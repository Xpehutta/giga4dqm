# DB catalog agent (skill description)

## What it is

`ai-agent-tools/agents/db_catalog_agent.py` is a small **LangGraph** workflow that answers **natural-language questions** about a **single PostgreSQL schema** using only metadata that was loaded from the database in-process. The LLM is **GigaChat**; the reply is coerced to a **Pydantic** `CatalogAnswer` (JSON) via `PydanticOutputParser`, so you get both a human-readable `answer` and structured citation fields.

## What it is for

- Explaining what tables and views exist, column roles, and high-level purpose when descriptions exist in the catalog.
- Pointing to **routines (functions/procedures)** and their **signatures and DDL** (subject to size limits in the prompt context).
- Stating when something is **not** present in the exported catalog (empty lists, missing descriptions).

## What it is not

- A substitute for running queries against application data, performance tuning, or security review.
- A guarantee of full routine bodies in the model context: `ddl` strings are **truncated** per object when building the LLM context (see `answer_node` in the agent).
- A tool to extract **Python** source from the repo: use the separate `extract_function_code` script only for that, as in `tools.md`.

## How it works

1. **Fetch catalog** — The graph always runs `export_catalog_tool` first. That opens **psycopg** and calls `fetch_schema_catalog` in `ai-agent-tools/scripts/postgres_metadata.py` (the same core logic as the `export_db_catalog.py` CLI). It combines **pg_catalog** (including `pg_get_functiondef` for routines), built DDL for tables/views, and an **`information_schema`** tally.
2. **Build prompt** — `tools.md`, optional overrides in `prompts/db_catalog_system_prompt.md` and `db_catalog_user_prompt.md`, and a **JSON context** (truncated per object) are sent to GigaChat.
3. **Parse response** — The model is instructed to return a **single JSON object** without markdown fences, matching `CatalogAnswer`. If parsing fails, the raw text is kept as `answer` and structured lists are left empty.

## How to run

```bash
uv run python ai-agent-tools/agents/db_catalog_agent.py --schema <name> --question "..." --pretty
```

**Environment (typically project `.env`):** PostgreSQL `PG*` or `PG_DSN`; GigaChat `GIGACHAT_API_KEY` or `GIGACHAT_EMBEDDINGS_CREDENTIALS`. Optional: `GIGACHAT_API_URL`, `MODEL`, `GIGACHAT_TIMEOUT`, and related GigaChat flags as used in the script.

## Output shape

JSON with at least:

- `schema`, `question`, `summary` (table/view/procedure counts)
- `answer` — main string
- `structured` — `answer`, `cited_table_names`, `cited_routine_names`, `missing_in_catalog`

## Related files

| File | Role |
|------|------|
| `ai-agent-tools/tools.md` | Tool contracts and agent-facing guidance |
| `ai-agent-tools/scripts/postgres_metadata.py` | SQL metadata loading |
| `ai-agent-tools/scripts/export_db_catalog.py` | Standalone JSON export (same metadata core) |
| `ai-agent-tools/prompts/db_catalog_*.md` | Optional prompt overrides |

Use this file when an automated assistant needs a **one-page skill** summary for the DB catalog agent; use `tools.md` for **tool I/O and usage rules** in more detail.

---

# DB data subagent (skill description)

## What it is

`ai-agent-tools/agents/db_data_subagent.py` is a **LangGraph** workflow that answers questions using **actual query results**. It uses LangChain’s **`SQLDatabase`** over **SQLAlchemy** (`postgresql+psycopg`) for schema/table context and execution. **GigaChat** generates SQL and later summarizes the string returned by the database.

## What it is for

- Counts, aggregates, filters, and “what’s in this table” questions over **rows**, not only DDL.
- Exploratory questions when sample rows and column lists (from `SQLDatabase`’s table info) are enough to steer the model.

## What it is not

- Not a replacement for BI, heavy analytics, or audited production access control: generated SQL is filtered to **SELECT / WITH…SELECT** only, with a configurable **LIMIT** (`SQL_SUBAGENT_MAX_LIMIT`, default 500).
- Not the same as `db_catalog_agent`: the catalog agent does **not** run arbitrary `SELECT` on your behalf.

## How to run

```bash
uv run python ai-agent-tools/agents/db_data_subagent.py --schema <name> --question "..." --pretty
```

Same DB and GigaChat env vars as the catalog agent. Optional: `--max-table-info-chars`, `--no-views`, `--sample-rows`.

---

# DB lineage subagent (skill description)

## What it is

`ai-agent-tools/agents/db_lineage_subagent.py` is a small **LangGraph** workflow (**load DDL → LLM**) that analyzes **PostgreSQL views, materialized views, and routines** (`pg_catalog`) plus the list of **base tables**, then asks **GigaChat-Pro** (default `LINEAGE_MODEL`; not the generic `MODEL` unless overridden) for a lineage narrative and structured **`LineageAnswer`**.

## What it is for

- “What **reads** table X / column Y?” / “What sits **upstream** or **downstream** of Z?” from **DDL** and SQL text in definitions.
- High-level lineage when introspection metadata is incomplete for ad hoc SQL but routine/view bodies contain the joins and references.

## What it is not

- Full **data** profiling or row sampling (use **`db_data_subagent`**).
- Exhaustive lineage product quality: DDL may be truncated for context; unnamed dynamic SQL cannot be summarized.
- A guarantee against large schemas: prioritize objects whose DDL **matches keywords** extracted from your question (`--max-ddls-chars`).

## How to run

```bash
uv run python ai-agent-tools/agents/db_lineage_subagent.py --schema <schema> --question "…" --pretty
```

Same DB vars as others; lineage model defaults to **GigaChat-Pro**. In **Streamlit**, **Auto** may route here when `intent_route` returns **`lineage`**; use fixed **Lineage** mode for every message.

## Output shape

JSON with **`answer`**, **`structured`** (`upstream_objects`, `downstream_objects`, `cited_object_names`), **`summary`** counts, and **`model`**.

---

# DB lineage + data audit subagent (skill description)

## What it is

`ai-agent-tools/agents/db_lineage_data_audit_subagent.py` is a **LangGraph** pipeline: **lineage** (`db_lineage_subagent`) then **data** (`db_data_subagent`), with the second step fed a synthesized prompt from the lineage **`LineageAnswer`** (upstream/downstream lists + narrative).

## What it is for

- Tracing **where a mart/view column comes from** and then **running SELECTs** against **upstream** tables/views to catch NULLs, skew, or join issues.
- Questions that mix **pipeline / definition** debugging with **row-level validation** (“why is this mart wrong?”, “validate sources for this view”).

## What it is not

- A single cheap call: it runs **two** GigaChat-heavy paths (lineage + SQL agent).
- Not a substitute for formal DQ tools or statistical profiling at scale (`SQL_SUBAGENT_MAX_LIMIT` still applies).

## How to run

```bash
uv run python ai-agent-tools/agents/db_lineage_data_audit_subagent.py --schema <schema> --question "…" --pretty
```

**Streamlit:** **Audit** fixed mode or **Auto** when `intent_route` returns **`audit`**.
