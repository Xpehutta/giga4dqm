"""
Shared logging for Giga4DQM agents and Streamlit.

Set ``LOG_LEVEL`` to DEBUG, INFO (default), WARNING, etc.
"""

from __future__ import annotations

import logging
import os

_CONFIGURED = False
_DEFAULT_FORMAT = "%(asctime)s %(levelname)s [%(name)s] %(message)s"


def configure_logging() -> None:
    """Idempotent: one ``basicConfig`` / root level for the process."""
    global _CONFIGURED
    level_name = (os.getenv("LOG_LEVEL") or "INFO").upper()
    level = getattr(logging, level_name, logging.INFO)
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(level=level, format=_DEFAULT_FORMAT)
    else:
        root.setLevel(level)
    _CONFIGURED = True


def get_logger(name: str) -> logging.Logger:
    """Return ``giga4dqm.<name>``; configures logging on first use."""
    if not _CONFIGURED:
        configure_logging()
    return logging.getLogger(f"giga4dqm.{name}")
