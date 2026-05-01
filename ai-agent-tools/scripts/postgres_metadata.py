"""
PostgreSQL catalog metadata: tables, views, and routines (DDL) via pg_catalog
plus tallies from information_schema for cross-checking and standards-based discovery.

Rationale: full DDL for routines requires pg_get_functiondef (pg_proc). Base table/column
metadata also appears in information_schema; we use both where appropriate.
"""

from __future__ import annotations

import os
from typing import Any

import psycopg
from psycopg.rows import dict_row


def load_env_file(path: str) -> None:
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            os.environ.setdefault(key, value)


def build_connection_string(
    *,
    dsn: str | None = None,
    host: str | None = None,
    port: str | None = None,
    database: str | None = None,
    user: str | None = None,
    password: str | None = None,
) -> str:
    if dsn:
        return dsn
    if not database or not user:
        raise ValueError("Provide dsn or both database and user (or PG* env vars).")
    h = host or "localhost"
    p = port or "5432"
    password_part = f":{password}" if password else ""
    return f"postgresql://{user}{password_part}@{h}:{p}/{database}"


def build_connection_string_from_environ() -> str:
    return build_connection_string(
        dsn=os.getenv("PG_DSN"),
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        database=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
    )


def quote_ident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def information_schema_tally(conn: psycopg.Connection[Any], schema: str) -> dict[str, Any]:
    """Counts in information_schema for the given schema (supplements pg_catalog fetches)."""
    sql = """
        SELECT table_type, COUNT(*)::int AS n
        FROM information_schema.tables
        WHERE table_schema = %s
        GROUP BY table_type
        ORDER BY table_type
    """
    by_type: dict[str, int] = {}
    with conn.cursor() as cur:
        cur.execute(sql, (schema,))
        for table_type, n in cur.fetchall():
            by_type[table_type or ""] = n
    sql_r = """
        SELECT COUNT(*)::int
        FROM information_schema.routines
        WHERE specific_schema = %s
    """
    with conn.cursor() as cur:
        cur.execute(sql_r, (schema,))
        (routine_count,) = cur.fetchone() or (0,)
    return {
        "tables_by_type": by_type,
        "routine_count": routine_count,
    }


def table_columns(conn: psycopg.Connection[Any], schema: str, table: str) -> list[dict[str, Any]]:
    sql = """
        SELECT
            a.attname AS column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
            NOT a.attnotnull AS is_nullable,
            pg_get_expr(ad.adbin, ad.adrelid) AS default_expr,
            col_description(c.oid, a.attnum) AS description
        FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_catalog.pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
        WHERE n.nspname = %s
          AND c.relname = %s
          AND a.attnum > 0
          AND NOT a.attisdropped
        ORDER BY a.attnum
    """
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql, (schema, table))
        return list(cur.fetchall())


def table_constraints(conn: psycopg.Connection[Any], schema: str, table: str) -> list[str]:
    sql = """
        SELECT pg_get_constraintdef(con.oid, true) AS constraint_def
        FROM pg_catalog.pg_constraint con
        JOIN pg_catalog.pg_class c ON c.oid = con.conrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = %s
          AND c.relname = %s
        ORDER BY con.contype, con.conname
    """
    with conn.cursor() as cur:
        cur.execute(sql, (schema, table))
        return [row[0] for row in cur.fetchall()]


def table_indexes(conn: psycopg.Connection[Any], schema: str, table: str) -> list[str]:
    sql = """
        SELECT indexdef
        FROM pg_catalog.pg_indexes
        WHERE schemaname = %s
          AND tablename = %s
        ORDER BY indexname
    """
    with conn.cursor() as cur:
        cur.execute(sql, (schema, table))
        return [row[0] + ";" for row in cur.fetchall()]


def build_table_ddl(
    conn: psycopg.Connection[Any], schema: str, table: str, columns: list[dict[str, Any]]
) -> str:
    lines: list[str] = []
    for col in columns:
        line = f"    {quote_ident(col['column_name'])} {col['data_type']}"
        if col["default_expr"]:
            line += f" DEFAULT {col['default_expr']}"
        if not col["is_nullable"]:
            line += " NOT NULL"
        lines.append(line)

    for constraint in table_constraints(conn, schema, table):
        lines.append(f"    {constraint}")

    table_name = f"{quote_ident(schema)}.{quote_ident(table)}"
    ddl = [f"CREATE TABLE {table_name} (", ",\n".join(lines), ");"]
    ddl.extend(table_indexes(conn, schema, table))
    return "\n".join(ddl)


def list_base_table_names(conn: psycopg.Connection[Any], schema: str) -> list[str]:
    """Plain base table names (`relkind` = heap); cheap list for lineage or discovery."""
    sql = """
        SELECT c.relname::text
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = %s AND c.relkind = 'r'
        ORDER BY c.relname
    """
    with conn.cursor() as cur:
        cur.execute(sql, (schema,))
        return [row[0] for row in cur.fetchall()]


def fetch_tables(conn: psycopg.Connection[Any], schema: str) -> list[dict[str, Any]]:
    sql = """
        SELECT
            c.relname AS table_name,
            obj_description(c.oid, 'pg_class') AS description
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
          AND n.nspname = %s
        ORDER BY c.relname
    """
    tables: list[dict[str, Any]] = []
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql, (schema,))
        for row in cur.fetchall():
            columns = table_columns(conn, schema, row["table_name"])
            tables.append(
                {
                    "schema": schema,
                    "name": row["table_name"],
                    "description": row["description"],
                    "columns": columns,
                    "ddl": build_table_ddl(conn, schema, row["table_name"], columns),
                }
            )
    return tables


def fetch_views(conn: psycopg.Connection[Any], schema: str) -> list[dict[str, Any]]:
    sql = """
        SELECT
            c.relname AS view_name,
            obj_description(c.oid, 'pg_class') AS description,
            pg_get_viewdef(c.oid, true) AS view_def
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('v', 'm')
          AND n.nspname = %s
        ORDER BY c.relname
    """
    views: list[dict[str, Any]] = []
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql, (schema,))
        for row in cur.fetchall():
            view_name = f"{quote_ident(schema)}.{quote_ident(row['view_name'])}"
            ddl = f"CREATE OR REPLACE VIEW {view_name} AS\n{row['view_def']};"
            views.append(
                {
                    "schema": schema,
                    "name": row["view_name"],
                    "description": row["description"],
                    "ddl": ddl,
                }
            )
    return views


def fetch_procedures(conn: psycopg.Connection[Any], schema: str) -> list[dict[str, Any]]:
    sql = """
        SELECT
            p.oid,
            p.proname AS routine_name,
            p.prokind,
            obj_description(p.oid, 'pg_proc') AS description,
            pg_get_function_identity_arguments(p.oid) AS identity_args,
            pg_get_functiondef(p.oid) AS routine_ddl
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = %s
          AND p.prokind IN ('f', 'p')
        ORDER BY p.proname, identity_args
    """
    routines: list[dict[str, Any]] = []
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(sql, (schema,))
        for row in cur.fetchall():
            routines.append(
                {
                    "schema": schema,
                    "name": row["routine_name"],
                    "kind": "procedure" if row["prokind"] == "p" else "function",
                    "signature": f"{row['routine_name']}({row['identity_args']})",
                    "description": row["description"],
                    "ddl": row["routine_ddl"].strip(),
                }
            )
    return routines


def list_non_system_schemas(conn: psycopg.Connection[Any]) -> list[str]:
    """
    List PostgreSQL namespace names, excluding system schemas (pg_*, information_schema, …).
    Includes `public` if present. Safe for `search_path` / application schema pickers.
    """
    sql = """
        SELECT nspname::text
        FROM pg_namespace
        WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
          AND nspname !~ '^pg_'
        ORDER BY nspname
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        return [row[0] for row in cur.fetchall()]


def list_schemas_from_environ() -> list[str]:
    """Open a connection with PG* / PG_DSN and return `list_non_system_schemas`."""
    uri = build_connection_string_from_environ()
    with psycopg.connect(uri) as conn:
        return list_non_system_schemas(conn)


def fetch_schema_catalog(
    conn: psycopg.Connection[Any],
    schema: str,
    sections: set[str],
) -> dict[str, Any]:
    result: dict[str, Any] = {"schema": schema}
    if "tables" in sections:
        result["tables"] = fetch_tables(conn, schema)
    if "views" in sections:
        result["views"] = fetch_views(conn, schema)
    if "procedures" in sections:
        result["procedures"] = fetch_procedures(conn, schema)
    result["information_schema"] = information_schema_tally(conn, schema)
    return result
