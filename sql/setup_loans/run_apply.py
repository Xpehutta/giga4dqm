#!/usr/bin/env python3
"""
Apply loans schema scripts using psql (local or Docker).

    uv run python sql/setup_loans/run_apply.py

Environment (via project `.env`):
    PG_DSN=postgresql://...                         (preferred — full URL), or
    PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

Options:
    LOANS_SEED_CUSTOMERS=500
    LOANS_SKIP_DATA=1
    LOANS_PG_DOCKER_HOST=host.docker.internal      (override when using Docker→host Postgres)

Docker is used only if `psql` is not on PATH. Postgres on localhost is reached as
host.docker.internal from the container on Docker Desktop for Mac.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _SCRIPT_DIR.parent.parent


def _load_pg() -> tuple[str | None, dict[str, str]]:
    """Returns (maybe_conn_uri or None for PG* fallback, env additions for subprocess)."""
    load_dotenv(_PROJECT_ROOT / ".env")
    dsn = (os.getenv("PG_DSN") or "").strip()
    if dsn:
        # psycopg / SQLAlchemy style postgresql+psycopg:// → libpq expects postgresql://
        if dsn.startswith("postgresql+psycopg://"):
            dsn = "postgresql://" + dsn.removeprefix("postgresql+psycopg://")
        return (dsn, {})

    user = os.getenv("PGUSER")
    db = os.getenv("PGDATABASE")
    if not user or not db:
        raise SystemExit("Need PG_DSN or PGUSER + PGDATABASE in .env")
    pw = os.getenv("PGPASSWORD") or ""
    host = os.getenv("PGHOST", "localhost")
    port = os.getenv("PGPORT", "5432")
    if pw:
        auth = f"{quote_plus(user)}:{quote_plus(pw)}@"
    else:
        auth = f"{quote_plus(user)}@"
    uri = f"postgresql://{auth}{host}:{port}/{quote_plus(db)}"
    return (uri, {})


def _docker_host(uri: str) -> str | None:
    """If URI points at localhost and we use Docker, rewrite host."""
    marker = "@"
    if marker not in uri:
        return None
    rest = uri.split(marker, 1)[1]
    netloc = rest.split("/", 1)[0]
    host_part = netloc.split(":")[0] if ":" in netloc else netloc
    if host_part in ("localhost", "127.0.0.1"):
        return os.getenv("LOANS_PG_DOCKER_HOST", "host.docker.internal")
    return None


def _rewrite_uri_host(uri: str, new_host: str) -> str:
    marker = "@"
    a, rest = uri.split(marker, 1)
    net_tail = rest.split("/", 1)
    netloc = net_tail[0]
    path_rest = "/" + net_tail[1] if len(net_tail) > 1 else ""
    if ":" in netloc:
        host_old, port = netloc.split(":", 1)
        new_net = f"{new_host}:{port}"
    else:
        new_net = new_host
    return a + marker + new_net + path_rest


def _run_sql(uri: str, sql: str, label: str) -> None:
    psql = shutil.which("psql")

    inner = sql.encode("utf-8")

    if psql:
        cmd = [psql, uri, "-v", "ON_ERROR_STOP=1", "-f", "-"]
        proc = subprocess.run(cmd, input=inner, capture_output=True, text=False)
        if proc.returncode != 0:
            sys.stderr.buffer.write(proc.stderr)
            sys.stdout.buffer.write(proc.stdout)
            raise SystemExit(f"{label} failed via local psql (exit {proc.returncode})")
        sys.stdout.buffer.write(proc.stdout)
        return

    alt = _docker_host(uri)
    docker_uri = _rewrite_uri_host(uri, alt) if alt else uri
    dock_cmd = [
        "docker",
        "run",
        "--rm",
        "-i",
        "-e",
        "PSQL_CONN",
        "postgres:16-alpine",
        "sh",
        "-eu",
        "-c",
        "apk add --no-cache postgresql-client >/dev/null && "
        "exec psql \"$PSQL_CONN\" -v ON_ERROR_STOP=1 -f -",
    ]
    proc = subprocess.run(
        dock_cmd,
        input=inner,
        env={**os.environ, "PSQL_CONN": docker_uri},
        capture_output=True,
        text=False,
    )
    if proc.returncode != 0:
        sys.stderr.buffer.write(proc.stderr)
        sys.stdout.buffer.write(proc.stdout)
        raise SystemExit(
            f"{label} failed inside Docker (exit {proc.returncode}). "
            "Ensure Docker Desktop is running and Postgres is reachable from the container.",
        )
    sys.stdout.buffer.write(proc.stdout)


def main() -> None:
    uri, _ = _load_pg()
    if uri is None:
        raise SystemExit("_load_pg returned empty URI")

    sql_files = [
        "02_schema_tables.sql",
        "03_functions_pmt.sql",
        "04_generate_banking_data.sql",
        "05_views.sql",
        "06_advanced_functions.sql",
        "07_datamart.sql",
        "08_bonus.sql",
    ]
    seed = os.getenv("LOANS_SEED_CUSTOMERS", "500")
    skip_data = os.getenv("LOANS_SKIP_DATA", "").lower() in ("1", "true", "yes")

    for name in sql_files:
        path = _SCRIPT_DIR / name
        if not path.is_file():
            raise SystemExit(f"Missing file: {path}")
        print(f"Applying {name} …", flush=True)
        _run_sql(uri, path.read_text(encoding="utf-8"), label=name)

    if skip_data:
        print("LOANS_SKIP_DATA set — skipping data generation.", flush=True)
        return

    print(f"Seeding {seed} customers …", flush=True)
    _run_sql(uri, f"SELECT loans.generate_banking_data({int(seed)});", label="seed")
    print("Refreshing loan_data_mart …", flush=True)
    _run_sql(uri, "CALL loans.refresh_loan_data_mart(CURRENT_DATE);", label="mart")
    print("Refreshing materialized view …", flush=True)
    _run_sql(uri, "REFRESH MATERIALIZED VIEW loans.mv_portfolio_summary;", label="mv")
    vpath = _SCRIPT_DIR / "99_verify.sql"
    if vpath.exists():
        print("Running verification SQL …", flush=True)
        _run_sql(uri, vpath.read_text(encoding="utf-8"), label="verify")
    print("Done.", flush=True)


if __name__ == "__main__":
    main()
