#!/usr/bin/env python3
"""
Helpers to extract **base SQL** from repo markdown slices or wrapped CREATE VIEW DDL.

Used by ``sql_definition_extract_subagent.py``. Pure Python — no DB dependency here.
"""

from __future__ import annotations

import re
from pathlib import Path


def resolve_under_project_root(project_root: Path, path_arg: str) -> Path:
    """
    Resolve ``path_arg`` (relative or absolute) and ensure it stays under ``project_root``.
    """
    root = project_root.resolve()
    raw = Path(path_arg.strip())
    candidate = raw.resolve() if raw.is_absolute() else (root / raw).resolve()
    root_resolved = root.resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError as e:
        raise ValueError(f"Path must be inside project root {root_resolved}: {candidate}") from e
    return candidate


def read_line_range(path: Path, line_start: int, line_end: int) -> str:
    """Return inclusive 1-based line slice from UTF-8 text file."""
    if line_start < 1 or line_end < line_start:
        raise ValueError(f"Invalid line range: {line_start}-{line_end}")
    lines = path.read_text(encoding="utf-8").splitlines()
    if line_end > len(lines):
        raise ValueError(f"End line {line_end} past EOF ({len(lines)} lines)")
    return "\n".join(lines[line_start - 1 : line_end])


_re_create_view_as_body = re.compile(
    r"(?is)^CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+.+\s+AS\s*\r?\n([\s\S]*)",
)


def extract_query_after_create_view(ddl: str) -> str | None:
    """
    Strip ``CREATE [OR REPLACE] VIEW … AS`` wrapper; return inner statement.

    Matches DDL shaped like ``postgres_metadata.fetch_views`` output (VIEW … AS newline body).
    """
    text = ddl.strip()
    m = _re_create_view_as_body.match(text)
    if not m:
        return None
    body = m.group(1).strip()
    if body.endswith(";"):
        body = body[:-1].strip()
    return body


def strip_sql_fence(block: str) -> str:
    """Remove optional outer ```sql … ``` fences."""
    s = block.strip()
    m = re.match(r"^```(?:sql)?\s*([\s\S]*?)```\s*$", s)
    if m:
        return m.group(1).strip()
    return s
