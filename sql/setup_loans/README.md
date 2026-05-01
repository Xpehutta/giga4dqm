# PostgreSQL `loans` banking schema — implementation scripts

Companion to `setup_loan_db.md` with **fixes and the missing generator**.

## Errata vs. the original markdown

| Item | Problem | Fix applied here |
|------|---------|------------------|
| Step 4 | `generate_banking_data` referenced but **not inlined** | Full `FUNCTION` definition in `04_generate_banking_data.sql` |
| `default_probability` | `LEFT JOIN payments` aggregated with `GROUP BY customer_id` could mis-count joins | Ratio = loans with **no payments** / total loans (`NOT EXISTS`), plus score/delinquency mix |
| `refresh_loan_data_mart` | Re-run in same transaction could Error on **existing temp tables** | `DROP TABLE IF EXISTS` temp objects at procedure start (`07_datamart.sql`) |
| Views | `ORDER BY` in views (`payment_behaviour`, `cohort_analysis`) is brittle / meaningless for some clients | **`ORDER BY` removed** (`05_views.sql`); sort at query time instead |

Everything else follows the Markdown structure (tables → PMT → data gen → views → advanced functions → data mart → bonus).

## Prerequisites

PostgreSQL **13+**, DB user may `CREATE` in target database.

## Apply (recommended)

From the repo root, with `PG_DSN` **or** `PGHOST`/`PGPORT`/`PGDATABASE`/`PGUSER`/`PGPASSWORD` in `.env`:

```bash
uv run python sql/setup_loans/run_apply.py
```

Uses **local `psql`** when it is on `PATH`; otherwise **`docker run postgres:16-alpine`** (installs `postgresql-client` once per step) and connects to `host.docker.internal` when `.env` uses `localhost`.

If a previous run stopped halfway, reset the schema before re-applying:

```bash
# via psql / same connection as .env
psql "$PG_DSN" -c "DROP SCHEMA IF EXISTS loans CASCADE;"
uv run python sql/setup_loans/run_apply.py
```

## Apply manually (individual files)

Using `psql`:

```bash
export PGDATABASE=your_db
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/02_schema_tables.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/03_functions_pmt.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/04_generate_banking_data.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/05_views.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/06_advanced_functions.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/07_datamart.sql
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/08_bonus.sql
```

**Skip** bonus material: omit `08_bonus.sql` (Steps 8 & 10 `REFRESH` on MV then need manual MV creation first).

Synthetic data & verification:

```bash
psql -c "SELECT loans.generate_banking_data(500);"
psql -c "CALL loans.refresh_loan_data_mart(CURRENT_DATE);"
psql -v ON_ERROR_STOP=1 -f sql/setup_loans/99_verify.sql
```

## Skipping unsuitable stages

| Goal | Skip |
|------|------|
| Schema only (no data) | `04`–`99` after `03` or stop after `02` |
| No data mart / ETL | Skip `07` and `99` mart checks |
| No star schema / MV | Skip `08` |
| No synthetic load | Skip `generate_banking_data` call |
