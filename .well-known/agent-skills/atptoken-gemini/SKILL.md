---
name: atptoken-gemini
description: Call the Atptoken LLM Gateway using the Google Gemini SDK or Gemini-compatible HTTP API — generateContent and streamGenerateContent. Use when the user has Google GenAI / Gemini-format code and wants it to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the Gemini surface

Point a Google Gemini client at the gateway and use your `atp-` key in place of a Google API key. The gateway speaks the Gemini `generateContent` format and can route to any available model.

- **Base URL:** `https://api.atptoken.ai` (the Gemini SDK adds the `/v1beta/models/...` path)
- **Auth:** `x-goog-api-key: atp-...` **or** `?key=atp-...`
- **Model:** any `id` from `GET /v1/models`

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /v1beta/models/{model}:generateContent` | Single (non-streaming) generation. |
| `POST /v1beta/models/{model}:streamGenerateContent` | Streaming generation. |

(The `/v1/models/{model}:generateContent` form is also accepted.)

## Python (`google-genai` SDK)

```python
from google import genai
from google.genai import types

client = genai.Client(
    api_key="atp-...",  # your Atptoken key, sent as x-goog-api-key
    http_options=types.HttpOptions(base_url="https://api.atptoken.ai"),
)

resp = client.models.generate_content(
    model="gemini-2.5-pro",  # an id from /v1/models
    contents="Explain a gateway in one sentence.",
)
print(resp.text)
```

## curl

Header form:

```bash
curl "https://api.atptoken.ai/v1beta/models/gemini-2.5-pro:generateContent" \
  -H "x-goog-api-key: $ATPTOKEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{ "parts": [{ "text": "Hello" }] }]
  }'
```

Query-parameter form (handy for quick tests):

```bash
curl "https://api.atptoken.ai/v1beta/models/gemini-2.5-pro:generateContent?key=$ATPTOKEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "contents": [{ "parts": [{ "text": "Hello" }] }] }'
```

## Streaming

Use the `:streamGenerateContent` action (the SDK's `generate_content_stream` does this for you). The gateway returns the Gemini streaming response format.

```python
for chunk in client.models.generate_content_stream(
    model="gemini-2.5-pro",
    contents="Count to five.",
):
    print(chunk.text, end="")
```

## Notes

- Use model `id`s from `GET /v1/models`; an unknown/disallowed model returns a permission error.
- A model named here may be served by a non-Google provider underneath — the gateway translates the response back to Gemini format.
- For status codes and retry guidance see `atptoken-gateway/references/errors.md`.
