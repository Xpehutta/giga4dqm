#!/usr/bin/env python3
"""
Data subagent: answer questions by running **read-only SELECT** queries using
LangChain's SQLDatabase (PostgreSQL via SQLAlchemy + psycopg).

This complements `db_catalog_agent.py`, which only reasons about **metadata** (DDL,
descriptions). Use this agent when the user needs **row-level** answers from tables.

Flow: load table context from SQLDatabase → GigaChat emits JSON (`GeneratedSql` via
`PydanticOutputParser`) → validate → SQLDatabase.run → GigaChat JSON summary (`DataSummaryAnswer`).

Optional: set ``LANGFUSE_PUBLIC_KEY`` / ``LANGFUSE_SECRET_KEY`` to trace GigaChat calls (see
``ai-agent-tools/README.md``).
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import time
from pathlib import Path
from typing import Any
from urllib.parse import quote_plus

from dotenv import load_dotenv
from langchain_community.utilities import SQLDatabase
from langchain_core.output_parsers import PydanticOutputParser
from langgraph.graph import END, START, StateGraph
from pydantic import BaseModel, Field
from sqlalchemy import create_engine
from typing_extensions import NotRequired, TypedDict

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = PROJECT_ROOT / ".env"
load_dotenv(dotenv_path=ENV_FILE)

_APPLY_PATH = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "apply_gigachat_http_timeouts.py"
_spec_apply = importlib.util.spec_from_file_location("apply_gigachat_http_timeouts", _APPLY_PATH)
if _spec_apply is None or _spec_apply.loader is None:
    raise ImportError(f"Cannot load apply_gigachat_http_timeouts from {_APPLY_PATH}")
_gch_apply = importlib.util.module_from_spec(_spec_apply)
_spec_apply.loader.exec_module(_gch_apply)
_gch_apply.apply()

import agent_logging  # noqa: E402

_LOG = agent_logging.get_logger("agents.data")

from gigachat import GigaChat  # noqa: E402
from gigachat.models import Chat, Messages, MessagesRole  # noqa: E402

GIGACHAT_CREDENTIALS = os.getenv("GIGACHAT_API_KEY") or os.getenv("GIGACHAT_EMBEDDINGS_CREDENTIALS")
if not GIGACHAT_CREDENTIALS:
    raise ValueError(
        "Missing GigaChat credentials. Set GIGACHAT_API_KEY or "
        f"GIGACHAT_EMBEDDINGS_CREDENTIALS in {ENV_FILE}."
    )

GIGACHAT_BASE_URL = os.getenv("GIGACHAT_API_URL", "https://gigachat.devices.sberbank.ru/api/v1")
VERIFY_SSL = os.getenv("GIGACHAT_VERIFY_SSL", "false").lower() == "true"
SCOPE = os.getenv("GIGACHAT_SCOPE", "GIGACHAT_API_PERS")
MODEL = os.getenv("MODEL", "GigaChat-Pro")
TIMEOUT = int(os.getenv("GIGACHAT_TIMEOUT", "120"))
SQL_MAX_LIMIT = int(os.getenv("SQL_SUBAGENT_MAX_LIMIT", "500"))
# GigaChat rejects when total "context" exceeds this (error message, chars).
_GIGACHAT_MAX_CONTEXT_CHARS = int(os.getenv("GIGACHAT_MAX_CONTEXT_CHARS", "130048"))
_GIGACHAT_CONTEXT_MARGIN = int(os.getenv("GIGACHAT_CONTEXT_MARGIN", "3000"))


giga = GigaChat(
    model=MODEL,
    credentials=GIGACHAT_CREDENTIALS,
    base_url=GIGACHAT_BASE_URL,
    verify_ssl_certs=VERIFY_SSL,
    scope=SCOPE,
    timeout=TIMEOUT,
)

import agent_langfuse as _trace  # noqa: E402

_LF = _trace.get_langfuse_client()

_DANGER = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE|GRANT|REVOKE|CREATE|"
    r"CALL|EXECUTE|DO\s*)\b",
    re.IGNORECASE,
)


class GeneratedSql(BaseModel):
    """SQL generation step JSON."""

    sql: str = Field(
        description=(
            "A single PostgreSQL SELECT or WITH ... SELECT statement. "
            "Read-only; end with LIMIT. "
            "If FROM/JOIN uses more than one table/view/CTE, qualify every column as "
            "alias.column or schema.table.column (use AS aliases); avoid bare names that "
            "could be ambiguous (PostgreSQL ERROR 42702)."
        ),
    )


class DataSummaryAnswer(BaseModel):
    """Final natural-language explanation for the user."""

    answer: str = Field(description="Answer in clear prose; cite numbers from the query result.")


_sql_parser = PydanticOutputParser(pydantic_object=GeneratedSql)
_summary_parser = PydanticOutputParser(pydantic_object=DataSummaryAnswer)

STRUCTURED_JSON = (
    "\n\nYou MUST respond with a single JSON object only (no markdown code fences) that "
    "matches the schema below. The JSON must be valid UTF-8 and parseable.\n"
)


def _strip_code_fence(text: str) -> str:
    s = text.strip()
    m = re.match(r"^```(?:json)?\s*([\s\S]*?)```\s*$", s)
    if m:
        return m.group(1).strip()
    if s.startswith("```"):
        lines = s.split("\n")
        lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        s = "\n".join(lines).strip()
    return s


def _parse_generated_sql(raw: str) -> str:
    cleaned = _strip_code_fence(raw)
    try:
        return _sql_parser.parse(cleaned).sql.strip()
    except Exception:
        return _strip_sql_fence(raw)


def _parse_summary_answer(raw: str) -> str:
    cleaned = _strip_code_fence(raw)
    try:
        return _summary_parser.parse(cleaned).answer.strip()
    except Exception:
        return (raw or "").strip()


def _sqlalchemy_uri_from_env() -> str:
    raw = os.getenv("PG_DSN", "").strip()
    if raw:
        if "postgresql+psycopg" in raw:
            return raw
        if raw.startswith("postgresql://"):
            return "postgresql+psycopg://" + raw.removeprefix("postgresql://")
        return raw
    user = os.getenv("PGUSER")
    database = os.getenv("PGDATABASE")
    if not user or not database:
        raise ValueError("Set PG_DSN or PGUSER + PGDATABASE (and PG*, or PGPASSWORD).")
    password = os.getenv("PGPASSWORD") or ""
    host = os.getenv("PGHOST", "localhost")
    port = os.getenv("PGPORT", "5432")
    u = quote_plus(user)
    p = quote_plus(password) if password else ""
    auth = f"{u}:{p}" if p else u
    return f"postgresql+psycopg://{auth}@{host}:{port}/{database}"


def _pg_schema_for_search_path(schema: str) -> str:
    """Only allow unquoted PostgreSQL identifier characters (safe for -csearch_path=)."""
    s = (schema or "").strip()
    if not re.match(r"^[a-zA-Z0-9_]+$", s):
        raise ValueError(
            f"Schema {schema!r} must be alphanumeric/underscore for SQLDatabase search_path.",
        )
    return s


def _is_readonly_sql(sql: str) -> bool:
    t = (sql or "").strip()
    if not t.endswith(";"):
        t = t.rstrip() + ";"  # normalize for check
    t = t.rstrip(";").strip()
    if _DANGER.search(t):
        return False
    return bool(re.search(r"^\s*(WITH\b[\s\S]*)?SELECT\b", t, re.IGNORECASE | re.DOTALL))


def _strip_sql_fence(s: str) -> str:
    t = s.strip()
    m = re.match(r"^```(?:sql)?\s*([\s\S]*?)```\s*$", t)
    if m:
        return m.group(1).strip()
    t = t.removeprefix("```sql").removesuffix("```").strip()
    return t


def _ensure_limit(sql: str, cap: int) -> str:
    t = sql.strip().rstrip(";")
    if re.search(r"\bLIMIT\s+\d+\s*$", t, re.IGNORECASE):
        return t + ";"
    return f"{t} LIMIT {cap};"


def _max_user_message_chars(system: str) -> int:
    return max(4_000, _GIGACHAT_MAX_CONTEXT_CHARS - _GIGACHAT_CONTEXT_MARGIN - len(system))


def _data_agent_question_effective(q: str, max_chars: int) -> str:
    """
    Prefer the 'Current:' tail from Streamlit multi-turn payload; else cap by length.
    """
    t = (q or "").strip()
    if not t:
        return t
    if "\n\nCurrent:\n" in t:
        body = t.rsplit("\n\nCurrent:\n", 1)[-1].strip()
    else:
        body = t
    if len(body) <= max_chars:
        return body
    return body[: max_chars - 24] + "\n[… truncated …]"


def _chat(system: str, user: str, *, step: str = "chat") -> str:
    cap = _max_user_message_chars(system)
    if len(user) <= cap:
        u = user
    else:
        note = "\n\n[... truncated to fit GigaChat context limit ...]"
        keep = max(0, cap - len(note))
        u = user[:keep] + note
    req = Chat(
        messages=[
            Messages(role=MessagesRole.SYSTEM, content=system),
            Messages(role=MessagesRole.USER, content=u),
        ]
    )
    resp = _trace.traced_giga_chat(
        _LF,
        giga,
        req,
        observation_name=f"db_data_subagent.{step}",
        model=MODEL,
    )
    return (resp.choices[0].message.content or "").strip()


def build_sql_database(
    schema: str,
    *,
    sample_rows: int = 1,
    view_support: bool = True,
) -> SQLDatabase:
    """
    Build LangChain SQLDatabase for PostgreSQL + psycopg3.

    LangChain runs ``SET search_path TO %s`` on each query; the psycopg3 driver
    rewrites that to use ``$1``, which PostgreSQL rejects for ``SET``. We set
    ``search_path`` via the engine ``connect_args`` and pass ``schema=None`` so
    the buggy branch is skipped. ``pg_table_is_visible`` then lists tables in
    the configured path.
    """
    uri = _sqlalchemy_uri_from_env()
    safe = _pg_schema_for_search_path(schema)
    engine = create_engine(
        uri,
        connect_args={"options": f"-csearch_path={safe},public"},
    )
    return SQLDatabase(
        engine,
        schema=None,
        sample_rows_in_table_info=sample_rows,
        view_support=view_support,
    )


class DataSubagentState(TypedDict):
    schema: str
    question: str
    table_context: str
    sql: str
    sql_result: str
    answer: str
    error: NotRequired[str]


DataSubagentState.__annotations__["error"] = NotRequired[str]


def make_graph(db: SQLDatabase, *, max_table_info_chars: int) -> Any:
    def context_node(state: DataSubagentState) -> DataSubagentState:
        _LOG.debug("node_context schema=%s", state["schema"])
        ctx = db.get_context()
        info = ctx["table_info"]
        if len(info) > max_table_info_chars:
            info = info[:max_table_info_chars] + "\n\n[... table info truncated ...]"
        _LOG.debug("node_context_done table_info_chars=%s", len(info))
        return {**state, "table_context": info, "sql": "", "sql_result": "", "answer": ""}

    def gen_sql_node(state: DataSubagentState) -> DataSubagentState:
        sys = (
            "You write a single PostgreSQL SELECT query (optionally WITH ... SELECT). "
            "Read-only: no INSERT/UPDATE/DELETE/DDL. Prefer explicit column lists. "
            "If the query joins two or more relations (tables, views, or CTEs), you MUST qualify "
            "every column reference as alias.column or schema.table.column—use short explicit AS "
            "aliases in FROM/JOIN. Bare identifiers (e.g. credit_score) when multiple relations "
            "expose the same name cause ERROR 42702; never do that. "
            f"End with LIMIT <= {SQL_MAX_LIMIT}. "
            "Put the full statement in the JSON field `sql` only."
            + STRUCTURED_JSON
            + _sql_parser.get_format_instructions()
        )
        room = _max_user_message_chars(sys)
        q_eff = _data_agent_question_effective(
            state["question"],
            max_chars=min(40_000, max(8_000, room // 4)),
        )
        prefix = f"Schema: {state['schema']}\n\n"
        suffix = f"\n\nQuestion:\n{q_eff}"
        body_room = max(1, room - len(prefix) - len(suffix))
        tc = state["table_context"]
        if len(tc) > body_room:
            tc = tc[: body_room - 60] + "\n\n[... table info truncated for model context limit ...]"
        user = prefix + tc + suffix
        raw = _chat(sys, user, step="gen_sql")
        sql = _parse_generated_sql(raw)
        if not _is_readonly_sql(sql):
            return {
                **state,
                "sql": sql,
                "error": (
                    "Generated SQL failed read-only check (use SELECT or WITH...SELECT only)."
                ),
            }
        sql = _ensure_limit(sql, SQL_MAX_LIMIT)
        _LOG.debug("node_gen_sql_done sql_chars=%s", len(sql))
        return {**state, "sql": sql, "error": ""}

    def run_sql_node(state: DataSubagentState) -> DataSubagentState:
        if state.get("error"):
            return {**state, "sql_result": ""}
        sql = state["sql"]
        out = db.run_no_throw(sql)
        if isinstance(out, str) and out.startswith("Error:"):
            _LOG.info(
                "node_run_sql_failed preview=%s",
                (out[:120] or "").replace("\n", " "),
            )
            return {**state, "sql_result": out, "error": out}
        _LOG.debug("node_run_sql_done result_chars=%s", len(str(out)))
        return {**state, "sql_result": str(out), "error": ""}

    def summarize_node(state: DataSubagentState) -> DataSubagentState:
        if state.get("error") and not state.get("sql_result"):
            return {**state, "answer": state.get("error", "Unknown error.")}
        q_sum = _data_agent_question_effective(state["question"], max_chars=16_000)
        if state.get("error") and state.get("sql_result", "").startswith("Error:"):
            sys = (
                "You explain a failed SQL run briefly; suggest a fix if obvious. "
                "Respond with ONE JSON object with key `answer`."
                + STRUCTURED_JSON
                + _summary_parser.get_format_instructions()
            )
            res = (state.get("sql_result") or "")
            user = f"Question: {q_sum}\nSQL: {state['sql']}\nDB message:\n{res}"
            room = _max_user_message_chars(sys)
            if len(user) > room:
                head = f"Question: {q_sum}\nSQL: {state['sql']}\nDB message:\n"
                rroom = max(2_000, room - len(head) - 50)
                if len(res) > rroom:
                    mtail = "\n[... message truncated for model context ...]"
                    res = res[: rroom - len(mtail)] + mtail
                user = head + res
            raw = _chat(sys, user, step="summarize_sql_error")
            return {**state, "answer": _parse_summary_answer(raw)}
        sys = (
            "Answer the user in clear prose using the query result. Cite numbers from the result. "
            "Respond with ONE JSON object with key `answer`."
            + STRUCTURED_JSON
            + _summary_parser.get_format_instructions()
        )
        res = (state.get("sql_result") or "")
        head = f"Question: {q_sum}\n\nQuery result (text):\n"
        room = _max_user_message_chars(sys)
        rroom = max(2_000, room - len(head) - 50)
        if len(res) > rroom:
            res = res[:rroom] + "\n[... result truncated for model context limit ...]"
        user = head + res
        raw = _chat(sys, user, step="summarize")

    graph = StateGraph(DataSubagentState)
    graph.add_node("context", context_node)
    graph.add_node("gen_sql", gen_sql_node)
    graph.add_node("run_sql", run_sql_node)
    graph.add_node("summarize", summarize_node)
    graph.add_edge(START, "context")
    graph.add_edge("context", "gen_sql")
    graph.add_edge("gen_sql", "run_sql")
    graph.add_edge("run_sql", "summarize")
    graph.add_edge("summarize", END)
    return graph.compile()


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Query PostgreSQL data via SQLDatabase + GigaChat (read-only SELECT).",
    )
    p.add_argument("--schema", default="public", help="Postgres schema to scope tables to.")
    p.add_argument("--question", required=True, help="Question about data (not only metadata).")
    p.add_argument("--pretty", action="store_true", help="Pretty-print JSON result.")
    p.add_argument(
        "--max-table-info-chars",
        type=int,
        default=100_000,
        help="Truncate LangChain table info string for the SQL prompt (default 100000).",
    )
    p.add_argument("--no-views", action="store_true", help="Do not include views in SQLDatabase.")
    p.add_argument(
        "--sample-rows",
        type=int,
        default=1,
        help="Sample rows in table info (SQLDatabase sample_rows_in_table_info).",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    _LOG.info("run_start schema=%s question_chars=%s", args.schema, len(args.question or ""))
    try:
        with _trace.root_agent_span(
            _LF,
            name="db_data_subagent",
            input={
                "schema": args.schema,
                "question": (args.question or "")[:12_000],
            },
            metadata={"agent": "db_data_subagent"},
        ) as root:
            try:
                db = build_sql_database(
                    args.schema,
                    sample_rows=args.sample_rows,
                    view_support=not args.no_views,
                )
                app = make_graph(db, max_table_info_chars=args.max_table_info_chars)
                out = app.invoke(
                    {
                        "schema": args.schema,
                        "question": args.question,
                        "table_context": "",
                        "sql": "",
                        "sql_result": "",
                        "answer": "",
                    }
                )
                payload = {
                    "schema": out["schema"],
                    "question": out["question"],
                    "sql": out.get("sql", ""),
                    "result_preview": (out.get("sql_result", "") or "")[:8000],
                    "answer": out.get("answer", ""),
                }
                if out.get("error"):
                    payload["error"] = out["error"]
                print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
                if root is not None:
                    root.update(
                        output={
                            "answer": (out.get("answer") or "")[:12_000],
                            "sql": (out.get("sql") or "")[:8000],
                            "error": out.get("error"),
                        }
                    )
                _LOG.info(
                    "run_done duration_ms=%.1f has_error=%s",
                    (time.perf_counter() - t0) * 1000,
                    bool(out.get("error")),
                )
            except Exception:
                if root is not None:
                    root.update(level="ERROR", status_message="run_failed")
                raise
    except Exception:
        _LOG.exception("run_failed duration_ms=%.1f", (time.perf_counter() - t0) * 1000)
        raise
    finally:
        _trace.flush_langfuse(_LF)


if __name__ == "__main__":
    main()
