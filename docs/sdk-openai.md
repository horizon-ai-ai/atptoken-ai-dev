# OpenAI SDK

> Source: https://atptoken.ai/docs/sdk-openai/

Use the official OpenAI SDK unchanged. Set the base URL to the Gateway, pass a project API key, and call any model returned by [GET /v1/models](https://atptoken.ai/docs/models/). That list is OpenAI's own list endpoint, so it shows exactly the models this SDK can call on `/v1/chat/completions` and `/v1/responses`.

## Configure the client

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai/v1` |
| Auth | `Authorization: Bearer atp-…` (SDK default) |
| Model | any id from GET /v1/models |

Models not on that list may still be allowed for your project on another entrypoint — most `claude-*` models use the [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic/), Gemini models the [Google GenAI SDK](https://atptoken.ai/docs/sdk-google/). `GET /v1/project/models` lists them all. Call one here and you get `422` naming the right entrypoint.

```
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## Streaming and differences from OpenAI

Set `stream=True` for SSE streaming — see [OpenAI SSE](https://atptoken.ai/docs/sse-openai/). The request and response bodies are exactly OpenAI's. The differences from calling OpenAI directly are the base URL, the `atp-` key, that a model not enabled for your project returns `403` (not billed), and the `stream` default: on `/v1/chat/completions` it is `true` (OpenAI's is `false`), while on `/v1/responses` it is `false`. Moving code between the two flips streaming silently, so always send `stream` explicitly. Full endpoint reference: [/v1/chat/completions](https://atptoken.ai/docs/chat/).

## Next steps

- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — Parameters and response shape for this endpoint.
- [Server-Sent Events](https://atptoken.ai/docs/sse-openai/) — The streaming format you get with `stream=True`.
- [Migrate from OpenAI](https://atptoken.ai/docs/cb-migrate-openai/) — Move an existing OpenAI integration to the Gateway.
