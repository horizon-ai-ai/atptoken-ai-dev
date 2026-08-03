# Google GenAI SDK

> Source: https://atptoken.ai/docs/sdk-google/

Use the Google GenAI SDK unchanged. Set the base URL to the Gateway, authenticate with `x-goog-api-key` (the SDK default), and call any model returned by [GET /v1/models](https://atptoken.ai/docs/models/).

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| Auth | `x-goog-api-key: atp-…` (SDK default) |
| Model | any id from GET /v1/models |

```
from google import genai

client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai"},
)
r = client.models.generate_content(
    model="<model from GET /v1/models>",
    contents="hi",
)
print(r.text)
```

The `generateContent` and `streamGenerateContent` routes work under both `/v1` and `/v1beta` (the SDK default). Full endpoint reference: [/v1/models/{model}:generateContent](https://atptoken.ai/docs/gemini/).
