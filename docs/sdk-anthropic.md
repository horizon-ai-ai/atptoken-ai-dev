# Anthropic SDK

> Source: https://atptoken.ai/docs/sdk-anthropic/

Use the official Anthropic SDK unchanged. Set the base URL to the Gateway (no `/v1` — the SDK appends `/v1/messages` itself), pass a project API key, and call any model returned by [GET /v1/models](https://atptoken.ai/docs/models/).

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| Auth | `Authorization: Bearer atp-…` (SDK default) |
| Model | any id from GET /v1/models |

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

Set `stream=True` for SSE streaming — see [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/). Note the top-level `system` field must be a string; the array form is not yet supported. Full endpoint reference: [/v1/messages](https://atptoken.ai/docs/messages/).
