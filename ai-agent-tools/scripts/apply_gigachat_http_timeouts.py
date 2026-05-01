#!/usr/bin/env python3
"""
Patch gigachat's httpx client factory so TLS connect can use a separate timeout.

The official client passes ``httpx.Timeout(settings.timeout)`` with one value for all phases.
Slow networks or VPNs may need a longer **connect** (including SSL handshake) budget than reads.

Call ``apply()`` before constructing ``gigachat.GigaChat`` (once per process).

Environment (optional):

- ``GIGACHAT_CONNECT_TIMEOUT`` — seconds for TCP + TLS handshake to the API and OAuth host.
  If unset, behaviour matches upstream (uniform timeout via ``GIGACHAT_TIMEOUT`` / client ``timeout``).
"""

from __future__ import annotations

import os
from typing import Any

_applied = False


def apply() -> None:
    """Monkey-patch ``gigachat.client`` timeout helpers idempotently."""
    global _applied
    if _applied:
        return
    import httpx
    import gigachat.client as gc

    _orig_get = gc._get_kwargs
    _orig_auth = gc._get_auth_kwargs

    def _timeout_for(settings_timeout: float) -> httpx.Timeout:
        total = float(settings_timeout)
        raw = os.getenv("GIGACHAT_CONNECT_TIMEOUT", "").strip()
        if raw:
            return httpx.Timeout(total, connect=float(raw))
        return httpx.Timeout(total)

    def _get_kwargs(settings: Any) -> dict[str, Any]:
        out = _orig_get(settings)
        out["timeout"] = _timeout_for(settings.timeout)
        return out

    def _get_auth_kwargs(settings: Any) -> dict[str, Any]:
        out = _orig_auth(settings)
        out["timeout"] = _timeout_for(settings.timeout)
        return out

    gc._get_kwargs = _get_kwargs
    gc._get_auth_kwargs = _get_auth_kwargs
    _applied = True
