"""
Route a natural-language question to catalog (metadata), data (row-level SQL), lineage (DDL-based
upstream/downstream), or both catalog+data.

Used by the Streamlit app in **auto** mode. One short GigaChat call; the reply is parsed with
``PydanticOutputParser`` (`RouterAnswer`); on parse errors falls back to ``json.loads`` or
**catalog**.

With Langfuse keys set, the LLM classification step is traced as a generation.
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
import sys
from pathlib import Path
from typing import Literal

from dotenv import load_dotenv
from langchain_core.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field

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
TIMEOUT = int(
    os.getenv("GIGACHAT_INTENT_TIMEOUT") or os.getenv("GIGACHAT_TIMEOUT", "60"),
)

giga = GigaChat(
    model=MODEL,
    credentials=GIGACHAT_CREDENTIALS,
    base_url=GIGACHAT_BASE_URL,
    verify_ssl_certs=VERIFY_SSL,
    scope=SCOPE,
    timeout=TIMEOUT,
)

_AGENTS_DIR = Path(__file__).resolve().parent


# Sibling modules (agent_langfuse, agent_logging) are imported by name. When this file is
# executed via ``importlib`` (Streamlit), ``ai-agent-tools/agents`` is not on ``sys.path``.
# ``streamlit_app`` registers ``agent_logging`` in ``sys.modules`` before loading this module.
def _load_agent_module(mod_name: str, filename: str):
    existing = sys.modules.get(mod_name)
    if existing is not None:
        return existing
    path = _AGENTS_DIR / filename
    spec = importlib.util.spec_from_file_location(mod_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {mod_name} from {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[mod_name] = mod
    spec.loader.exec_module(mod)
    return mod


_trace = _load_agent_module("agent_langfuse", "agent_langfuse.py")
agent_logging = _load_agent_module("agent_logging", "agent_logging.py")

_LOG = agent_logging.get_logger("agents.intent")
_LF = _trace.get_langfuse_client()

RouteKind = Literal["catalog", "data", "both", "lineage", "audit", "investigate"]


class RouterAnswer(BaseModel):
    """Router JSON before mapping to ``RouteKind``."""

    route: str = Field(
        description=(
            'Exactly one of: "catalog", "data", "lineage", "audit", "both", "investigate".'
        ),
    )


_route_parser = PydanticOutputParser(pydantic_object=RouterAnswer)

_SYSTEM = (
    "You choose which backend answers a user question about a PostgreSQL database.\n"
    "- catalog: metadata/DDL — list or describe tables, views, columns, types, "
    "comments, routines; no row values.\n"
    "- data: ONLY when the request is a **straightforward** row-level query "
    "(counts, sums, filters, samples, aggregates) **without** asking why a value might "
    "be wrong or without needing column/table semantics alongside the numbers.\n"
    "- lineage: upstream/downstream for a **specific** table/column using **DDL only**, "
    "no synthesized investigative SQL bundle.\n"
    "- audit: DDL lineage **plus** one interactive **data** pass over upstream rows "
    "(pipelines / marts / layers).\n"
    "- investigate: user embeds **SQL** (often SELECT … FROM …), suspects a **wrong "
    "column value** or bad data, and needs **column lineage from metadata** followed "
    "by **multiple suggested read-only SELECTs** along upstream sources to diagnose "
    "(not catalog-only, not bare lineage-only). If they name **one** suspect column "
    "(e.g. \"error in value for column status_code\") or paste single-column SELECT, scope "
    "investigation to **that column only** unless they ask otherwise.\n"
    "- both: metadata **and** one row-level SELECT — use when the user needs definitions "
    "**and** a single query result **without** pasted suspicious SQL, or without needing "
    "a **bundle** of lineage-driven diagnostic SELECTs.\n"
    "Reply with a single JSON object only (no markdown fences).\n\n"
    + _route_parser.get_format_instructions()
)


_QUALIFIED_REL_RE = re.compile(
    # table.column or schema.table.column (unquoted Postgres-like identifiers)
    r"\b[a-zA-Z_][\w]*\.[a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*)?\b",
)


def _explicit_lineage_request(low: str) -> bool:
    """
    User clearly asks for DDL lineage for a qualified table/column, without pasted SQL or
    data-quality suspicion. Avoids LLM misroutes (e.g. column names overlapping prompt examples).
    """
    if not re.search(r"\b(lineage|upstream|downstream|provenance|came\s+from)\b", low):
        return False
    if _QUALIFIED_REL_RE.search(low) is None:
        return False
    if _investigation_heuristic(low):
        return False
    if (
        "possible error" in low
        or "wrong value" in low
        or "incorrect value" in low
        or "invalid value" in low
        or "error in a value" in low
        or "error in the value" in low
    ):
        return False
    if "investigate" in low:
        return False
    return True


def _investigation_heuristic(low: str) -> bool:
    """Question reads like pasted SQL plus suspicion about wrong values."""
    if "select" not in low or "from" not in low:
        return False
    return any(
        p in low
        for p in (
            "possible error",
            "wrong",
            "incorrect",
            "suspicious",
            "invalid",
            "mistake",
            "bad value",
            "bad data",
            "should not",
            "unexpected",
            "help me",
            "check this",
        )
    )


def _heuristic_route(question: str) -> RouteKind | None:
    """
    Prefer ``investigate`` for SQL + suspicion; ``both`` for broader diagnostics.

    Keeps routing stable when the LLM would otherwise pick bare ``data``.
    """
    low = (question or "").lower()
    if not low.strip():
        return None
    inv = _investigation_heuristic(low)
    if inv:
        return "investigate"
    suspects_bad_value = (
        "possible error" in low
        or "wrong value" in low
        or "incorrect value" in low
        or "invalid value" in low
        or "error in a value" in low
        or "error in the value" in low
    )
    wants_help_reason = (
        ("help" in low or "please" in low)
        and ("check" in low or "validate" in low)
        and (
            "error" in low
            or "wrong" in low
            or "correct" in low
            or "explain" in low
            or "suspicious" in low
            or "invalid" in low
        )
    )
    asks_correctness = (
        "investigate" in low
        or "is this correct" in low
        or "could this be wrong" in low
    )
    if suspects_bad_value or asks_correctness or wants_help_reason:
        return "both"
    return None


def _strip_json_fences(s: str) -> str:
    t = s.strip()
    m = re.match(r"^```(?:json)?\s*([\s\S]*?)```\s*$", t)
    if m:
        return m.group(1).strip()
    return t


def route_db_question(question: str) -> RouteKind:
    """
    Return which agent(s) to run: includes ``investigate`` for SQL+suspicion workflows.

    Defaults to 'catalog' if the model output cannot be parsed.
    """
    q = (question or "").strip()
    if not q:
        _LOG.info("route_decision route=catalog via=empty")
        return "catalog"
    low = q.lower()
    if _explicit_lineage_request(low):
        _LOG.info(
            "route_decision route=lineage via=explicit_lineage question_chars=%s",
            len(q),
        )
        return "lineage"
    hinted = _heuristic_route(q)
    if hinted is not None:
        _LOG.info(
            "route_decision route=%s via=heuristic question_chars=%s",
            hinted,
            len(q),
        )
        return hinted
    user = f"User question:\n{q}"
    req = Chat(
        messages=[
            Messages(role=MessagesRole.SYSTEM, content=_SYSTEM),
            Messages(role=MessagesRole.USER, content=user),
        ]
    )
    _LOG.debug("route_llm_call question_chars=%s", len(q))
    resp = _trace.traced_giga_chat(
        _LF,
        giga,
        req,
        observation_name="intent_route.classify",
        model=MODEL,
    )
    raw = (resp.choices[0].message.content or "").strip()
    _trace.flush_langfuse(_LF)
    cleaned = _strip_json_fences(raw)
    try:
        parsed = _route_parser.parse(cleaned)
        r = parsed.route.lower().strip()
        if r in ("catalog", "data", "both", "lineage", "audit", "investigate"):
            _LOG.info("route_decision route=%s via=llm_pydantic", r)
            return r  # type: ignore[return-value]
    except Exception:
        pass
    try:
        obj = json.loads(cleaned)
        r = (obj.get("route") or "").lower().strip()
        if r in ("catalog", "data", "both", "lineage", "audit", "investigate"):
            _LOG.info("route_decision route=%s via=llm_json", r)
            return r  # type: ignore[return-value]
    except (json.JSONDecodeError, TypeError, AttributeError):
        pass
    _LOG.warning(
        "route_decision route=catalog via=fallback question_chars=%s",
        len(q),
    )
    return "catalog"
