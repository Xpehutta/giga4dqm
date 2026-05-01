#!/usr/bin/env python3
"""
Column / value investigation subagent:

1. Loads **DDL** (views, routines, base tables) for the schema — same context as
   ``db_lineage_subagent``.
2. Infers **lineage** for the user’s focus column/table (structured ``LineageAnswer``).
3. Emits a **bundle of read-only SELECT** statements grounded in upstream lineage, to investigate
   suspected bad data (user may embed SQL in the question).

Uses **GigaChat-Pro** for lineage by default (``LINEAGE_MODEL``); second call uses the same client
for SQL synthesis. Does **not** execute the generated SQL.

Optional Langfuse: ``LANGFUSE_PUBLIC_KEY`` / ``LANGFUSE_SECRET_KEY``
(see ``ai-agent-tools/README.md``).
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

from dotenv import load_dotenv
from gigachat import GigaChat
from gigachat.models import Chat, Messages, MessagesRole
from langchain_core.output_parsers import PydanticOutputParser
from langgraph.graph import END, START, StateGraph
from pydantic import BaseModel, Field
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

_AGENTS_DIR = Path(__file__).resolve().parent


def _load_sibling(name: str, filename: str) -> Any:
    path = _AGENTS_DIR / filename
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {name} from {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_lineage = _load_sibling("db_lineage_subagent", "db_lineage_subagent.py")

import agent_logging  # noqa: E402

_LOG = agent_logging.get_logger("agents.investigation")

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
SQL_CAP = min(500, int(os.getenv("SQL_SUBAGENT_MAX_LIMIT", "500")))
MAX_INV_QUERIES = int(os.getenv("INVESTIGATION_MAX_QUERIES", "12"))
_GIGACHAT_MAX_CONTEXT_CHARS = int(os.getenv("GIGACHAT_MAX_CONTEXT_CHARS", "130048"))
_GIGACHAT_CONTEXT_MARGIN = int(os.getenv("GIGACHAT_CONTEXT_MARGIN", "3000"))

giga_inv = GigaChat(
    model=MODEL_LINEAGE,
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


def _is_readonly_sql(sql: str) -> bool:
    t = (sql or "").strip()
    if not t.endswith(";"):
        t = t.rstrip() + ";"
    t = t.rstrip(";").strip()
    if _DANGER.search(t):
        return False
    return bool(re.search(r"^\s*(WITH\b[\s\S]*)?SELECT\b", t, re.IGNORECASE | re.DOTALL))


class InvestigativeSqlItem(BaseModel):
    purpose: str = Field(description="What this SELECT checks or validates.")
    sql: str = Field(
        description=(
            "Read-only SELECT ending with LIMIT (respect SQL_SUBAGENT_MAX_LIMIT). "
            "If FROM/JOIN involves more than one relation, qualify every column as "
            "alias.column or schema.table.column (use explicit AS aliases); bare names "
            "like credit_score cause PostgreSQL ERROR 42702 when ambiguous."
        ),
    )


class InvestigationSqlBundle(BaseModel):
    lineage_context_summary: str = Field(
        description=(
            "Brief recap: suspected column vs upstream objects. Quote **derivation rules** "
            "from DDL when relevant (e.g. full CASE/WHEN thresholds for computed columns like "
            "`risk_category`). If structured lineage included `defining_expressions`, lean on "
            "those verbatim snippets."
        ),
    )
    queries: list[InvestigativeSqlItem] = Field(
        default_factory=list,
        description=(
            f"Concrete investigative SELECTs ({MAX_INV_QUERIES} max); read-only. "
            "Qualify columns with aliases whenever joins or multiple CTEs appear."
        ),
    )


_plan_parser = PydanticOutputParser(pydantic_object=InvestigationSqlBundle)


# Verbatim thresholds: loans.customer_credit_risk (setup_loan_db.md, sql/setup_loans/05_views.sql).
_CUSTOMER_CREDIT_RISK_CASE = """\
CASE
        WHEN credit_score >= 700 AND avg_days_past_due < 5 THEN 'LOW'
        WHEN credit_score BETWEEN 600 AND 699 OR avg_days_past_due BETWEEN 5 AND 30 THEN 'MEDIUM'
        ELSE 'HIGH'
    END AS risk_category"""


def _canonical_risk_category_block(
    *,
    schema: str,
    focus_col: str | None,
    question: str,
    structured: dict[str, Any],
) -> str:
    """Inject risk_category derivation when the LLM may miss DDL (truncated context)."""
    if not focus_col or focus_col.lower() != "risk_category":
        return ""
    blob = f"{question}\n{json.dumps(structured, ensure_ascii=False)}".lower()
    if "customer_credit_risk" not in blob:
        return ""
    return (
        "\n--- Reference: canonical `loans.customer_credit_risk`.`risk_category` "
        f"(project `setup_loan_db.md` / `sql/setup_loans/05_views.sql`; "
        f"session schema `{schema}`) ---\n"
        "Use this definition **verbatim** in `lineage_context_summary` and when proposing checks "
        "(recompute inputs vs bands). Evaluation order: first matching WHEN wins "
        "(LOW, then MEDIUM, else HIGH). "
        "MEDIUM is triggered if **either** the credit-score band **or** the delinquency band "
        "matches.\n"
        "`avg_days_past_due` is `COALESCE(AVG(d.days_past_due), 0)` per customer in the view CTE "
        "(from `customers` → `loans` → `delinquencies`).\n\n"
        f"{_CUSTOMER_CREDIT_RISK_CASE}\n"
    )


def _validation_focus_column(question: str) -> str | None:
    """
    When the user asks to validate one named column (optionally with pasted SELECT … col …),
    return that column name so prompts scope checks to it only.
    """
    q = (question or "").strip()
    if not q:
        return None
    # "error in a value risk_category", "possible error in a value foo"
    m = re.search(r"\berror\s+in\s+a\s+value\s+([a-zA-Z_][a-zA-Z0-9_]*)\b", q, re.I)
    if m:
        return m.group(1)
    # Single-column SELECT: SELECT [DISTINCT] col FROM ...
    m = re.search(
        r"\bSELECT\s+(?:DISTINCT\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s+FROM\b",
        q,
        re.I | re.DOTALL,
    )
    if m:
        return m.group(1)
    return None


_STRUCTURE_INST = (
    "\n\nYou MUST reply with exactly one JSON object (no markdown fences) matching:\n"
    + _plan_parser.get_format_instructions()
)


def _max_user_chars(system: str) -> int:
    return max(4_000, _GIGACHAT_MAX_CONTEXT_CHARS - _GIGACHAT_CONTEXT_MARGIN - len(system))


def _truncate(text: str, system: str, cap_extra: int = 0) -> str:
    cap = _max_user_chars(system) - cap_extra
    if len(text) <= cap:
        return text
    note = "\n\n[... truncated ...]"
    return text[: max(0, cap - len(note))] + note


def _strip_fence(raw: str) -> str:
    s = raw.strip()
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


def _parse_bundle(raw: str) -> InvestigationSqlBundle:
    cleaned = _strip_fence(raw)
    try:
        return _plan_parser.parse(cleaned)
    except Exception:
        return InvestigationSqlBundle(
            lineage_context_summary=raw[:4_000] if raw else "",
            queries=[],
        )


class InvestigationState(TypedDict):
    schema: str
    question: str
    max_ddls_chars: int
    lineage_result: dict[str, Any]
    investigation: dict[str, Any]
    error: NotRequired[str]


InvestigationState.__annotations__["error"] = NotRequired[str]


def make_graph(db_uri: str, *, max_ddls_chars: int) -> Any:
    lineage_app = _lineage.make_graph(db_uri, max_ddls_chars=max_ddls_chars)

    def lineage_node(state: InvestigationState) -> InvestigationState:
        try:
            out = lineage_app.invoke(
                {
                    "schema": state["schema"],
                    "question": state["question"],
                    "context_blob": "",
                    "summary": {},
                    "answer": "",
                },
            )
            return {**state, "lineage_result": dict(out), "error": ""}
        except Exception as e:  # noqa: BLE001
            return {**state, "lineage_result": {}, "error": str(e)}

    def investigation_sql_node(state: InvestigationState) -> InvestigationState:
        if state.get("error"):
            return {
                **state,
                "investigation": {
                    "lineage_context_summary": "",
                    "queries": [],
                    "note": f"Lineage step failed: {state['error']}",
                },
            }
        lr = state["lineage_result"]
        structured = lr.get("structured") or {}
        if not isinstance(structured, dict):
            structured = {}
        blob = lr.get("context_blob") or ""
        summary = lr.get("summary") or {}
        ans = lr.get("answer") or ""

        focus_col = _validation_focus_column(state["question"])
        scope_note = ""
        if focus_col:
            scope_note = (
                f"\n**Scope:** The user asked to validate **only** the column `{focus_col}`. "
                "Every investigative SELECT must primarily inspect **that column** "
                "(distribution, allowed values, NULL rate, joins needed along lineage to interpret "
                f"`{focus_col}`). Filtering by keys (e.g. customer_id) is fine. "
                "Do **not** propose audits whose main purpose is unrelated columns.\n"
            )

        system = (
            "You design **investigative read-only SQL** for PostgreSQL. "
            f"The schema namespace for objects is `{state['schema']}` unless DDL shows otherwise.\n"
            "The user suspects a **data/value issue** (they may paste SQL). "
            "Use the lineage summary and DDL excerpts to list **upstream** tables/views that "
            "feed the focus column.\n"
            "**Column qualification (required):** Whenever a statement has more than one relation "
            "in FROM/JOIN (including CTEs joined to tables), PostgreSQL raises ERROR 42702 if a "
            "column name exists on multiple relations without a qualifier. Use **explicit table "
            "aliases** and write **every** referenced column as **alias.column** (or "
            "schema.table.column). Never use bare names like credit_score across joins.\n"
            "If lineage structured JSON contains **`defining_expressions`** or DDL shows CASE/WHEN "
            "for the suspect column, **anchor your reasoning** on those predicates (thresholds, "
            "bands). Proposed SELECTs should check observed values against that construction "
            "(e.g. recompute CASE inputs vs bands).\n"
            + scope_note
            + "Produce several DISTINCT SELECT queries that validate or disprove the suspicion "
            "(counts, DISTINCT, NULL rates, CASE boundaries, joins on lineage path).\n"
            f"Every statement must be SELECT-only and end with LIMIT <= {SQL_CAP}. "
            f"Provide at most {MAX_INV_QUERIES} queries."
            + _STRUCTURE_INST
        )
        user_head = ""
        if focus_col:
            user_head = f"Primary validation target (user): `{focus_col}` **only**.\n\n"

        ref_block = _canonical_risk_category_block(
            schema=state["schema"],
            focus_col=focus_col,
            question=state["question"],
            structured=structured,
        )
        user = (
            user_head
            + f"--- User question ---\n{state['question']}\n\n"
            f"--- Lineage counts ---\n{summary}\n\n"
            f"--- Lineage narrative ---\n{ans[:14_000]}\n\n"
            f"--- Structured lineage ---\n{json.dumps(structured, ensure_ascii=False)}\n\n"
            + ref_block
            + f"--- DDL excerpts ---\n{_truncate(blob, system)}\n"
        )
        user = _truncate(user, system, cap_extra=400)
        req = Chat(
            messages=[
                Messages(role=MessagesRole.SYSTEM, content=system),
                Messages(role=MessagesRole.USER, content=user),
            ]
        )
        resp = _trace.traced_giga_chat(
            _LF,
            giga_inv,
            req,
            observation_name="db_investigation.sql_bundle",
            model=MODEL_LINEAGE,
        )
        raw = (resp.choices[0].message.content or "").strip()
        bundle = _parse_bundle(raw)
        items_out: list[dict[str, Any]] = []
        for it in bundle.queries[:MAX_INV_QUERIES]:
            sql = (it.sql or "").strip()
            items_out.append(
                {
                    "purpose": it.purpose,
                    "sql": sql,
                    "readonly_ok": _is_readonly_sql(sql),
                },
            )
        _LOG.debug("node_investigation_sql_done proposal_count=%s", len(items_out))
        return {
            **state,
            "investigation": {
                "lineage_context_summary": bundle.lineage_context_summary,
                "queries": items_out,
                "model": MODEL_LINEAGE,
            },
        }

    graph = StateGraph(InvestigationState)
    graph.add_node("lineage", lineage_node)
    graph.add_node("investigation_sql", investigation_sql_node)
    graph.add_edge(START, "lineage")
    graph.add_edge("lineage", "investigation_sql")
    graph.add_edge("investigation_sql", END)
    return graph.compile()


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Lineage for a column/value suspicion, then investigative SELECT proposals.",
    )
    p.add_argument("--schema", required=True)
    p.add_argument("--question", required=True)
    p.add_argument("--pretty", action="store_true")
    p.add_argument("--max-ddls-chars", type=int, default=100_000)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    _LOG.info("run_start schema=%s question_chars=%s", args.schema, len(args.question or ""))
    try:
        with _trace.root_agent_span(
            _LF,
            name="db_investigation_subagent",
            input={
                "schema": args.schema,
                "question": (args.question or "")[:12_000],
            },
            metadata={"agent": "db_investigation_subagent"},
        ) as root:
            try:
                uri = _lineage.pgmeta.build_connection_string_from_environ()
                app = make_graph(uri, max_ddls_chars=args.max_ddls_chars)
                out = app.invoke(
                    {
                        "schema": args.schema,
                        "question": args.question,
                        "max_ddls_chars": args.max_ddls_chars,
                        "lineage_result": {},
                        "investigation": {},
                    },
                )
                lr = out.get("lineage_result") or {}
                lineage_payload = {
                    "answer": lr.get("answer", ""),
                    "structured": lr.get("structured") or {},
                    "summary": lr.get("summary") or {},
                    "model": getattr(_lineage, "MODEL_LINEAGE", MODEL_LINEAGE),
                }
                inv = out.get("investigation") or {}
                payload = {
                    "schema": args.schema,
                    "question": args.question,
                    "lineage": lineage_payload,
                    "investigation": inv,
                    "meta": {
                        "workflow": ["lineage_ddl", "investigation_sql_bundle"],
                        "sql_cap": SQL_CAP,
                    },
                }
                if out.get("error"):
                    payload["error"] = out["error"]
                print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
                nq = len((inv.get("queries") or [])) if isinstance(inv, dict) else 0
                if root is not None:
                    root.update(
                        output={
                            "investigation_query_count": nq,
                            "lineage_answer_preview": str(lr.get("answer", ""))[:8000],
                        }
                    )
                _LOG.info(
                    "run_done duration_ms=%.1f investigation_queries=%s",
                    (time.perf_counter() - t0) * 1000,
                    nq,
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
