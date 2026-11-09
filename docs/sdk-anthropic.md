# Anthropic SDK

> Source: https://atptoken.ai/docs/sdk-anthropic/

Use the official Anthropic SDK unchanged. Set the base URL to the Gateway (no `/v1` — the SDK appends `/v1/messages` itself), pass a project API key, and call a model your project allows that is served on `/v1/messages`.

## Configure the client

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| Auth | `x-api-key: atp-…` (SDK default; `Authorization: Bearer` also works) |
| Model | a model your project allows on `/v1/messages` — find it in GET /v1/project/models |

Don't look for Claude models in `GET /v1/models`: that is OpenAI's list endpoint, and most `claude-*` models are not on it. The SDK's `models.list()` also calls `/v1/models`, so it doesn't fail — it just comes back short. Anthropic has no list endpoint of its own; for the complete list call `GET /v1/project/models`. Call a model that isn't served on `/v1/messages` and you get `422` naming the right entrypoint.

## Send a first request

```
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/project/models>",
    max_tokens=256,
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

## Streaming and the system prompt

Three things to get right on this entrypoint:

- `max_tokens` is required (it isn't on the OpenAI side).
- The `anthropic-version` header is required; the SDK sends it for you. For raw requests, see [/v1/messages](https://atptoken.ai/docs/messages/).
- `stream` defaults to `true` here — the opposite of Anthropic's own API — so send it explicitly. Use `stream=True` for SSE (see [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/)) and `stream=False` for a single JSON response.

The top-level `system` field accepts a string or an array of text blocks.

## Next steps

- [/v1/messages](https://atptoken.ai/docs/messages/) — full endpoint reference
- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence you read when streaming
- [Run Claude Code on ATP](https://atptoken.ai/docs/cb-claude-code/) — point Claude Code at the Gateway
