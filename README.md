# Giga4DQM

PostgreSQL-focused **data quality and exploration** helpers: metadata catalog Q&A, read-only SQL over live data, DDL-based lineage, combined lineage + data audits, and investigation workflows—all driven by **[GigaChat](https://developers.sber.ru/portal/products/gigachat)** and optional **[Langfuse](https://langfuse.com)** tracing.

---

## Features

- **Streamlit chat UI** — one place to pick schema, agent mode (catalog, data, lineage, audit, investigate, or auto-routing), and chat with bounded multi-turn context.
- **CLI agents** — same logic as the UI, runnable as scripts under [`ai-agent-tools/agents/`](ai-agent-tools/agents/).
- **LangGraph flows** — multi-step pipelines (e.g. lineage then SQL proposals) with structured JSON outputs.
- **Local Postgres** — optional Docker Compose database for development (`docker-compose.yml`).

For mode descriptions, sidebar options, and diagrams, see **[`workflow.md`](workflow.md)**.

---

## Requirements

- **Python 3.12+**
- **[uv](https://docs.astral.sh/uv/)** (recommended) for environments and runs  
- **PostgreSQL** reachable from your machine  
- **GigaChat** API credentials  

---

## Quick start

```bash
git clone https://github.com/Xpehutta/giga4dqm.git
cd giga4dqm
cp .env.example .env
# Edit .env: PG*, GIGACHAT_*, optional LANGFUSE_* (see ai-agent-tools/README.md)

uv sync
uv run streamlit run streamlit_app.py
```

### Optional: local database

```bash
docker compose up -d
```

Default compose maps Postgres to **localhost:5433** (database/user/password `giga4dqm`). Align `PGPORT` / `PG*` in `.env` with your setup.

### Loan / banking demo schema

End-to-end SQL setup and narrative: **[`setup_loan_db.md`](setup_loan_db.md)** and [`sql/setup_loans/`](sql/setup_loans/).

---

## Repository layout

| Path | Purpose |
|------|---------|
| [`streamlit_app.py`](streamlit_app.py) | Main UI; spawns agent CLIs and loads intent routing. |
| [`ai-agent-tools/`](ai-agent-tools/) | Agents, prompts, scripts, catalog JSON — see **[`ai-agent-tools/README.md`](ai-agent-tools/README.md)**. |
| [`sql/setup_loans/`](sql/setup_loans/) | Idempotent loan/banking schema + data + views. |
| [`Script_DB/`](Script_DB/), [`Script_DB_pg/`](Script_DB_pg/) | Additional SQL / test harness assets. |
| [`docker-compose.yml`](docker-compose.yml) | App Postgres (dev). |
| [`docker-compose.langfuse.yml`](docker-compose.langfuse.yml) | Optional self-hosted Langfuse v3 stack (use a **separate** compose project name; file header explains `-p`). |
| [`workflow.md`](workflow.md) | User workflow, routing, and architecture notes. |
| [`src/giga4dqm/`](src/giga4dqm/) | Small library package (tests in [`tests/`](tests/)). |

---

## Configuration

- Copy **`.env.example`** → **`.env`**. Never commit `.env` (it is gitignored).
- **Agents / UI:** PostgreSQL (`PG*` or `PG_DSN`) and GigaChat env vars are documented in **[`ai-agent-tools/README.md`](ai-agent-tools/README.md)** (timeouts, intent routing, optional Langfuse Cloud EU, logging).

---

## Tests and lint

```bash
uv run pytest
uv run ruff check .
```

---

## License

Specify a license in the repository settings or add a `LICENSE` file if you want this project to be explicitly open source.
