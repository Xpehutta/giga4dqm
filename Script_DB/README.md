# Script_DB

Original upstream SQL scripts (source of truth).

## Purpose

- Keeps the canonical/original script set as received.
- Serves as reference for future updates and diffs.
- Should be used to understand intended logic and full test workflow.

## Important

- These scripts are Greenplum-oriented.
- They are **not** guaranteed to run on vanilla PostgreSQL without adaptation.

## Editing policy

- Prefer **not** editing files here unless you are updating from upstream source.
- PostgreSQL-compatible changes should go into `Script_DB_pg`.

## Related

- See `../Script_DB_pg` for PostgreSQL-adapted executable scripts.
- See `../SETUP_FROM_SCRATCH.md` for end-to-end setup and run order.

