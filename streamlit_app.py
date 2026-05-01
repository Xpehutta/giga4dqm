#!/usr/bin/env python3
"""
Streamlit UI to chat with DB agents (catalog, data/SQL, lineage, audit, investigation).

Run from the project root (with dev dependencies installed):

    uv run streamlit run streamlit_app.py

Requires `.env` with PostgreSQL and GigaChat (for both agents). See `ai-agent-tools/README.md`.
Set ``LOG_LEVEL`` (e.g. ``INFO``, ``DEBUG``) for stderr logging from the UI and subprocess agents.
"""

from __future__ import annotations

import importlib.util
import json
import re
import sys
import time
from pathlib import Path
from subprocess import run
from typing import Any

import streamlit as st
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent
CATALOG_AGENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "db_catalog_agent.py"
DATA_SUBAGENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "db_data_subagent.py"
LINEAGE_AGENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "db_lineage_subagent.py"
AUDIT_AGENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "db_lineage_data_audit_subagent.py"
INVESTIGATION_AGENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "db_investigation_subagent.py"
_INTENT = PROJECT_ROOT / "ai-agent-tools" / "agents" / "intent_route.py"
_POSTGRES_METADATA = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "postgres_metadata.py"

load_dotenv(PROJECT_ROOT / ".env")

_AGENT_LOG_PATH = PROJECT_ROOT / "ai-agent-tools" / "agents" / "agent_logging.py"
_spec_al = importlib.util.spec_from_file_location("agent_logging", _AGENT_LOG_PATH)
if _spec_al is None or _spec_al.loader is None:
    raise RuntimeError("Cannot load agent_logging")
_al_mod = importlib.util.module_from_spec(_spec_al)
sys.modules[_spec_al.name] = _al_mod
_spec_al.loader.exec_module(_al_mod)
_al_mod.configure_logging()
_APP_LOG = _al_mod.get_logger("streamlit")

_spec = importlib.util.spec_from_file_location("intent_route", _INTENT)
if _spec is None or _spec.loader is None:
    raise RuntimeError("Cannot load intent_route module")
_ir = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ir)
route_db_question = _ir.route_db_question

_spec_pg = importlib.util.spec_from_file_location("postgres_metadata", _POSTGRES_METADATA)
if _spec_pg is None or _spec_pg.loader is None:
    _postgres_metadata = None
else:
    _postgres_metadata = importlib.util.module_from_spec(_spec_pg)
    _spec_pg.loader.exec_module(_postgres_metadata)


def _valid_pg_schema(s: str) -> bool:
    t = (s or "").strip()
    return bool(t and re.match(r"^[a-zA-Z0-9_]+$", t))


def _run_agent(script: Path, args: list[str], timeout: int = 300) -> tuple[int, str, str]:
    cmd = [sys.executable, str(script), *args]
    _APP_LOG.info("subprocess_start script=%s timeout=%s", script.name, timeout)
    t0 = time.perf_counter()
    r = run(
        cmd,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    ms = (time.perf_counter() - t0) * 1000
    err = r.stderr or ""
    _APP_LOG.info(
        "subprocess_end script=%s exit=%s duration_ms=%.1f stdout_chars=%s stderr_chars=%s",
        script.name,
        r.returncode,
        ms,
        len(r.stdout or ""),
        len(err),
    )
    if r.returncode != 0:
        _APP_LOG.warning(
            "subprocess_failed script=%s preview=%s",
            script.name,
            err[:800].replace("\n", " "),
        )
    return r.returncode, r.stdout, r.stderr


def _parse_json_safe(raw: str) -> dict[str, Any] | None:
    raw = (raw or "").strip()
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


# Budget for prior turns passed into CLI agents (full-text `--question` arg).
_MAX_ASSISTANT_TURN_FOR_CONTEXT = 12_000
_MAX_PRIOR_DIALOG_CHARS = 48_000


def _format_prior_dialog(
    prior_messages: list[dict[str, Any]],
) -> str:
    """Format prior user/assistant turns; drop the oldest text if over the char budget."""
    parts: list[str] = []
    for m in prior_messages:
        role = m.get("role")
        text = (m.get("text") or "").strip()
        if not text or role not in ("user", "assistant"):
            continue
        if role == "assistant" and len(text) > _MAX_ASSISTANT_TURN_FOR_CONTEXT:
            text = text[:_MAX_ASSISTANT_TURN_FOR_CONTEXT] + "\n[… truncated for context size …]"
        label = "User" if role == "user" else "Assistant"
        parts.append(f"{label}:\n{text}")
    block = "\n\n".join(parts)
    if len(block) <= _MAX_PRIOR_DIALOG_CHARS:
        return block
    tail = block[-_MAX_PRIOR_DIALOG_CHARS:].lstrip()
    if "\n\n" in tail:
        i = tail.find("\n\n")
        tail = tail[i + 2 :]
    return f"…[earlier dialog omitted]…\n\n{tail}"


def _question_with_dialog(prior_messages: list[dict[str, Any]], current_user: str) -> str:
    """Single prompt for agents: optional transcript + current user line."""
    cur = (current_user or "").strip()
    if not cur:
        return cur
    prior = _format_prior_dialog(prior_messages)
    if not prior:
        return cur
    return (
        "Conversation (for context). Answer the **Current** line using prior turns as needed.\n\n"
        f"{prior}\n\n---\n\nCurrent:\n{cur}"
    )


st.set_page_config(
    page_title="Giga4DQM · DB agents",
    page_icon="🗃️",
    layout="centered",
    initial_sidebar_state="expanded",
)


@st.cache_data(ttl=120, show_spinner="Listing schemas…")
def _list_app_schemas() -> tuple[list[str], str | None]:
    if _postgres_metadata is None:
        return [], "Could not load postgres_metadata"
    try:
        return _postgres_metadata.list_schemas_from_environ(), None
    except Exception as e:  # noqa: BLE001
        return [], str(e)


st.title("Converse with DB agents")
st.caption(
    "**Auto** — routes to catalog, data, lineage, audit, **investigate**, or both "
    "(metadata+data). **investigate** = pasted SQL + suspicion → lineage + diagnostic SELECTs.  \n"
    "**Catalog** — metadata + DDL. **Data** — read-only `SELECT`. "
    "**Lineage** — upstream/downstream from views/routines (GigaChat-Pro). "
    "**Audit** — lineage then one **SELECT** on upstream data. "
    "**Investigate** — lineage for the column then **multiple** guided SELECT proposals.  \n"
    "Earlier turns are sent as **dialog context** (bounded size)."
)

with st.sidebar:
    st.subheader("Settings")

    def _label_mode(x: str) -> str:
        return {
            "auto": "Auto (route from question)",
            "catalog": "Catalog (metadata + DDL)",
            "data": "Data (row-level SQL)",
            "lineage": "Lineage (views & routines → table/column)",
            "audit": "Audit (lineage + one source data check)",
            "investigate": "Investigate (lineage + diagnostic SQL bundle)",
        }[x]

    mode = st.radio(
        "Agent",
        options=["auto", "catalog", "data", "lineage", "audit", "investigate"],
        index=0,
        format_func=_label_mode,
        horizontal=False,
    )
    st.subheader("Schema")
    all_schemas, disc_err = _list_app_schemas()
    non_public = [n for n in all_schemas if n != "public"]
    has_public = "public" in all_schemas
    if disc_err:
        st.caption(f"Could not list schemas: {disc_err}")
    override = st.text_input(
        "Override (optional)",
        value="",
        help="If set, wins over the list; unquoted identifier (letters, digits, _).",
    )
    o = override.strip()
    if o:
        schema_effective = o
        st.caption(f"**Using:** `{schema_effective}` (override)")
    elif non_public:
        opts = non_public + (["public"] if has_public else [])
        pick = st.selectbox(
            (
                "Detected schemas (non-`public` first; `public` last if present — "
                "not auto-defaulted as first choice)."
            ),
            opts,
            index=0,
        )
        schema_effective = str(pick)
    elif has_public and not non_public:
        st.warning(
            "Only the `public` schema was found. This app does **not** default to it. "
            "Use **Override** above, or type the name below (e.g. `public`) if you intend it."
        )
        man = st.text_input(
            "Schema name",
            value="",
            key="sc_only_public",
            placeholder="e.g. public or your schema",
        )
        schema_effective = man.strip()
    else:
        st.caption(
            "No non-system schemas from discovery, or the list is empty. "
            "Enter a schema name below."
        )
        man2 = st.text_input(
            "Schema (required)",
            value="",
            key="sc_required",
            help="Unquoted name; use Override instead if you prefer.",
        )
        schema_effective = man2.strip()
    if not _valid_pg_schema(schema_effective) and schema_effective:
        st.error("Schema must be an unquoted identifier (letters, digits, underscore only).")
    if mode in ("auto", "data", "audit"):
        max_info = st.number_input(
            "Max table-info chars (Data / Audit / Auto→Data or Auto→Audit)",
            min_value=5_000,
            max_value=500_000,
            value=80_000,
            step=5_000,
        )
    else:
        max_info = 80_000
    if mode in ("auto", "lineage", "audit", "investigate"):
        max_ddls = st.number_input(
            "Max DDL context chars (Lineage / Audit)",
            min_value=10_000,
            max_value=250_000,
            value=100_000,
            step=10_000,
        )
    else:
        max_ddls = 100_000
    st.caption(
        "In **Auto**, routing includes **investigate** when you paste SQL and suspect bad values."
    )
    st.divider()
    if st.button("Clear conversation"):
        st.session_state.pop("chat_messages", None)
        st.rerun()

if "chat_messages" not in st.session_state:
    st.session_state.chat_messages = []

for msg in st.session_state.chat_messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["text"])
        if msg.get("details") is not None:
            with st.expander("Raw JSON / details"):
                st.json(msg["details"])


def _format_catalog_response(data: dict[str, Any]) -> str:
    main = str(data.get("answer", ""))
    lines = [main]
    st_struct = data.get("structured")
    if isinstance(st_struct, dict):
        ctab = st_struct.get("cited_table_names") or []
        cr = st_struct.get("cited_routine_names") or []
        if ctab:
            lines.append("\n*Cited tables:* " + ", ".join(f"`{x}`" for x in ctab))
        if cr:
            lines.append("\n*Cited routines:* " + ", ".join(f"`{x}`" for x in cr))
    return "\n".join(lines)


def _format_lineage_response(data: dict[str, Any]) -> str:
    main = str(data.get("answer", ""))
    lines = [main]
    st_struct = data.get("structured")
    if isinstance(st_struct, dict):
        up = st_struct.get("upstream_objects") or []
        down = st_struct.get("downstream_objects") or []
        if up:
            lines.append("\n*Upstream (sources):* " + ", ".join(f"`{x}`" for x in up))
        if down:
            lines.append("\n*Downstream (consumers):* " + ", ".join(f"`{x}`" for x in down))
        cite = st_struct.get("cited_object_names") or []
        if cite:
            lines.append("\n*Cited in DDL:* " + ", ".join(f"`{x}`" for x in cite))
        defs = st_struct.get("defining_expressions") or []
        if isinstance(defs, list) and defs:
            lines.append("\n**Definition from DDL (verbatim):**")
            for block in defs[:12]:
                if str(block).strip():
                    lines.append("\n```sql\n" + str(block).strip()[:8_000] + "\n```")
    mm = data.get("model")
    if mm:
        lines.append(f"\n*Model:* `{mm}`")
    return "\n".join(lines)


def _format_data_response(data: dict[str, Any]) -> str:
    main = str(data.get("answer", ""))
    parts = [main]
    sql = data.get("sql")
    if sql:
        parts.append("\n**SQL**:\n```sql\n" + str(sql)[:4_000] + "\n```")
    pre = data.get("result_preview")
    if pre is not None and str(pre).strip():
        parts.append("\n**Result (preview)**:\n```\n" + str(pre)[:2_000] + "\n```")
    if data.get("error"):
        parts.append("\n*Diagnostics:*\n```\n" + str(data.get("error"))[:2_000] + "\n```")
    return "\n".join(parts)


def _format_audit_response(data: dict[str, Any]) -> str:
    main = str(data.get("combined_answer", "")).strip()
    lines = [main] if main else []
    lin = data.get("lineage") or {}
    st_struct = lin.get("structured")
    if isinstance(st_struct, dict):
        up = st_struct.get("upstream_objects") or []
        down = st_struct.get("downstream_objects") or []
        if up:
            lines.append("\n*Upstream (sources):* " + ", ".join(f"`{x}`" for x in up))
        if down:
            lines.append("\n*Downstream (consumers):* " + ", ".join(f"`{x}`" for x in down))
        defs = st_struct.get("defining_expressions") or []
        if isinstance(defs, list) and defs:
            lines.append("\n**Definition from DDL (verbatim):**")
            for block in defs[:12]:
                if str(block).strip():
                    lines.append("\n```sql\n" + str(block).strip()[:8_000] + "\n```")
    da = data.get("data_audit") or {}
    sql = da.get("sql")
    if sql:
        lines.append("\n**Data audit SQL**:\n```sql\n" + str(sql)[:4_000] + "\n```")
    pre = da.get("result_preview")
    if pre is not None and str(pre).strip():
        lines.append("\n**Result (preview)**:\n```\n" + str(pre)[:2_000] + "\n```")
    if da.get("error"):
        lines.append("\n*Data step diagnostics:*\n```\n" + str(da.get("error"))[:2_000] + "\n```")
    if data.get("error"):
        lines.append("\n*Workflow:*\n```\n" + str(data.get("error"))[:2_000] + "\n```")
    return "\n".join(lines) if lines else "(empty)"


def _format_investigation_response(data: dict[str, Any]) -> str:
    lin = data.get("lineage") or {}
    lines: list[str] = []
    main = str(lin.get("answer", "")).strip()
    if main:
        lines.append("### Lineage (DDL)\n" + main)
    st_struct = lin.get("structured")
    if isinstance(st_struct, dict):
        up = st_struct.get("upstream_objects") or []
        down = st_struct.get("downstream_objects") or []
        if up:
            lines.append("\n*Upstream (sources):* " + ", ".join(f"`{x}`" for x in up))
        if down:
            lines.append("\n*Downstream (consumers):* " + ", ".join(f"`{x}`" for x in down))
        cite = st_struct.get("cited_object_names") or []
        if cite:
            lines.append("\n*Cited in DDL:* " + ", ".join(f"`{x}`" for x in cite))
        defs = st_struct.get("defining_expressions") or []
        if isinstance(defs, list) and defs:
            lines.append("\n**Definition from DDL (verbatim):**")
            for block in defs[:12]:
                if str(block).strip():
                    lines.append("\n```sql\n" + str(block).strip()[:8_000] + "\n```")
    inv = data.get("investigation") or {}
    summ = str(inv.get("lineage_context_summary") or "").strip()
    if summ:
        lines.append("\n### Investigation summary\n" + summ)
    qs = inv.get("queries") or []
    for i, q in enumerate(qs, 1):
        if not isinstance(q, dict):
            continue
        purpose = str(q.get("purpose") or "").strip()
        sql = str(q.get("sql") or "").strip()
        ro = q.get("readonly_ok")
        warn = "" if ro else " *(did not pass read-only validation)*"
        lines.append(f"\n**Suggested query {i}** — {purpose}{warn}\n```sql\n{sql[:6_000]}\n```")
    mm = inv.get("model")
    if mm:
        lines.append(f"\n*Model:* `{mm}`")
    return "\n".join(lines) if lines else "(empty)"


def _process_agent_output(
    mode_label: str,
    code: int,
    out: str,
    err: str,
    *,
    output_kind: str,
) -> tuple[str, dict[str, Any] | None]:
    if code != 0:
        tail = err or out or "(no output)"
        body = f"**{mode_label}** — process exited {code}\n\n```\n{tail}\n```"
        return body, {"exit_code": code, "stdout": out, "stderr": err}
    data = _parse_json_safe(out)
    if data is None:
        return (
            f"**{mode_label}** — could not parse JSON.\n\n```\n{out[:4_000]}\n```",
            None,
        )
    if output_kind == "catalog":
        return _format_catalog_response(data), data
    if output_kind == "lineage":
        return _format_lineage_response(data), data
    if output_kind == "audit":
        return _format_audit_response(data), data
    if output_kind == "investigate":
        return _format_investigation_response(data), data
    return _format_data_response(data), data


if prompt := st.chat_input("Ask about the database…"):
    if not _valid_pg_schema(schema_effective):
        st.session_state.chat_messages.append(
            {
                "role": "user",
                "text": prompt,
            }
        )
        _schema_help = (
            "Set a valid **PostgreSQL schema** in the sidebar first. "
            "This app does not default to `public`. Use discovery, **Override**, "
            "or the required name field, then try again."
        )
        _APP_LOG.warning("chat_turn schema_invalid effective=%r", schema_effective)
        st.session_state.chat_messages.append(
            {
                "role": "assistant",
                "text": _schema_help,
                "details": None,
            }
        )
        st.rerun()
    st.session_state.chat_messages.append({"role": "user", "text": prompt})
    sc = schema_effective.strip()
    _prior = st.session_state.chat_messages[:-1]
    question_for_agents = _question_with_dialog(_prior, prompt)
    _APP_LOG.info(
        "chat_turn mode=%s schema=%s prompt_chars=%s agent_question_chars=%s",
        mode,
        sc,
        len(prompt),
        len(question_for_agents),
    )
    data_args = [
        "--schema",
        sc,
        "--question",
        question_for_agents,
        "--pretty",
        "--max-table-info-chars",
        str(int(max_info)),
    ]
    audit_args = [
        "--schema",
        sc,
        "--question",
        question_for_agents,
        "--pretty",
        "--max-ddls-chars",
        str(int(max_ddls)),
        "--max-table-info-chars",
        str(int(max_info)),
    ]
    investigation_args = [
        "--schema",
        sc,
        "--question",
        question_for_agents,
        "--pretty",
        "--max-ddls-chars",
        str(int(max_ddls)),
    ]

    if mode == "auto":
        route_err: str | None = None
        with st.spinner("Choosing catalog / data / lineage / audit / investigate…"):
            try:
                rkind = route_db_question(question_for_agents)
            except Exception as e:  # noqa: BLE001
                rkind = "catalog"
                route_err = str(e)
        route_note = f"*Router:* **{rkind}**"
        if route_err:
            route_note += f" (classifier error, used catalog: {route_err})"
        if rkind == "catalog":
            with st.spinner("Running catalog agent…"):
                code, out, err = _run_agent(
                    CATALOG_AGENT,
                    ["--schema", sc, "--question", question_for_agents, "--pretty"],
                )
            text, det = _process_agent_output(
                "Catalog", code, out, err, output_kind="catalog",
            )
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": route_note + "\n\n" + text,
                    "details": det,
                }
            )
        elif rkind == "lineage":
            with st.spinner("Running lineage subagent…"):
                code, out, err = _run_agent(
                    LINEAGE_AGENT,
                    [
                        "--schema",
                        sc,
                        "--question",
                        question_for_agents,
                        "--pretty",
                        "--max-ddls-chars",
                        str(int(max_ddls)),
                    ],
                )
            text, det = _process_agent_output(
                "Lineage (SQL)", code, out, err, output_kind="lineage",
            )
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": route_note + "\n\n" + text,
                    "details": det,
                }
            )
        elif rkind == "investigate":
            with st.spinner("Running lineage + investigation SQL bundle…"):
                code, out, err = _run_agent(INVESTIGATION_AGENT, investigation_args, timeout=600)
            text, det = _process_agent_output(
                "Investigate (lineage + SQL bundle)",
                code,
                out,
                err,
                output_kind="investigate",
            )
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": route_note + "\n\n" + text,
                    "details": det,
                }
            )
        elif rkind == "audit":
            with st.spinner("Running lineage + data audit subagent…"):
                code, out, err = _run_agent(AUDIT_AGENT, audit_args, timeout=600)
            text, det = _process_agent_output(
                "Audit (lineage + data)",
                code,
                out,
                err,
                output_kind="audit",
            )
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": route_note + "\n\n" + text,
                    "details": det,
                }
            )
        elif rkind == "data":
            with st.spinner("Running data subagent…"):
                code, out, err = _run_agent(DATA_SUBAGENT, data_args)
            text, det = _process_agent_output("Data", code, out, err, output_kind="data")
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": route_note + "\n\n" + text,
                    "details": det,
                }
            )
        else:
            parts = [route_note, ""]
            details_merged: dict[str, Any] = {"route": "both"}
            with st.spinner("Running catalog agent…"):
                c_code, c_out, c_err = _run_agent(
                    CATALOG_AGENT,
                    ["--schema", sc, "--question", question_for_agents, "--pretty"],
                )
            t1, d1 = _process_agent_output(
                "Metadata", c_code, c_out, c_err, output_kind="catalog",
            )
            parts.append("### Metadata (catalog)\n" + t1)
            if d1 is not None:
                details_merged["catalog"] = d1
            with st.spinner("Running data subagent…"):
                d_code, d_out, d_err = _run_agent(DATA_SUBAGENT, data_args)
            t2, d2 = _process_agent_output(
                "Data (SQL)", d_code, d_out, d_err, output_kind="data",
            )
            parts.append("\n### Data (row-level)\n" + t2)
            if d2 is not None:
                details_merged["data"] = d2
            st.session_state.chat_messages.append(
                {
                    "role": "assistant",
                    "text": "\n\n".join(parts),
                    "details": details_merged,
                }
            )
    elif mode == "catalog":
        with st.spinner("Running catalog agent…"):
            code, out, err = _run_agent(
                CATALOG_AGENT,
                ["--schema", sc, "--question", question_for_agents, "--pretty"],
            )
        text, det = _process_agent_output("Catalog", code, out, err, output_kind="catalog")
        st.session_state.chat_messages.append({"role": "assistant", "text": text, "details": det})
    elif mode == "lineage":
        with st.spinner("Running lineage subagent…"):
            code, out, err = _run_agent(
                LINEAGE_AGENT,
                [
                    "--schema",
                    sc,
                    "--question",
                    question_for_agents,
                    "--pretty",
                    "--max-ddls-chars",
                    str(int(max_ddls)),
                ],
            )
        text, det = _process_agent_output("Lineage (SQL)", code, out, err, output_kind="lineage")
        st.session_state.chat_messages.append({"role": "assistant", "text": text, "details": det})
    elif mode == "investigate":
        with st.spinner("Running lineage + investigation SQL bundle…"):
            code, out, err = _run_agent(INVESTIGATION_AGENT, investigation_args, timeout=600)
        text, det = _process_agent_output(
            "Investigate (lineage + SQL bundle)",
            code,
            out,
            err,
            output_kind="investigate",
        )
        st.session_state.chat_messages.append({"role": "assistant", "text": text, "details": det})
    elif mode == "audit":
        with st.spinner("Running lineage + data audit subagent…"):
            code, out, err = _run_agent(AUDIT_AGENT, audit_args, timeout=600)
        text, det = _process_agent_output(
            "Audit (lineage + data)", code, out, err, output_kind="audit",
        )
        st.session_state.chat_messages.append({"role": "assistant", "text": text, "details": det})
    else:
        with st.spinner("Running data subagent…"):
            code, out, err = _run_agent(DATA_SUBAGENT, data_args)
        text, det = _process_agent_output("Data", code, out, err, output_kind="data")
        st.session_state.chat_messages.append({"role": "assistant", "text": text, "details": det})
    st.rerun()

if not st.session_state.chat_messages:
    st.info(
        "Choose **Auto** to route each question "
        "(including **investigate**: pasted SQL + suspicion → lineage + diagnostic SELECTs), "
        "or fixed **Catalog** / **Data** / **Lineage** / **Audit** / **Investigate**. "
        "Pick or enter a **PostgreSQL schema** in the sidebar "
        "(the app does not default to `public`), then type below.",
    )
