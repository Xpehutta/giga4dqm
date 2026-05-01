# Script_DB_pg

PostgreSQL-adapted SQL scripts derived from `Script_DB`.

## Purpose

- Contains scripts adjusted to run in local PostgreSQL.
- Used for creating objects/functions and running local data generation/tests.

## Important

- This folder is an adapted derivative, not the upstream source of truth.
- Some original Greenplum behaviors are approximated for PostgreSQL compatibility.
- For original intent/logic, cross-check with `../Script_DB`.

## Editing policy

- Put PostgreSQL compatibility fixes and local execution changes here.
- Keep changes documented and reproducible.
- Maintain schema metadata comments (`COMMENT ON TABLE/COLUMN/TYPE`) centrally in `bootstrap_objects.sql` to avoid drift across scripts.

## Typical usage

- Bootstrap objects from `bootstrap_objects.sql`.
- Apply adapted function scripts.
- Optionally run `run_*.sql` for full scenarios (can be heavy).

See `../SETUP_FROM_SCRATCH.md` for detailed ordered steps.

