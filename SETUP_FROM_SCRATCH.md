# PostgreSQL Setup Runbook (From Scratch)

This document explains how to recreate the current local setup from scratch:
- PostgreSQL in Docker
- Python/`uv` environment
- adapted SQL objects/functions
- test data generation
- validation notebooks

It is intended for any teammate who needs to reproduce the same environment.

## 1) Prerequisites

- Docker installed and running
- `uv` installed (`uv --version`)
- Project root: `Giga4DQM`

## 2) Create Python environment

From project root:

```bash
uv venv --seed .venv
source .venv/bin/activate
uv init --bare
uv add --dev pytest ruff jupyter 'psycopg[binary]'
uv sync
```

## 2.1) Configure local `.env`

Create `.env` in project root (you can copy from `.env.example`) and set:

```bash
PGHOST=localhost
PGPORT=5433
PGDATABASE=giga4dqm
PGUSER=giga4dqm
PGPASSWORD=giga4dqm
```

Notebooks and AI-agent DB tools read connection values from this file.

## 3) Start PostgreSQL

The project uses Docker Compose (`docker-compose.yml`) with:
- DB: `giga4dqm`
- User: `giga4dqm`
- Password: `giga4dqm`
- Host port: `5433`

Start DB:

```bash
docker compose up -d
```

Quick check:

```bash
docker compose ps
```

## 4) Understand source scripts

Original scripts are in:
- `Script_DB`

They are Greenplum-oriented and include syntax not supported by PostgreSQL (`DISTRIBUTED BY`, Greenplum partition/storage clauses, etc.).

PostgreSQL-adapted scripts are in:
- `Script_DB_pg`

## 5) Create schema + base objects

The base schema and table/type objects are created from:
- `Script_DB_pg/bootstrap_objects.sql`

This script now also applies schema metadata (`COMMENT ON TABLE`, `COMMENT ON COLUMN`, `COMMENT ON TYPE`) so object descriptions are available in PostgreSQL clients.

Run:

```bash
docker exec -i giga4dqm-postgres psql -U giga4dqm -d giga4dqm -v ON_ERROR_STOP=1 < "Script_DB_pg/bootstrap_objects.sql"
```

## 6) Create functions/procedures

Apply adapted SQL files from `Script_DB_pg` (excluding `run_*.sql` if you do not want heavy runs yet).

`fn_create_obj_test1.sql` creates objects via function logic, while schema metadata comments are maintained centrally in `bootstrap_objects.sql` to avoid drift.

Recommended pattern:

```bash
for f in Script_DB_pg/*.sql; do
  b="$(basename "$f")"
  case "$b" in
    bootstrap_objects.sql|run_*.sql) continue ;;
  esac
  docker exec -i giga4dqm-postgres psql -U giga4dqm -d giga4dqm -v ON_ERROR_STOP=1 < "$f"
done
```

## 7) Seed reference tables

Static reference inserts (from original object script) are applied with:
- `Script_DB_pg/seed_reference_tables.sql`

Run:

```bash
docker exec -i giga4dqm-postgres psql -U giga4dqm -d giga4dqm -v ON_ERROR_STOP=1 < "Script_DB_pg/seed_reference_tables.sql"
```

This populates:
- `etl_task_param`
- `d_settings`
- `t_src_system_type`

## 8) Generate data (controlled run)

Used generation calls:

```sql
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test1(3000,1000000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test2(100000,200,100);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test3(100000,200,100);
```

Run with:

```bash
docker exec -i giga4dqm-postgres psql -U giga4dqm -d giga4dqm <<'SQL'
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test1(3000,1000000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test2(100000,200,100);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test3(100000,200,100);
SQL
```

## 9) Move suffixed run tables into base tables

Some generators write to suffixed tables (`*_123456`).  
Copy from suffixed tables into base tables if needed for downstream checks.

Example:

```sql
TRUNCATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred;
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred
SELECT * FROM s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_1497470240;
```

Also done for:
- `d_agr_cred_coa`
- `d_agr_cred_coa_period_prep_bal`
- `d_agr_cred_optn`
- `d_tech_tbl_coa_bal_h`
- `t_coa`
- `t_je_line`

## 10) Optional cleanup of suffixed tables

Drop all `_numbers` tables:

```sql
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 's_grnplm_as_t_didsd_nnn_db_tmd'
      AND tablename ~ '.*_[0-9]+$'
  LOOP
    EXECUTE format('DROP TABLE IF EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.%I', r.tablename);
  END LOOP;
END $$;
```

## 11) Validation notebooks

Available notebooks in `notebooks/`:

- `postgres_connection_check.ipynb`  
  Basic DB connection test.

- `postgres_setup_validation.ipynb`  
  Schema/tables/functions sanity checks.

- `postgres_table_counts.ipynb`  
  Row counts for all tables and key tables.

- `postgres_functions_check.ipynb`  
  Function inventory, signatures, and definitions.

- `postgres_views_check.ipynb`  
  View inventory and definition/count probes.

Run Jupyter:

```bash
source .venv/bin/activate
uv run jupyter notebook
```

Optional metadata check in `psql`:

```sql
\d+ s_grnplm_as_t_didsd_nnn_db_tmd.t_coa
\dT+ s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params
```

## 12) Important notes

- Original `Script_DB` is Greenplum-oriented; use adapted `Script_DB_pg` for PostgreSQL.
- Some heavy calc functions may run long on large data volumes.
- In adapted mode, some original workflows were supplemented with direct seed/fill SQL for practical local validation.
- If you need a strict clean start, truncate/drop objects and rerun this document from step 3.

