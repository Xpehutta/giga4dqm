#!/usr/bin/env python3
"""
Lineage + data audit subagent: infers upstream/downstream from view/routine DDL, then runs
read-only SELECT checks on source objects to surface data issues relevant to marts/pipelines.

Combines `db_lineage_subagent` (DDL, GigaChat-Pro) and `db_data_subagent` (SQLDatabase + SELECT).
Structured LLM replies in those subgraphs use `langchain_core.output_parsers.PydanticOutputParser`.

Optional Langfuse keys trace nested lineage + data LLM calls; see README.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import time
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from langgraph.graph import END, START, StateGraph
from typing_extensions import NotRequired, TypedDict

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = PROJECT_ROOT / ".env"
load_dotenv(dotenv_path=ENV_FILE)

_SCRIPTS_METADATA = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "postgres_metadata.py"
_spec_meta = importlib.util.spec_from_file_location("postgres_metadata", _SCRIPTS_METADATA)
if _spec_meta is None or _spec_meta.loader is None:
    raise ImportError(f"Cannot load postgres_metadata from {_SCRIPTS_METADATA}")
pgmeta = importlib.util.module_from_spec(_spec_meta)
_spec_meta.loader.exec_module(pgmeta)
pgmeta.load_env_file(str(ENV_FILE))

_APPLY_PATH = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "apply_gigachat_http_timeouts.py"
_spec_apply = importlib.util.spec_from_file_location("apply_gigachat_http_timeouts", _APPLY_PATH)
if _spec_apply is None or _spec_apply.loader is None:
    raise ImportError(f"Cannot load apply_gigachat_http_timeouts from {_APPLY_PATH}")
_gch_apply = importlib.util.module_from_spec(_spec_apply)
_spec_apply.loader.exec_module(_gch_apply)
_gch_apply.apply()

import agent_langfuse as _trace  # noqa: E402
import agent_logging  # noqa: E402

_LOG = agent_logging.get_logger("agents.audit")
_LF = _trace.get_langfuse_client()

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
_data = _load_sibling("db_data_subagent", "db_data_subagent.py")


class AuditState(TypedDict):
    schema: str
    question: str
    max_ddls_chars: int
    max_table_info_chars: int
    lineage_out: dict[str, Any]
    data_question: str
    data_out: dict[str, Any]
    error: NotRequired[str]


AuditState.__annotations__["error"] = NotRequired[str]


def _data_tail(q: str) -> str:
    t = (q or "").strip()
    if "\n\nCurrent:\n" in t:
        return t.rsplit("\n\nCurrent:\n", 1)[-1].strip()
    return t


def _build_data_question(user_question: str, lineage_payload: dict[str, Any]) -> str:
    """Turn lineage JSON into instructions for the data subagent."""
    ans = str(lineage_payload.get("answer", "")).strip()
    structured = lineage_payload.get("structured") or {}
    if not isinstance(structured, dict):
        structured = {}
    up = structured.get("upstream_objects") or []
    down = structured.get("downstream_objects") or []
    cited = structured.get("cited_object_names") or []
    tail = _data_tail(user_question)
    parts = [
        "You are validating a data mart / view pipeline. Use read-only SELECT queries.",
        "",
        f"User focus:\n{tail}",
        "",
        "--- Lineage (from DDL; use as guidance only) ---",
        ans[:12_000] if len(ans) > 12_000 else ans,
        "",
        f"Upstream objects (sources): {up if up else '(none named)'}",
        f"Downstream objects: {down if down else '(none named)'}",
        f"Objects cited in DDL: {cited if cited else '(none)'}",
        "",
        "Tasks:",
        (
            "1. Prioritize checking **base tables and views listed as upstream** "
            "(or named in the lineage text)."
        ),
        "2. Look for data issues that could break or skew the mart: unexpected NULLs, "
        "duplicates on "
        "supposed keys, empty segments, count mismatches, obvious referential gaps.",
        "3. If the focus is a column, probe that column and join keys in sources "
        "when identifiable.",
        "4. Stay read-only; use LIMIT. Summarize concrete findings and what to verify next.",
        "5. SQL must avoid PostgreSQL ERROR 42702: in any join or multi-CTE query, qualify every "
        "column as alias.column (explicit AS aliases); never use bare shared names like "
        "credit_score across relations.",
    ]
    return "\n".join(parts)


def make_audit_graph(
    db_uri: str,
    *,
    max_ddls_chars: int,
    max_table_info_chars: int,
    sample_rows: int,
    include_views: bool,
) -> Any:
    lineage_app = _lineage.make_graph(db_uri, max_ddls_chars=max_ddls_chars)

    def lineage_node(state: AuditState) -> AuditState:
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
            payload = {
                "answer": out.get("answer", ""),
                "structured": out.get("structured") or {},
                "summary": out.get("summary") or {},
                "model": getattr(_lineage, "MODEL_LINEAGE", ""),
            }
            if out.get("error"):
                payload["lineage_error"] = out["error"]
            return {**state, "lineage_out": payload, "error": ""}
        except Exception as e:  # noqa: BLE001
            return {
                **state,
                "lineage_out": {"answer": "", "structured": {}, "summary": {}},
                "error": str(e),
            }

    def data_node(state: AuditState) -> AuditState:
        if state.get("error"):
            skip_msg = f"Skipped data audit: lineage step failed: {state['error']}"
            return {
                **state,
                "data_question": "",
                "data_out": {"answer": skip_msg},
            }
        dq = _build_data_question(state["question"], state["lineage_out"])
        schema = state["schema"]
        db_local = _data.build_sql_database(
            schema,
            sample_rows=sample_rows,
            view_support=include_views,
        )
        data_app = _data.make_graph(db_local, max_table_info_chars=state["max_table_info_chars"])
        try:
            dout = data_app.invoke(
                {
                    "schema": schema,
                    "question": dq,
                    "table_context": "",
                    "sql": "",
                    "sql_result": "",
                    "answer": "",
                },
            )
            data_payload = {
                "answer": dout.get("answer", ""),
                "sql": dout.get("sql", ""),
                "result_preview": (dout.get("sql_result") or "")[:16_000],
                "error": dout.get("error"),
            }
            return {**state, "data_question": dq, "data_out": data_payload}
        except Exception as e:  # noqa: BLE001
            return {
                **state,
                "data_question": dq,
                "data_out": {"answer": "", "sql": "", "result_preview": "", "error": str(e)},
            }

    graph = StateGraph(AuditState)
    graph.add_node("lineage", lineage_node)
    graph.add_node("data_audit", data_node)
    graph.add_edge(START, "lineage")
    graph.add_edge("lineage", "data_audit")
    graph.add_edge("data_audit", END)
    return graph.compile()


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Lineage (DDL) then data checks on upstream sources (read-only SELECT).",
    )
    p.add_argument("--schema", required=True, help="PostgreSQL schema.")
    p.add_argument(
        "--question",
        required=True,
        help="Table/column/mart focus + what to validate (same as lineage subagent).",
    )
    p.add_argument("--pretty", action="store_true")
    p.add_argument(
        "--max-ddls-chars",
        type=int,
        default=100_000,
        help="DDL context size for lineage step (default 100000).",
    )
    p.add_argument(
        "--max-table-info-chars",
        type=int,
        default=100_000,
        help="SQLDatabase table info cap for data step (default 100000).",
    )
    p.add_argument("--sample-rows", type=int, default=1, help="Sample rows in table info.")
    p.add_argument("--no-views", action="store_true", help="Exclude views from SQLDatabase.")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    _LOG.info("run_start schema=%s question_chars=%s", args.schema, len(args.question or ""))
    try:
        with _trace.root_agent_span(
            _LF,
            name="db_lineage_data_audit_subagent",
            input={
                "schema": args.schema,
                "question": (args.question or "")[:12_000],
            },
            metadata={"agent": "db_lineage_data_audit_subagent"},
        ) as root:
            try:
                uri = pgmeta.build_connection_string_from_environ()
                app = make_audit_graph(
                    uri,
                    max_ddls_chars=args.max_ddls_chars,
                    max_table_info_chars=args.max_table_info_chars,
                    sample_rows=args.sample_rows,
                    include_views=not args.no_views,
                )
                out = app.invoke(
                    {
                        "schema": args.schema,
                        "question": args.question,
                        "max_ddls_chars": args.max_ddls_chars,
                        "max_table_info_chars": args.max_table_info_chars,
                        "lineage_out": {},
                        "data_question": "",
                        "data_out": {},
                    },
                )
                lineage = out.get("lineage_out") or {}
                data = out.get("data_out") or {}
                lineage_answer = str(lineage.get("answer", ""))
                data_answer = str(data.get("answer", ""))
                combined_parts = [
                    "### Lineage (DDL)\n",
                    lineage_answer.strip(),
                    "",
                    "### Data audit (SELECT)\n",
                    data_answer.strip(),
                ]
                combined = "\n".join(combined_parts).strip()
                payload: dict[str, Any] = {
                    "schema": args.schema,
                    "question": args.question,
                    "combined_answer": combined,
                    "lineage": lineage,
                    "data_audit": data,
                    "meta": {"workflow": ["lineage_ddl", "data_select"]},
                }
                if out.get("error"):
                    payload["error"] = out["error"]
                print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
                if root is not None:
                    root.update(
                        output={
                            "combined_answer": combined[:16_000],
                            "data_error": data.get("error"),
                        }
                    )
                _LOG.info(
                    "run_done duration_ms=%.1f data_err=%s",
                    (time.perf_counter() - t0) * 1000,
                    bool(data.get("error")),
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
