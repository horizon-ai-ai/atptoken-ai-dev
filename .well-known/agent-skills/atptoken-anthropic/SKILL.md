---
name: atptoken-anthropic
description: Call the Atptoken LLM Gateway using the Anthropic SDK or Anthropic-compatible HTTP API — the Messages API, streaming, and count_tokens. Use when the user has Anthropic/Claude-format code and wants it to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the Anthropic surface

Point the official `anthropic` SDK at the gateway and pass your `atp-` key as `api_key`. Only models served on `/v1/messages` work here; a model served on another entry point returns **422** naming the right one.

- **Base URL:** `https://api.atptoken.ai` (the SDK appends `/v1/messages`)
- **Auth:** `x-api-key: atp-...` (what the SDK sends with `api_key=`) or `Authorization: Bearer atp-...`
- **Header:** `anthropic-version: 2023-06-01` (the SDK sets it)
- **Model:** an `id` from `GET /v1/project/models`. Most `claude-*` models are **not** in `GET /v1/models` (that is OpenAI's list), and there is no Anthropic list endpoint — so the SDK's `models.list()` silently returns a short list.
- **`max_tokens`:** required.
- **`stream`:** defaults to `true` on this endpoint (unlike Anthropic's own API). Always send it explicitly.

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/messages` | Anthropic Messages (chat). |
| `POST /v1/messages/count_tokens` | Token counting (used by Claude clients). |

## Python (official `anthropic` SDK)

```python
from anthropic import Anthropic

client = Anthropic(
    base_url="https://api.atptoken.ai",  # SDK appends /v1/messages
    api_key="atp-...",                   # sent as x-api-key, which the gateway accepts
)

msg = client.messages.create(
    model="claude-sonnet-4-6",  # an id from /v1/project/models
    max_tokens=256,
    stream=False,  # this endpoint defaults to stream=true
    messages=[{"role": "user", "content": "Explain a gateway in one sentence."}],
)
print(msg.content[0].text)
```

## curl

```bash
curl https://api.atptoken.ai/v1/messages \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-6",
    "max_tokens": 256,
    "stream": false,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

Send the `anthropic-version` header; the SDK sets it for you.

## Streaming

Set `"stream": true` (the default here, but send it explicitly). The gateway emits the standard Anthropic event sequence:

```
event: message_start        → { ...message envelope... }
event: content_block_start  → { index, content_block }
event: content_block_delta  → { delta: { type: "text_delta", text } }   (repeated)
event: content_block_stop
event: message_delta        → { delta: { stop_reason }, usage }
event: message_stop
```

`stop_reason` maps from the underlying provider (e.g. `end_turn`, `max_tokens`). Read token usage from `message_delta`, not `message_start`.

## Important format note

- `system` is a top-level field (not inside `messages`): a string, or an array of text blocks that may carry `cache_control`.
- Tools use `input_schema` (not `function.parameters`). Tool results go back in a **`user`** message as a `tool_result` block matched by `tool_use_id` — not `role: "tool"`.
- Prompt caching: put `cache_control: {"type": "ephemeral"}` (optionally `"ttl": "1h"`) on the last block of the stable prefix, or at the top level of the body. Not allowed on blocks inside `tool_result.content` — put it on the `tool_result` itself.
- Fields and roles are forwarded as is, not checked against the model's schema. A wrong-format message (e.g. OpenAI `role: "tool"`) may get a 200 while the model ignores it — use this endpoint's own format.
- `POST /v1/messages/count_tokens` returns `{"input_tokens": n}`, not billed.
- Errors use the Anthropic error shape (`{"type": "error", "error": {...}}`), except a **401**, whose body is `{"message": "...", "error": "token_revoked"}`. See `atptoken-gateway/references/errors.md`.
