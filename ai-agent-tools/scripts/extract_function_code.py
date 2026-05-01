#!/usr/bin/env python3
"""
Print the source code of a function or method from a Python file.

Resolves a dotted name: top-level `func_name` or `ClassName.method_name`.
If multiple definitions share the name, the first match in source order is returned.
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract source text of a function or method from a Python file."
    )
    parser.add_argument("file", help="Path to a .py file.")
    parser.add_argument(
        "name",
        help="Function name, or ClassName.method for a method.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON with keys file, name, line_start, line_end, source.",
    )
    return parser.parse_args()


def _find_routine(
    tree: ast.Module, parts: list[str]
) -> ast.AsyncFunctionDef | ast.FunctionDef | None:
    if len(parts) == 1:
        want = parts[0]
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == want:
                return node
        return None

    if len(parts) != 2:
        return None
    cls_name, method_name = parts
    for node in tree.body:
        if not isinstance(node, ast.ClassDef) or node.name != cls_name:
            continue
        for item in node.body:
            if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)) and item.name == method_name:
                return item
    return None


def extract(source: str, name: str) -> dict[str, Any] | None:
    parts = name.split(".")
    if not parts or not all(parts) or any(" " in p for p in parts):
        return None
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return None
    if not isinstance(tree, ast.Module):
        return None
    node = _find_routine(tree, parts)
    if node is None:
        return None
    seg = ast.get_source_segment(source, node)
    if seg is not None:
        text = seg
    else:
        lines = source.splitlines(keepends=True)
        li = (node.lineno or 1) - 1
        hi = (getattr(node, "end_lineno", None) or node.lineno or 1) - 1
        text = "".join(lines[li : hi + 1])
    line_start = node.lineno or 1
    line_end = getattr(node, "end_lineno", None) or line_start
    return {
        "line_start": line_start,
        "line_end": line_end,
        "source": text,
    }


def main() -> None:
    args = parse_args()
    try:
        with open(args.file, "r", encoding="utf-8") as f:
            source = f.read()
    except OSError as e:
        print(f"error: cannot read file: {e}", file=sys.stderr)
        sys.exit(2)
    result = extract(source, args.name)
    if result is None:
        print(
            f"error: no function or method {args.name!r} found in {args.file!r}",
            file=sys.stderr,
        )
        sys.exit(1)
    if args.json:
        out = {
            "file": args.file,
            "name": args.name,
            "line_start": result["line_start"],
            "line_end": result["line_end"],
            "source": result["source"],
        }
        print(json.dumps(out, ensure_ascii=True, indent=2))
    else:
        sys.stdout.write(result["source"])
        if not result["source"].endswith("\n"):
            sys.stdout.write("\n")


if __name__ == "__main__":
    main()
