#!/usr/bin/env python3
"""
Extract **base SQL** from:

1. A **repo file line range** (e.g. ``setup_loan_db.md`` lines 229–241 — inner SELECT/CASE for
   ``risk_category``).
2. A **PostgreSQL view** in a schema (uses ``pg_get_viewdef`` via
   ``postgres_metadata.fetch_views``).

No LLM; deterministic output JSON on stdout.

Examples::

    uv run python ai-agent-tools/agents/sql_definition_extract_subagent.py \\
      --repo-file setup_loan_db.md --lines 229 241 --pretty

    uv run python ai-agent-tools/agents/sql_definition_extract_subagent.py \\
      --schema loans --view customer_credit_risk --pretty

Environment for ``--schema`` / ``--view``: ``PG*`` / ``PG_DSN`` like other agents.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import time
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[2]

import agent_logging  # noqa: E402

_LOG = agent_logging.get_logger("agents.sql_extract")

_SCRIPTS_EXTRACT = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "sql_doc_extract.py"
_spec_ex = importlib.util.spec_from_file_location("sql_doc_extract", _SCRIPTS_EXTRACT)
if _spec_ex is None or _spec_ex.loader is None:
    raise ImportError(f"Cannot load sql_doc_extract from {_SCRIPTS_EXTRACT}")
sqlex = importlib.util.module_from_spec(_spec_ex)
_spec_ex.loader.exec_module(sqlex)

_SCRIPTS_PG = PROJECT_ROOT / "ai-agent-tools" / "scripts" / "postgres_metadata.py"
_spec_pg = importlib.util.spec_from_file_location("postgres_metadata", _SCRIPTS_PG)
if _spec_pg is None or _spec_pg.loader is None:
    raise ImportError(f"Cannot load postgres_metadata from {_SCRIPTS_PG}")
pgmeta = importlib.util.module_from_spec(_spec_pg)
_spec_pg.loader.exec_module(pgmeta)


def extract_from_repo(file_arg: str, line_start: int, line_end: int) -> dict[str, Any]:
    path = sqlex.resolve_under_project_root(PROJECT_ROOT, file_arg)
    raw = sqlex.read_line_range(path, line_start, line_end)
    optional_unfenced = sqlex.strip_sql_fence(raw)
    return {
        "mode": "repo_line_range",
        "file": str(path.relative_to(PROJECT_ROOT.resolve())),
        "line_start": line_start,
        "line_end": line_end,
        "base_sql": optional_unfenced.strip(),
        "note": "Slice as in the doc; may be a fragment inside a larger CREATE VIEW block.",
    }


def extract_from_pg_view(schema: str, view_name: str) -> dict[str, Any]:
    import psycopg

    conn_str = pgmeta.build_connection_string_from_environ()
    with psycopg.connect(conn_str) as conn:
        views = pgmeta.fetch_views(conn, schema)
    for v in views:
        if (v.get("name") or "").lower() == view_name.lower():
            ddl = v.get("ddl") or ""
            body = sqlex.extract_query_after_create_view(ddl)
            if body is None:
                body = ddl
            return {
                "mode": "pg_view",
                "schema": schema,
                "view": view_name,
                "base_sql": body,
                "wrapped_ddl_preview": ddl[:2000] + ("…" if len(ddl) > 2000 else ""),
                "description": v.get("description"),
            }
    names = [v.get("name") for v in views]
    raise ValueError(f"View {schema!r}.{view_name!r} not found. Available: {names}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Extract base SQL from a markdown line range or a DB view definition.",
    )
    p.add_argument(
        "--repo-file",
        help="Path relative to project root (or absolute under repo), e.g. setup_loan_db.md",
    )
    p.add_argument(
        "--lines",
        metavar=("START", "END"),
        nargs=2,
        type=int,
        help="Inclusive 1-based line numbers (use with --repo-file).",
    )
    p.add_argument("--schema", help="PostgreSQL schema (use with --view).")
    p.add_argument("--view", metavar="VIEW_NAME", help="Bare view name (use with --schema).")
    p.add_argument("--pretty", action="store_true", help="Pretty-print JSON.")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    t0 = time.perf_counter()
    has_repo = bool(args.repo_file)
    has_pg = bool(args.schema or args.view)
    if has_repo == has_pg:
        _LOG.warning("sql_extract_invalid_args repo=%s pg=%s", has_repo, has_pg)
        print(
            "Specify exactly one mode: (--repo-file AND --lines START END) "
            "OR (--schema AND --view).",
            file=sys.stderr,
        )
        sys.exit(2)
    if has_repo:
        if args.lines is None:
            _LOG.warning("sql_extract_missing_lines")
            print("--lines START END required with --repo-file.", file=sys.stderr)
            sys.exit(2)
        a, b = args.lines
        out = extract_from_repo(args.repo_file, a, b)
    else:
        if not args.schema or not args.view:
            print("--schema and --view are required together.", file=sys.stderr)
            sys.exit(2)
        try:
            out = extract_from_pg_view(args.schema, args.view)
        except ValueError as e:
            _LOG.warning("sql_extract_view_not_found: %s", e)
            print(str(e), file=sys.stderr)
            sys.exit(1)
    print(json.dumps(out, ensure_ascii=False, indent=2 if args.pretty else None))
    _LOG.info(
        "sql_extract_done mode=%s duration_ms=%.1f",
        out.get("mode"),
        (time.perf_counter() - t0) * 1000,
    )


if __name__ == "__main__":
    main()
