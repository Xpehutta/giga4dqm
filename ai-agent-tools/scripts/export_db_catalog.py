#!/usr/bin/env python3
"""
Export PostgreSQL metadata and DDL for tables, views, and routines.

Environment variables (used when CLI args are not provided):
- PGHOST
- PGPORT
- PGDATABASE
- PGUSER
- PGPASSWORD

By default, values are loaded from `.env` in the project root.
"""

from __future__ import annotations

import argparse
import json
import os
from typing import Any

import psycopg
from postgres_metadata import (
    build_connection_string,
    fetch_schema_catalog,
    load_env_file,
)


def parse_args() -> argparse.Namespace:
    default_env_file = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", ".env")
    )
    parser = argparse.ArgumentParser(
        description="Export descriptions and DDLs for tables, views, and procedures/functions."
    )
    parser.add_argument(
        "--env-file",
        default=default_env_file,
        help="Path to .env file with PG* variables.",
    )
    parser.add_argument("--dsn", help="Full Postgres DSN. If set, overrides host/user/etc.")
    parser.add_argument("--host")
    parser.add_argument("--port")
    parser.add_argument("--database")
    parser.add_argument("--user")
    parser.add_argument("--password")
    parser.add_argument("--schema", default="public", help="Schema to inspect.")
    parser.add_argument(
        "--sections",
        nargs="+",
        choices=["tables", "views", "procedures", "all"],
        default=["all"],
        help="Which sections to include.",
    )
    parser.add_argument("--output", help="Write JSON output to file path.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output.")
    return parser.parse_args()


def build_connection_string_from_args(args: argparse.Namespace) -> str:
    if args.dsn:
        return args.dsn
    if not args.database or not args.user:
        raise ValueError(
            "Provide --dsn or both --database and --user (or PG* env vars).",
        )
    return build_connection_string(
        host=args.host,
        port=args.port,
        database=args.database,
        user=args.user,
        password=args.password,
    )


def main() -> None:
    args = parse_args()
    load_env_file(args.env_file)

    if not args.host:
        args.host = os.getenv("PGHOST", "localhost")
    if not args.port:
        args.port = os.getenv("PGPORT", "5432")
    if not args.database:
        args.database = os.getenv("PGDATABASE")
    if not args.user:
        args.user = os.getenv("PGUSER")
    if not args.password:
        args.password = os.getenv("PGPASSWORD")

    conn_string = build_connection_string_from_args(args)
    sections = set(args.sections)
    if "all" in sections:
        sections = {"tables", "views", "procedures"}

    with psycopg.connect(conn_string) as conn:
        result: dict[str, Any] = fetch_schema_catalog(conn, args.schema, sections)

    indent = 2 if args.pretty else None
    payload = json.dumps(result, ensure_ascii=True, indent=indent)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(payload + "\n")
    else:
        print(payload)


if __name__ == "__main__":
    main()
