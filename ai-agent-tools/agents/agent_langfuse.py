"""Optional Langfuse tracing for GigaChat-backed agents (env-based, no-op without keys)."""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Any, Generator

from gigachat.models.chat import Chat, ChatCompletion

_MAX_LANGFUSE_MSG_CHARS = 48_000
_MAX_LANGFUSE_OUT_CHARS = 96_000

_client_cache: Any = None
_client_initialized = False


def is_langfuse_configured() -> bool:
    if os.getenv("LANGFUSE_TRACING_ENABLED", "true").lower() in ("0", "false", "no"):
        return False
    pk = (os.getenv("LANGFUSE_PUBLIC_KEY") or "").strip()
    sk = (os.getenv("LANGFUSE_SECRET_KEY") or "").strip()
    return bool(pk and sk)


def get_langfuse_client() -> Any:
    """Return Langfuse client singleton, or None if tracing is not configured."""
    global _client_cache, _client_initialized
    if _client_initialized:
        return _client_cache
    _client_initialized = True
    if not is_langfuse_configured():
        _client_cache = None
        return None
    from langfuse import get_client

    _client_cache = get_client()
    return _client_cache


def _serialize_chat_messages(chat_request: Chat) -> list[dict[str, str]]:
    if not isinstance(chat_request, Chat):
        return [{"role": "?", "content": "(non-Chat request)"}]
    rows: list[dict[str, str]] = []
    for m in chat_request.messages or []:
        role = str(getattr(m, "role", "") or "")
        content = str(getattr(m, "content", "") or "")
        if len(content) > _MAX_LANGFUSE_MSG_CHARS:
            tail = "\n[... truncated for Langfuse ...]"
            content = content[: _MAX_LANGFUSE_MSG_CHARS - len(tail)] + tail
        rows.append({"role": role, "content": content})
    return rows


def _usage_from_completion(resp: ChatCompletion) -> dict[str, int] | None:
    u = getattr(resp, "usage", None)
    if u is None:
        return None
    try:
        return {
            "prompt_tokens": int(getattr(u, "prompt_tokens", 0) or 0),
            "completion_tokens": int(getattr(u, "completion_tokens", 0) or 0),
            "total_tokens": int(getattr(u, "total_tokens", 0) or 0),
        }
    except (TypeError, ValueError):
        return None


def traced_giga_chat(
    lf: Any,
    giga: Any,
    chat_request: Chat,
    *,
    observation_name: str,
    model: str,
) -> ChatCompletion:
    """
    Run ``giga.chat(chat_request)`` inside a Langfuse generation span when ``lf`` is set.

    Without Langfuse credentials, delegates to a plain ``giga.chat`` call.
    """
    if lf is None:
        return giga.chat(chat_request)

    inp = _serialize_chat_messages(chat_request)
    with lf.start_as_current_observation(
        name=observation_name,
        as_type="generation",
        model=model,
        input=inp,
    ) as gen:
        try:
            resp = giga.chat(chat_request)
            text = ""
            if resp.choices:
                text = (resp.choices[0].message.content or "") or ""
            if len(text) > _MAX_LANGFUSE_OUT_CHARS:
                tail = "\n[... truncated for Langfuse ...]"
                text = text[: _MAX_LANGFUSE_OUT_CHARS - len(tail)] + tail
            gen.update(output=text, usage_details=_usage_from_completion(resp))
            return resp
        except Exception as e:
            msg = str(e)
            if len(msg) > 2000:
                msg = msg[:2000] + "..."
            gen.update(level="ERROR", status_message=msg)
            raise


@contextmanager
def root_agent_span(
    lf: Any,
    *,
    name: str,
    input: dict[str, Any],
    metadata: dict[str, Any] | None = None,
) -> Generator[Any, None, None]:
    """Root ``agent`` observation for a CLI run; no-op when ``lf`` is None."""
    if lf is None:
        yield None
        return
    meta = {"component": "giga4dqm-agent", **(metadata or {})}
    with lf.start_as_current_observation(
        name=name,
        as_type="agent",
        input=input,
        metadata=meta,
    ) as span:
        yield span


def flush_langfuse(lf: Any) -> None:
    if lf is None:
        return
    try:
        lf.flush()
    except Exception:
        pass
