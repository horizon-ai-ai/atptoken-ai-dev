# Anthropic SDK

> Source: https://atptoken.ai/docs/sdk-anthropic/

Use the official Anthropic SDK unchanged. Set the base URL to the Gateway (no `/v1` — the SDK appends `/v1/messages` itself), pass a project API key, and call any model returned by [GET /v1/models](https://atptoken.ai/docs/models/).

## Configure the client

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| Auth | `Authorization: Bearer atp-…` (SDK default) |
| Model | any id from GET /v1/models |

## Send a first request

```
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/models>",
    max_tokens=256,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

## Streaming and the system prompt

Set `stream=True` for SSE streaming — see [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/). The top-level `system` field accepts a string or an array of text blocks.

## Next steps

- [/v1/messages](https://atptoken.ai/docs/messages/) — full endpoint reference
- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence you read when streaming
- [Run Claude Code on ATP](https://atptoken.ai/docs/cb-claude-code/) — point Claude Code at the Gateway
