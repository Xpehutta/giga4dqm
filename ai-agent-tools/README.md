# ai-agent-tools

Workspace for AI-agent–related tooling in this project.

## Structure

- `scripts/` — utilities and shared building blocks
  - `export_db_catalog.py` — CLI: dump catalog JSON to stdout or a file
  - `postgres_metadata.py` — in-process PostgreSQL metadata (`pg_catalog`, `pg_get_functiondef`, `information_schema` tallies); shared with the CLI and the agent
  - `sql_doc_extract.py` — extract base SQL from repo line slices or ``CREATE VIEW … AS`` wrappers
- `agents/` — runnable agent entrypoints
  - `db_catalog_agent.py` — metadata / DDL Q&A (`postgres_metadata`)
  - `db_data_subagent.py` — **data** Q&A via LangChain `SQLDatabase` + read-only `SELECT`
  - `db_lineage_subagent.py` — **lineage** from view/routine DDL + structured answer (`LineageAnswer`)
  - `db_lineage_data_audit_subagent.py` — **lineage** then **source data checks** (same stack as lineage + data)
  - `db_investigation_subagent.py` — **lineage** for a suspicious column/value, then **bundle of diagnostic SELECTs**
  - `sql_definition_extract_subagent.py` — CLI: **base SQL** from repo markdown lines or ``pg_get_viewdef`` (no LLM)
- `configs/` — example or exported catalog JSON for workflows
- `prompts/` — optional overrides for the DB catalog agent
- `tools.md` — tool contracts and agent-facing I/O
- `skills.md` — short skill summaries (catalog + data + lineage agents)

## Conventions

- Keep scripts idempotent when possible.
- Document required environment variables at the top of each script.
- Prefer small, composable utilities over large monolithic scripts.

## Environment

From the project root, copy `.env.example` to `.env` and set:

- **PostgreSQL** — `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, or a single `PG_DSN` if you prefer.
- **GigaChat (for both DB agents)** — `GIGACHAT_API_KEY` or `GIGACHAT_EMBEDDINGS_CREDENTIALS`. Optional: `GIGACHAT_API_URL`, `MODEL`, `GIGACHAT_TIMEOUT`, etc.
  - **`GIGACHAT_CONNECT_TIMEOUT`** (optional) — separate timeout in seconds for **TCP + TLS handshake** (OAuth token + API). Use if you see **`httpx.ConnectTimeout`** / OpenSSL handshake timeouts on slow VPNs while keeping `GIGACHAT_TIMEOUT` for read/response. Patched via `scripts/apply_gigachat_http_timeouts.py` (applied automatically by agents).
  - **`GIGACHAT_INTENT_TIMEOUT`** (optional) — override for **`intent_route.py`** only; defaults to **`GIGACHAT_TIMEOUT`** or **60** seconds.

- **Langfuse Cloud (EU)** — optional observability when code uses the Langfuse Python SDK (`langfuse` is in dev dependencies). Host: [https://cloud.langfuse.com](https://cloud.langfuse.com).
  - **This workspace:** project **giga4dqm** (org **Sber**, **EU**). Create **API keys** under that project in the Langfuse UI; ingestion is scoped to the project tied to those keys.
  - **`.env`:** `LANGFUSE_BASE_URL=https://cloud.langfuse.com`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`. Optional: `LANGFUSE_TRACING_ENVIRONMENT`, `LANGFUSE_SAMPLE_RATE` ([SDK environment variables](https://langfuse.com/docs/observability/sdk/python)).
  - **Tracing:** agent CLIs wrap each run in an **agent** observation; each GigaChat call is a **generation** (e.g. `db_catalog.answer`, `db_data_subagent.gen_sql`, `intent_route.classify`). Set `LANGFUSE_TRACING_ENABLED=false` to turn off exports.
  - **Reference metadata** (ids match the Langfuse UI; not secrets — do not commit keys):

```json
{
  "project": { "name": "giga4dqm", "id": "cmomjvte606l2ad07fmzp7odt" },
  "org": { "name": "Sber", "id": "cmomjv4ut00isad088ab9sobv" },
  "cloudRegion": "EU"
}
```

Self-hosted Langfuse uses a different base URL; see `docker-compose.langfuse.yml` in the repo root.

`export_db_catalog.py` only needs database variables. **`db_catalog_agent`**, **`db_data_subagent`**, **`db_lineage_subagent`**, **`db_lineage_data_audit_subagent`**, and **`db_investigation_subagent`** need **DB + GigaChat**.

The lineage agent uses **GigaChat-Pro** by default (`LINEAGE_MODEL`, default `GigaChat-Pro`), independent of `MODEL`.

Optional for the data subagent: `SQL_SUBAGENT_MAX_LIMIT` (default `500`) caps appended `LIMIT` on generated SQL.

## Catalog export (CLI)

Uses the same `postgres_metadata.fetch_schema_catalog` logic as the agent. JSON includes `schema`, `tables`, `views`, `procedures`, and an `information_schema` summary.

```bash
uv run python ai-agent-tools/scripts/export_db_catalog.py \
  --schema s_grnplm_as_t_didsd_nnn_db_tmd \
  --pretty --output ai-agent-tools/configs/db_catalog.json
```

## DB catalog agent

`agents/db_catalog_agent.py` is a **LangGraph** app that always loads the catalog **in-process** (no subprocess): `export_catalog_tool` → **psycopg** → `postgres_metadata`. The model (**GigaChat**) returns JSON shaped by `PydanticOutputParser` (`CatalogAnswer`).

**Prompts** (optional; defaults exist in code):

- `prompts/db_catalog_system_prompt.md`
- `prompts/db_catalog_user_prompt.md`

**Also loaded:** `tools.md` (and see `skills.md` for a narrative overview).

**Output JSON** includes `schema`, `question`, `summary` (counts), `answer` (main text), and `structured` (`cited_table_names`, `cited_routine_names`, `missing_in_catalog`, and the same `answer` for compatibility).

```bash
uv run python ai-agent-tools/agents/db_catalog_agent.py \
  --schema s_grnplm_as_t_didsd_nnn_db_tmd \
  --question "What does t_je_line table store and which columns are most important?" \
  --pretty
```

## DB data subagent (row-level SQL)

`agents/db_data_subagent.py` answers questions about **stored data** using **`langchain_community.utilities.SQLDatabase`** (SQLAlchemy `postgresql+psycopg://` to the same DB as `PG*` / `PG_DSN`). It builds table context from `SQLDatabase.get_context()`, asks GigaChat for a **single read-only** `SELECT` (or `WITH … SELECT`), validates it, runs it via `SQLDatabase.run`, then asks GigaChat to explain the result. This is **not** wired into `db_catalog_agent` by default; run it as a separate program when you need queries, not only catalog metadata.

```bash
uv run python ai-agent-tools/agents/db_data_subagent.py \
  --schema s_grnplm_as_t_didsd_nnn_db_tmd \
  --question "How many rows are in t_je_line?" \
  --pretty
```

A smoke notebook is at `notebooks/db_data_subagent_check.ipynb` (same repo).

## DB lineage subagent

`agents/db_lineage_subagent.py` answers **upstream / downstream lineage** questions about a named table or column by loading **plain base table names** plus **`pg_get_viewdef`** DDL for views/materialized views and **`pg_get_functiondef`** DDL for routines, then prompting **GigaChat-Pro**. It infers lineage from definitions only (no `SELECT` on row data). Long schemas rank objects by overlap with keywords from your question before fitting the DDL blob under `--max-ddls-chars`.

```bash
uv run python ai-agent-tools/agents/db_lineage_subagent.py \
  --schema s_grnplm_as_t_didsd_nnn_db_tmd \
  --question "Where does column amount in v_report flow from?" \
  --pretty
```

Optional: `LINEAGE_MODEL` overrides the default **`GigaChat-Pro`** model for lineage only.

The Streamlit app’s **Auto** mode calls **`intent_route.route_db_question`**; when it returns **`lineage`** or **`audit`**, the corresponding subagent runs automatically. **`audit`** chains **`db_lineage_subagent`**-style DDL analysis with **`db_data_subagent`**-style probes on upstream sources.

## DB lineage + data audit subagent

`agents/db_lineage_data_audit_subagent.py` runs **lineage first** (`db_lineage_subagent`), then builds a scoped question for **`db_data_subagent`** that includes structured upstream/downstream lists and asks the SQL agent to prioritize checks on sources relevant to mart/view debugging.

```bash
uv run python ai-agent-tools/agents/db_lineage_data_audit_subagent.py \
  --schema s_grnplm_as_t_didsd_nnn_db_tmd \
  --question "Why might v_fact_loan disagree with staging? Trace sources and spot bad nulls." \
  --pretty
```

Uses the same lineage and data env vars as those agents. **`intent_route`** can return **`audit`** when the classifier detects pipeline validation / error-hunting alongside lineage (**Streamlit Auto** invokes it without a separate click).

## Column investigation subagent

`agents/db_investigation_subagent.py`: **lineage** from DDL for the column/table implied by the question, then a **bundle of read-only investigative SELECTs** (purpose + SQL each; **not executed**). For questions that include pasted SQL and suspicion about wrong values; **`intent_route`** may return **`investigate`**.

```bash
uv run python ai-agent-tools/agents/db_investigation_subagent.py \
  --schema loans \
  --question "SELECT risk_category FROM loans.customer_credit_risk WHERE customer_id = 1; possible error — investigate" \
  --pretty
```

Optional env: **`INVESTIGATION_MAX_QUERIES`** (default `12`), **`SQL_SUBAGENT_MAX_LIMIT`** (LIMIT cap in prompts).

## SQL definition extract subagent

`agents/sql_definition_extract_subagent.py` prints deterministic JSON with **`base_sql`**:

- **Repo slice** — `--repo-file PATH_UNDER_REPO --lines START END` (inclusive 1-based lines), e.g. the inner ``SELECT … CASE … AS risk_category`` fragment in ``setup_loan_db.md`` (around lines 229–241).
- **Live DB view** — `--schema SCHEMA --view VIEW_NAME`: inner query from PostgreSQL (`pg_get_viewdef`), stripping the artificial ``CREATE VIEW … AS`` wrapper used by ``postgres_metadata``.

Uses helpers in ``scripts/sql_doc_extract.py``. **No GigaChat.**

```bash
uv run python ai-agent-tools/agents/sql_definition_extract_subagent.py \
  --repo-file setup_loan_db.md --lines 229 241 --pretty

uv run python ai-agent-tools/agents/sql_definition_extract_subagent.py \
  --schema loans --view customer_credit_risk --pretty
```

## Streamlit chat UI

From the **repository root**, with `.env` configured:

```bash
uv run streamlit run streamlit_app.py
```

This opens a browser UI to set a schema and chat (messages are kept until you clear or reload). **Schema** is discovered from the database (non-system namespaces); non-`public` names are listed first, and the app does **not** default to `public`—if only `public` exists or you need another name, use the override or manual fields. Use **Auto** to classify each question with `agents/intent_route.py` (short GigaChat call) and run the **catalog**, **data**, **lineage**, **audit**, **investigate**, or **both** (catalog+data) path. **Catalog** / **Data** / **Lineage** / **Audit** / **Investigate** pin a single backend. The app runs the same agent scripts as the CLI in a subprocess.

**Logging:** set `LOG_LEVEL` in the environment or `.env` (`INFO` default; use `DEBUG` for per-node detail). Logs go to stderr with names like `giga4dqm.streamlit`, `giga4dqm.agents.catalog`, `giga4dqm.agents.intent`, etc. (`agents/agent_logging.py`).

## See also

| Doc | Purpose |
|-----|--------|
| `tools.md` | Tool inputs, outputs, and usage rules |
| `skills.md` | Skill summaries for catalog, data, lineage, and audit agents |
