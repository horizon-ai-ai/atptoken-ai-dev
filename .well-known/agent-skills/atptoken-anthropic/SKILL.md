---
name: atptoken-anthropic
description: Call the Atptoken LLM Gateway using the Anthropic SDK or Anthropic-compatible HTTP API — the Messages API, streaming, and count_tokens. Use when the user has Anthropic/Claude-format code and wants it to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the Anthropic surface

Point any Anthropic-compatible client at the gateway base URL and use your `atp-` key. The gateway accepts the Anthropic Messages format and can route to any available model.

- **Base URL:** `https://api.atptoken.ai/v1`
- **Auth:** `Authorization: Bearer atp-...`
- **Model:** any `id` from `GET /v1/models`

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
    auth_token="atp-...",                # sends Authorization: Bearer atp-...
)

msg = client.messages.create(
    model="claude-sonnet-4-6",  # an id from /v1/models
    max_tokens=256,
    messages=[{"role": "user", "content": "Explain a gateway in one sentence."}],
)
print(msg.content[0].text)
```

> Use `auth_token=` (Bearer) rather than `api_key=` so the key is sent as `Authorization: Bearer atp-...`.

## curl

```bash
curl https://api.atptoken.ai/v1/messages \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-6",
    "max_tokens": 256,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

The `anthropic-version` header is forwarded unchanged; the SDK sets it for you.

## Streaming

Set `"stream": true`. The gateway emits the standard Anthropic event sequence:

```
event: message_start        → { ...message envelope... }
event: content_block_start  → { index, content_block }
event: content_block_delta  → { delta: { type: "text_delta", text } }   (repeated)
event: content_block_stop
event: message_delta        → { delta: { stop_reason }, usage }
event: message_stop
```

`stop_reason` maps from the underlying provider (e.g. `end_turn`, `max_tokens`).

## Important format note

- `system` must be a **string** top-level field. Array-style `system` (Anthropic cache_control blocks) is rejected with **400** — send the system prompt as a plain string.
- Fields outside the supported Messages shape are dropped during normalization.
- Errors use the Anthropic error shape (`{"type": "error", "error": {...}}`). See `atptoken-gateway/references/errors.md`.
