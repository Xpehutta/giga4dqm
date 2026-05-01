# Agent Tools

This document describes tools available to agents in `ai-agent-tools`.

## export_catalog_tool

- **Source**: `ai-agent-tools/agents/db_catalog_agent.py` (in-process) and `ai-agent-tools/scripts/export_db_catalog.py` (CLI). Shared logic: `ai-agent-tools/scripts/postgres_metadata.py` (uses `pg_catalog` for DDL, `pg_get_functiondef` for routines, plus `information_schema` for table-type / routine counts).
- **Purpose**: Load PostgreSQL schema metadata and DDL as JSON.
- **Input**:
  - `schema` (string): schema name to inspect.
- **Output**:
  - JSON object with keys:
    - `schema`
    - `tables` (table descriptions, columns, DDL)
    - `views` (view definitions and DDL)
    - `procedures` (signatures, descriptions, full routine DDL)
    - `information_schema` (tallies: `tables_by_type`, `routine_count` from standard views)

`db_catalog_agent` prints an additional `structured` object (Pydantic fields: `answer`, `cited_table_names`, `cited_routine_names`, `missing_in_catalog`) when the model returns valid JSON; the main `answer` string is the human-readable text.

## extract_function_code

- **Source**: `ai-agent-tools/scripts/extract_function_code.py`
- **Purpose**: Return the full source text of a Python function or class method from a file (for grounding answers in actual code, without reading the whole module).
- **Input**:
  - `file` (positional path): path to a `.py` file.
  - `name` (positional string): top-level function name, or `ClassName.method_name` for a method.
- **Output**:
  - Default: the function’s source on stdout, with a trailing newline.
  - With `--json`: JSON with keys `file`, `name`, `line_start`, `line_end`, `source`.

## db_data_subagent (row-level queries)

- **Source**: `ai-agent-tools/agents/db_data_subagent.py`
- **Mechanism**: `langchain_community.utilities.SQLDatabase` (SQLAlchemy + PostgreSQL). GigaChat proposes read-only SQL; execution and result summarization are separate steps.
- **Input**: CLI `--schema`, `--question`; environment `PG*` / `PG_DSN` and GigaChat credentials.
- **Output**: JSON with `sql`, `result_preview` (truncated), `answer`, optional `error`.

Use for **data** questions; use `export_catalog_tool` / `db_catalog_agent` for **metadata and routine DDL** only.

## db_lineage_subagent

- **Source**: `ai-agent-tools/agents/db_lineage_subagent.py`
- **Purpose**: Infer **upstream** and **downstream** lineage for a user-named table/column using **DDL only** (`pg_get_viewdef` + `pg_get_functiondef`), not row-level SELECT.
- **Input**: `--schema`, `--question`, optional `--max-ddls-chars` (default `100000`); env `PG*` / `PG_DSN` and GigaChat credentials.
- **Output**: JSON with `answer`, `summary` (`base_tables`, `views`, `routines`), `structured` (`upstream_objects`, `downstream_objects`, `cited_object_names`, `missing_in_context`), `model` (**GigaChat-Pro** by default; override via `LINEAGE_MODEL`).

Use when the question is about **impact**, **dependencies**, **provenance**, or **where column values come from**, expressed over **definitions** rather than querying stored rows (use **db_data_subagent** for counts/samples).

## db_lineage_data_audit_subagent

- **Source**: `ai-agent-tools/agents/db_lineage_data_audit_subagent.py`
- **Purpose**: End-to-end **pipeline debugging** — first **lineage** from view/routine DDL (same as `db_lineage_subagent`), then **read-only SELECT** checks on **upstream** objects (via `db_data_subagent`) guided by structured `upstream_objects` / `downstream_objects`, to spot data anomalies that could explain mart/view errors.
- **Input**: `--schema`, `--question`; optional `--max-ddls-chars`, `--max-table-info-chars`, `--sample-rows`, `--no-views`; env `PG*` / `PG_DSN` and GigaChat credentials (**two** heavy steps: lineage model + default `MODEL` for SQL).
- **Output**: JSON with `combined_answer`, nested `lineage` (matches lineage agent shape), `data_audit` (`answer`, `sql`, `result_preview`, `error`), and `meta.workflow`.

Use **`intent_route`** route **`audit`** or Streamlit modes **Audit** / **Auto** when the user combines lineage/tracing with **validating sources** or fixing **pipeline / data mart** issues.

## sql_doc_extract / sql_definition_extract_subagent

- **Source**: `ai-agent-tools/scripts/sql_doc_extract.py` (library), `ai-agent-tools/agents/sql_definition_extract_subagent.py` (CLI).
- **Purpose**: Obtain **base SQL** without the LLM — either a **line range** inside a tracked file (markdown ` ```sql ` blocks often document view bodies) or the **inner query** of a view from the database (`pg_get_viewdef` wrapped as in `postgres_metadata.fetch_views`).
- **Input**:
  - Repo mode: `--repo-file` path under project root, `--lines START END`.
  - DB mode: `--schema`, `--view` (bare view name); requires `PG*` / `PG_DSN`.
- **Output**: JSON with `mode`, `base_sql`, and provenance (`file`/`line_*` or `schema`/`view`).

Use when grounding lineage or DQ checks in **canonical SQL text** from docs or catalog.

## db_investigation_subagent

- **Source**: `ai-agent-tools/agents/db_investigation_subagent.py`
- **Purpose**: **Step 1** — DDL-backed **lineage** for the column/table in the question; **step 2** — structured **`queries`** (purpose + read-only SQL) along upstream objects to investigate suspected bad values (user may paste SQL). Does **not** run the queries.
- **Input**: `--schema`, `--question`, `--max-ddls-chars`; env `PG*` / `PG_DSN`, GigaChat (**LINEAGE_MODEL**); optional `INVESTIGATION_MAX_QUERIES`, `SQL_SUBAGENT_MAX_LIMIT`.
- **Output**: JSON with nested **`lineage`** (same shape as lineage CLI) and **`investigation`** (`lineage_context_summary`, `queries` with `readonly_ok`).

Use together with **`intent_route`** route **`investigate`** or Streamlit **Investigate** mode.

## Usage guidance for agents

- Prefer `export_catalog_tool` as the single source of schema context.
- Ground answers in exported metadata, not assumptions.
- If data is missing in catalog output, explicitly state what is missing.
- For PostgreSQL function or procedure *definitions*, prefer the `ddl` on the matching entry under `procedures` from `export_catalog_tool` (full `CREATE FUNCTION` / `CREATE PROCEDURE` text). For Python, use `extract_function_code` to pull a specific function or method from a file.
