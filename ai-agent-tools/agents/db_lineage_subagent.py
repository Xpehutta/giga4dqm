#!/usr/bin/env python3
"""
Data lineage subagent: analyzes view and routine **DDL** from pg_catalog to infer
upstream/downstream relationships for a table or column in one schema.

Uses **GigaChat-Pro** by default (see LINEAGE_MODEL). Read-only: no data SELECT.
Structured output is parsed with ``PydanticOutputParser`` into ``LineageAnswer``.

Optional Langfuse tracing: ``LANGFUSE_PUBLIC_KEY`` / ``LANGFUSE_SECRET_KEY`` (see README).
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

import psycopg
from dotenv import load_dotenv
from langchain_core.output_parsers import PydanticOutputParser
from langgraph.graph import END, START, StateGraph
from pydantic import BaseModel, Field
from typing_extensions import NotRequired, TypedDict

PROJECT_ROOT = Path(__file__).resolve().parents[2]
_SCRIPTS_METADATA = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "postgres_metadata.py"
_spec = importlib.util.spec_from_file_location("postgres_metadata", _SCRIPTS_METADATA)
if _spec is None or _spec.loader is None:
    raise ImportError(f"Cannot load postgres_metadata from {_SCRIPTS_METADATA}")
pgmeta = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pgmeta)

ENV_FILE = PROJECT_ROOT / ".env"
load_dotenv(dotenv_path=ENV_FILE)
pgmeta.load_env_file(str(ENV_FILE))

_APPLY_PATH = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "apply_gigachat_http_timeouts.py"
_spec_apply = importlib.util.spec_from_file_location("apply_gigachat_http_timeouts", _APPLY_PATH)
if _spec_apply is None or _spec_apply.loader is None:
    raise ImportError(f"Cannot load apply_gigachat_http_timeouts from {_APPLY_PATH}")
_gch_apply = importlib.util.module_from_spec(_spec_apply)
_spec_apply.loader.exec_module(_gch_apply)
_gch_apply.apply()

import agent_logging  # noqa: E402

_LOG = agent_logging.get_logger("agents.lineage")

from gigachat import GigaChat  # noqa: E402
from gigachat.models import Chat, Messages, MessagesRole  # noqa: E402

GIGACHAT_CREDENTIALS = os.getenv("GIGACHAT_API_KEY") or os.getenv("GIGACHAT_EMBEDDINGS_CREDENTIALS")
if not GIGACHAT_CREDENTIALS:
    raise ValueError(
        "Missing GigaChat credentials. Set GIGACHAT_API_KEY or "
        f"GIGACHAT_EMBEDDINGS_CREDENTIALS in {ENV_FILE}.",
    )

GIGACHAT_BASE_URL = os.getenv("GIGACHAT_API_URL", "https://gigachat.devices.sberbank.ru/api/v1")
VERIFY_SSL = os.getenv("GIGACHAT_VERIFY_SSL", "false").lower() == "true"
SCOPE = os.getenv("GIGACHAT_SCOPE", "GIGACHAT_API_PERS")
MODEL_LINEAGE = os.getenv("LINEAGE_MODEL", "GigaChat-Pro")
TIMEOUT = int(os.getenv("GIGACHAT_TIMEOUT", "120"))
_GIGACHAT_MAX_CONTEXT_CHARS = int(os.getenv("GIGACHAT_MAX_CONTEXT_CHARS", "130048"))
_GIGACHAT_CONTEXT_MARGIN = int(os.getenv("GIGACHAT_CONTEXT_MARGIN", "3000"))

giga_lineage = GigaChat(
    model=MODEL_LINEAGE,
    credentials=GIGACHAT_CREDENTIALS,
    base_url=GIGACHAT_BASE_URL,
    verify_ssl_certs=VERIFY_SSL,
    scope=SCOPE,
    timeout=TIMEOUT,
)

import agent_langfuse as _trace  # noqa: E402

_LF = _trace.get_langfuse_client()

_STRUCTURE_INST = (
    "\n\nYou MUST reply with exactly one JSON object (no markdown fences) matching the schema:\n"
)

_STOPWORDS = frozenset(
    {
        "the",
        "a",
        "an",
        "and",
        "or",
        "for",
        "what",
        "where",
        "how",
        "which",
        "who",
        "when",
        "does",
        "do",
        "is",
        "are",
        "was",
        "were",
        "be",
        "to",
        "of",
        "in",
        "on",
        "about",
        "from",
        "with",
        "this",
        "that",
        "these",
        "those",
        "postgresql",
        "schema",
        "table",
        "column",
        "view",
        "function",
        "lineage",
        "data",
    },
)


class LineageAnswer(BaseModel):
    answer: str = Field(
        description=(
            "Clear explanation of upstream/downstream for the user's focus object. Markdown ok."
        ),
    )
    upstream_objects: list[str] = Field(
        default_factory=list,
        description="Objects named in DDL that sources flow from (bases, refs ‘feeding’ focus).",
    )
    downstream_objects: list[str] = Field(
        default_factory=list,
        description="Objects that depend on / read the focus (views, routines using focus).",
    )
    cited_object_names: list[str] = Field(
        default_factory=list,
        description="View/routine/table names from the context you relied on.",
    )
    missing_in_context: list[str] = Field(
        default_factory=list,
        description="Identifiers the user asked about that did not appear in the DDL excerpt.",
    )
    defining_expressions: list[str] = Field(
        default_factory=list,
        description=(
            "Verbatim SQL snippets **copied from the DDL context** that define how computed "
            "columns "
            "are produced. When the focus column is derived with CASE/WHEN (or expr AS name), "
            "paste "
            "the **full** CASE … END AS column_name (or equivalent) block here — do not paraphrase "
            "thresholds or predicates. Leave empty only if the column is a plain base-table column "
            "or its definition is absent from excerpts."
        ),
    )


_output_parser = PydanticOutputParser(pydantic_object=LineageAnswer)


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


def _parse_lineage_structured(raw: str) -> LineageAnswer:
    cleaned = _strip_code_fence(raw)
    try:
        return _output_parser.parse(cleaned)
    except Exception:
        try:
            return LineageAnswer.model_validate_json(cleaned)
        except Exception:
            return LineageAnswer(answer=raw or "(empty model response)", missing_in_context=[])


def _max_user_chars(system: str) -> int:
    return max(4_000, _GIGACHAT_MAX_CONTEXT_CHARS - _GIGACHAT_CONTEXT_MARGIN - len(system))


def _truncate_user(system: str, user: str) -> str:
    cap = _max_user_chars(system)
    if len(user) <= cap:
        return user
    note = "\n\n[... truncated to fit GigaChat context limit ...]"
    keep = max(0, cap - len(note))
    return user[:keep] + note


def _data_agent_question_tail(q: str) -> str:
    t = (q or "").strip()
    if "\n\nCurrent:\n" in t:
        return t.rsplit("\n\nCurrent:\n", 1)[-1].strip()
    return t


def _keywords_for_filter(question: str) -> list[str]:
    tail = _data_agent_question_tail(question)
    words = set(re.findall(r"[a-zA-Z_][a-zA-Z0-9_]{1,}", tail))
    words.update(re.findall(r"\bFROM\s+(?:[\w.]+\.)?([\w]+)\b", tail, re.I))
    return sorted(w for w in words if w.lower() not in _STOPWORDS and len(w) >= 2)[:48]


def _score_ddl(ddl: str, keywords: list[str]) -> int:
    d = ddl.lower()
    return sum(d.count(k.lower()) for k in keywords)


def _build_ddls_blob(
    schema: str,
    base_tables: list[str],
    views: list[dict[str, Any]],
    routines: list[dict[str, Any]],
    question: str,
    max_chars: int,
) -> str:
    header = (
        f"# Schema `{schema}`\n"
        f"## Base tables ({len(base_tables)}): "
        + (", ".join(base_tables) if base_tables else "(none)")
        + "\n"
    )
    kw = _keywords_for_filter(question)
    scored: list[tuple[int, str, str]] = []
    for v in views:
        ddl = v.get("ddl") or ""
        label = f"VIEW {schema}.{v.get('name', '?')}"
        scored.append((_score_ddl(ddl, kw), label, ddl))
    for r in routines:
        ddl = r.get("ddl") or ""
        label = f"{r.get('kind', 'function').upper()} {schema}.{r.get('name', '?')}"
        scored.append((_score_ddl(ddl, kw), label, ddl))
    scored.sort(key=lambda x: -x[0])
    parts: list[str] = [header]
    total = len(header)
    for _sc, lab, ddl in scored:
        block = f"### {lab}\n```sql\n{ddl}\n```\n"
        if total + len(block) <= max_chars:
            parts.append(block)
            total += len(block)
        elif not parts[-1].endswith("(objects omitted due to size)\n"):
            parts.append("(objects omitted due to size)\n")
            total += len(parts[-1])
    text = "".join(parts)
    if len(text) > max_chars:
        note = "\n[... DDL blob truncated ...]"
        text = text[: max_chars - len(note)] + note
    return text


class LineageState(TypedDict):
    schema: str
    question: str
    context_blob: str
    summary: dict[str, int]
    answer: str
    structured: NotRequired[dict[str, Any]]
    error: NotRequired[str]


LineageState.__annotations__["structured"] = NotRequired[dict[str, Any]]
LineageState.__annotations__["error"] = NotRequired[str]


def make_graph(db_uri: str, *, max_ddls_chars: int) -> Any:
    def load_node(state: LineageState) -> LineageState:
        schema = state["schema"]
        try:
            with psycopg.connect(db_uri) as conn:
                base = pgmeta.list_base_table_names(conn, schema)
                views = pgmeta.fetch_views(conn, schema)
                routines = pgmeta.fetch_procedures(conn, schema)
            blob = _build_ddls_blob(
                schema, base, views, routines, state["question"], max_ddls_chars,
            )
            _LOG.debug(
                "node_load_ddl_done blob_chars=%s base=%s views=%s routines=%s",
                len(blob),
                len(base),
                len(views),
                len(routines),
            )
            return {
                **state,
                "context_blob": blob,
                "summary": {
                    "base_tables": len(base),
                    "views": len(views),
                    "routines": len(routines),
                },
                "error": "",
            }
        except Exception as e:  # noqa: BLE001
            _LOG.warning("node_load_ddl_failed err=%s", e)
            return {
                **state,
                "context_blob": "",
                "summary": {"base_tables": 0, "views": 0, "routines": 0},
                "error": str(e),
            }

    def answer_node(state: LineageState) -> LineageState:
        if state.get("error"):
            ans = (
                "Could not load DDL from PostgreSQL:\n```\n"
                + (state.get("error") or "?")
                + "\n```"
            )
            return {
                **state,
                "answer": ans,
                "structured": LineageAnswer(answer=ans, missing_in_context=[]).model_dump(),
            }
        system = (
            "You are a PostgreSQL data-lineage analyst. You only see **DDL excerpts** below "
            "(views + functions/procedures + list of base tables). "
            "Infer **upstream** objects (sources the focus reads from) and **downstream** objects "
            "(objects whose definitions reference the focus), for the user’s table or column. "
            "If the user names **one suspect column** (or pastes SQL that selects **one** column "
            "as the concern), treat **that column as the sole lineage focus** — trace DDL paths "
            "for that identifier first; avoid drifting into unrelated columns unless they "
            "directly define or derive that column. "
            "**Computed columns:** When that column is defined in DDL with CASE/WHEN, filters, "
            "expressions, or `expr AS column_name`, you MUST locate it in the excerpts and fill "
            "`defining_expressions` with **verbatim** defining SQL (prefer the entire "
            "`CASE … END AS column_name` block). Explain thresholds/rules in `answer` using those "
            "exact predicates — never invent cutoff values missing from DDL. "
            "If the excerpt is incomplete, say so. Do not invent object names not present in the "
            "DDL or base-table list. Use short schema-qualified names when clear."
            + _STRUCTURE_INST
            + _output_parser.get_format_instructions()
        )
        user = (
            f"Counts: {state['summary']}\n\n--- DDL context ---\n{state['context_blob']}\n\n"
            f"--- Question ---\n{state['question']}"
        )
        user = _truncate_user(system, user)
        req = Chat(
            messages=[
                Messages(role=MessagesRole.SYSTEM, content=system),
                Messages(role=MessagesRole.USER, content=user),
            ]
        )
        resp = _trace.traced_giga_chat(
            _LF,
            giga_lineage,
            req,
            observation_name="db_lineage.answer",
            model=MODEL_LINEAGE,
        )
        raw = (resp.choices[0].message.content or "").strip()
        parsed = _parse_lineage_structured(raw)
        _LOG.debug("node_lineage_answer_done response_chars=%s", len(raw))
        return {
            **state,
            "answer": parsed.answer,
            "structured": parsed.model_dump(),
        }

    graph = StateGraph(LineageState)
    graph.add_node("load", load_node)
    graph.add_node("answer", answer_node)
    graph.add_edge(START, "load")
    graph.add_edge("load", "answer")
    graph.add_edge("answer", END)
    return graph.compile()


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Data lineage from view/routine DDL (GigaChat-Pro by default).",
    )
    p.add_argument("--schema", required=True, help="PostgreSQL schema.")
    p.add_argument("--question", required=True, help="Lineage question (table/column focus).")
    p.add_argument("--pretty", action="store_true")
    p.add_argument(
        "--max-ddls-chars",
        type=int,
        default=100_000,
        help="Max characters of DDL blob sent to the model (default 100000).",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    _LOG.info("run_start schema=%s question_chars=%s", args.schema, len(args.question or ""))
    try:
        with _trace.root_agent_span(
            _LF,
            name="db_lineage_subagent",
            input={
                "schema": args.schema,
                "question": (args.question or "")[:12_000],
            },
            metadata={"agent": "db_lineage_subagent"},
        ) as root:
            try:
                uri = pgmeta.build_connection_string_from_environ()
                app = make_graph(uri, max_ddls_chars=args.max_ddls_chars)
                out = app.invoke(
                    {
                        "schema": args.schema,
                        "question": args.question,
                        "context_blob": "",
                        "summary": {},
                        "answer": "",
                    },
                )
                structured = out.get("structured") or {}
                payload = {
                    "schema": args.schema,
                    "question": args.question,
                    "answer": out.get("answer", ""),
                    "summary": out.get("summary", {}),
                    "structured": structured,
                    "model": MODEL_LINEAGE,
                }
                if out.get("error") and out.get("answer", "").startswith("Could not load DDL"):
                    payload["error"] = out["error"]
                print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
                if root is not None:
                    root.update(
                        output={
                            "answer": (out.get("answer") or "")[:16_000],
                            "summary": out.get("summary", {}),
                        }
                    )
                _LOG.info(
                    "run_done duration_ms=%.1f model=%s",
                    (time.perf_counter() - t0) * 1000,
                    MODEL_LINEAGE,
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
