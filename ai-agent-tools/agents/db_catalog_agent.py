#!/usr/bin/env python3
"""
LangGraph agent for PostgreSQL catalog Q&A.

It uses:
- in-process metadata fetch: ai-agent-tools/scripts/postgres_metadata.py
  (pg_catalog DDL + information_schema tallies)
- LangGraph workflow
- GigaChat for answer generation
- PydanticOutputParser for structured JSON answers

Environment:
- Loads variables from project .env by default.
- Requires GigaChat credentials:
  - GIGACHAT_API_KEY or GIGACHAT_EMBEDDINGS_CREDENTIALS
- PostgreSQL: PG* variables or PG_DSN
- Optional: ``GIGACHAT_CONNECT_TIMEOUT`` — longer SSL connect budget (see
  ``apply_gigachat_http_timeouts.py``).
- Optional **Langfuse:** ``LANGFUSE_PUBLIC_KEY`` and ``LANGFUSE_SECRET_KEY`` (see
  ``ai-agent-tools/README.md``) trace GigaChat generations and agent runs.
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
from langchain_core.tools import tool
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

_LOG = agent_logging.get_logger("agents.catalog")

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

from gigachat import GigaChat  # noqa: E402
from gigachat.models import Chat, Messages, MessagesRole  # noqa: E402

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

TOOLS_DOC_PATH = PROJECT_ROOT / "ai-agent-tools" / "tools.md"
SYSTEM_PROMPT_PATH = PROJECT_ROOT / "ai-agent-tools" / "prompts" / "db_catalog_system_prompt.md"
USER_PROMPT_PATH = PROJECT_ROOT / "ai-agent-tools" / "prompts" / "db_catalog_user_prompt.md"

STRUCTURED_INSTRUCTIONS = (
    "\n\nYou MUST respond with a single JSON object only (no markdown code fences) that "
    "matches the schema below. The JSON must be valid UTF-8 and parseable.\n"
)


def read_text_or_default(path: Path, default: str) -> str:
    if path.exists():
        return path.read_text(encoding="utf-8").strip()
    return default


class CatalogAnswer(BaseModel):
    """User-facing answer plus citation hints grounded in the catalog context."""

    answer: str = Field(
        description="Main answer. Markdown or plain text. Must follow facts from the context only."
    )
    cited_table_names: list[str] = Field(
        default_factory=list,
        description="Table names from the context the answer explicitly relies on (may be empty).",
    )
    cited_routine_names: list[str] = Field(
        default_factory=list,
        description="Function/procedure base names (proname) from the context, if any.",
    )
    missing_in_catalog: list[str] = Field(
        default_factory=list,
        description="Object names the user asked about that are not present in the context.",
    )


_output_parser = PydanticOutputParser(pydantic_object=CatalogAnswer)


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


def _parse_structured(raw: str) -> CatalogAnswer:
    cleaned = _strip_code_fence(raw)
    try:
        return _output_parser.parse(cleaned)
    except Exception:
        return CatalogAnswer(
            answer=raw,
            cited_table_names=[],
            cited_routine_names=[],
            missing_in_catalog=[],
        )


class AgentState(TypedDict):
    schema: str
    question: str
    catalog: dict[str, Any]
    answer: str
    structured: NotRequired[dict[str, Any]]


AgentState.__annotations__["structured"] = NotRequired[dict[str, Any]]


@tool
def export_catalog_tool(schema: str) -> dict[str, Any]:
    """Return catalog JSON: pg_catalog DDL plus an information_schema tally."""
    conn_str = pgmeta.build_connection_string_from_environ()
    with psycopg.connect(conn_str) as conn:
        return pgmeta.fetch_schema_catalog(conn, schema, {"tables", "views", "procedures"})


def fetch_catalog_node(state: AgentState) -> AgentState:
    _LOG.debug("node_fetch_catalog schema=%s", state["schema"])
    catalog = export_catalog_tool.invoke({"schema": state["schema"]})
    ntab = len(catalog.get("tables") or [])
    _LOG.debug(
        "node_fetch_catalog_done tables=%s views=%s",
        ntab,
        len(catalog.get("views") or []),
    )
    return {**state, "catalog": catalog}


def answer_node(state: AgentState) -> AgentState:
    tables = state["catalog"].get("tables", [])
    views = state["catalog"].get("views", [])
    procedures = state["catalog"].get("procedures", [])
    info_ischema = state["catalog"].get("information_schema", {})

    context: dict[str, Any] = {
        "schema": state["catalog"].get("schema", state["schema"]),
        "table_count": len(tables),
        "view_count": len(views),
        "procedure_count": len(procedures),
        "information_schema": info_ischema,
        "tables": [
            {
                "name": t.get("name"),
                "description": t.get("description"),
                "columns": [
                    {"name": c.get("column_name"), "description": c.get("description")}
                    for c in t.get("columns", [])[:40]
                ],
                "ddl": t.get("ddl", "")[:2000],
            }
            for t in tables[:80]
        ],
        "views": [
            {
                "name": v.get("name"),
                "description": v.get("description"),
                "ddl": v.get("ddl", "")[:2000],
            }
            for v in views[:80]
        ],
        "procedures": [
            {
                "name": p.get("name"),
                "signature": p.get("signature"),
                "kind": p.get("kind"),
                "description": p.get("description"),
                "ddl": p.get("ddl", "")[:2000],
            }
            for p in procedures[:120]
        ],
    }

    default_tools_doc = (
        "Tool: export_catalog_tool(schema) -> JSON with tables/views/procedures and DDL.\n"
        "Use tool output as source of truth. information_schema key has SQL-standard tallies."
    )
    default_system_prompt = (
        "You are a PostgreSQL catalog assistant. "
        "Answer using ONLY the provided catalog context and tool documentation. "
        "If information is missing, say so clearly."
    )
    default_user_prompt_template = (
        "Schema: {schema}\n"
        "Question: {question}\n\n"
        "Tool documentation:\n{tools_doc}\n\n"
        "Catalog context JSON:\n{context_json}"
    )

    tools_doc = read_text_or_default(TOOLS_DOC_PATH, default_tools_doc)
    system_prompt = read_text_or_default(SYSTEM_PROMPT_PATH, default_system_prompt)
    user_prompt_template = read_text_or_default(USER_PROMPT_PATH, default_user_prompt_template)
    user_prompt = user_prompt_template.format(
        schema=state["schema"],
        question=state["question"],
        tools_doc=tools_doc,
        context_json=json.dumps(context, ensure_ascii=False),
    )
    system_prompt = (
        system_prompt
        + STRUCTURED_INSTRUCTIONS
        + _output_parser.get_format_instructions()
    )
    user_prompt = user_prompt + "\n\nReturn only the JSON object, nothing else."

    chat_request = Chat(
        messages=[
            Messages(role=MessagesRole.SYSTEM, content=system_prompt),
            Messages(role=MessagesRole.USER, content=user_prompt),
        ]
    )
    response = _trace.traced_giga_chat(
        _LF,
        giga,
        chat_request,
        observation_name="db_catalog.answer",
        model=MODEL,
    )
    raw = response.choices[0].message.content
    if raw is None:
        raw = ""
    parsed = _parse_structured(raw)
    structured = parsed.model_dump()
    _LOG.debug("node_answer_done response_chars=%s", len(raw))
    return {**state, "answer": parsed.answer, "structured": structured}


def build_graph():
    graph = StateGraph(AgentState)
    graph.add_node("fetch_catalog", fetch_catalog_node)
    graph.add_node("answer", answer_node)
    graph.add_edge(START, "fetch_catalog")
    graph.add_edge("fetch_catalog", "answer")
    graph.add_edge("answer", END)
    return graph.compile()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ask DB metadata questions via LangGraph + GigaChat.",
    )
    parser.add_argument("--schema", default="public", help="Schema to inspect.")
    parser.add_argument("--question", required=True, help="Natural-language question.")
    parser.add_argument("--pretty", action="store_true", help="Pretty print final payload.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    _LOG.info("run_start schema=%s question_chars=%s", args.schema, len(args.question or ""))
    try:
        with _trace.root_agent_span(
            _LF,
            name="db_catalog_agent",
            input={
                "schema": args.schema,
                "question": (args.question or "")[:12_000],
            },
            metadata={"agent": "db_catalog_agent"},
        ) as root:
            try:
                app = build_graph()
                result = app.invoke(
                    {
                        "schema": args.schema,
                        "question": args.question,
                        "catalog": {},
                        "answer": "",
                    }
                )
                out_structured = result.get("structured", {})
                payload = {
                    "schema": args.schema,
                    "question": args.question,
                    "answer": result["answer"],
                    "summary": {
                        "tables": len(result["catalog"].get("tables", [])),
                        "views": len(result["catalog"].get("views", [])),
                        "procedures": len(result["catalog"].get("procedures", [])),
                    },
                }
                if out_structured is not None:
                    payload["structured"] = out_structured
                print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
                if root is not None:
                    root.update(
                        output={
                            "answer": (result.get("answer") or "")[:16_000],
                            "summary": payload["summary"],
                        }
                    )
                _LOG.info(
                    "run_done duration_ms=%.1f summary=%s",
                    (time.perf_counter() - t0) * 1000,
                    payload["summary"],
                )
            except Exception:
                if root is not None:
                    root.update(level="ERROR", status_message="run_failed")
                raise
    except Exception:
        _LOG.exception(
            "run_failed duration_ms=%.1f",
            (time.perf_counter() - t0) * 1000,
        )
        raise
    finally:
        _trace.flush_langfuse(_LF)


if __name__ == "__main__":
    main()
