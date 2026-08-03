# OpenAI SDK

> Source: https://atptoken.ai/docs/sdk-openai/

Use the official OpenAI SDK unchanged. Set the base URL to the Gateway, pass a project API key, and call any model returned by [GET /v1/models](https://atptoken.ai/docs/models/).

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai/v1` |
| Auth | `Authorization: Bearer atp-…` (SDK default) |
| Model | any id from GET /v1/models |

```
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

Set `stream=True` for SSE streaming — see [OpenAI SSE](https://atptoken.ai/docs/sse-openai/). The request and response bodies are exactly OpenAI's; the only differences from calling OpenAI directly are the base URL, the `atp-` key, and that a model not enabled for your project returns `403`. Full endpoint reference: [/v1/chat/completions](https://atptoken.ai/docs/chat/).
