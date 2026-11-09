---
name: atptoken-gemini
description: Call the Atptoken LLM Gateway using the Google Gemini SDK or Gemini-compatible HTTP API — generateContent and streamGenerateContent. Use when the user has Google GenAI / Gemini-format code and wants it to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the Gemini surface

Point the `google-genai` SDK (Python `from google import genai`, Node `@google/genai` — not the deprecated `google-generativeai`) at the gateway and use your `atp-` key in place of a Google API key. Only models served on the Gemini entry point work here; a model served elsewhere returns **422** naming the right entry point.

- **Base URL:** `https://api.atptoken.ai`, with **`apiVersion: "v1beta"`**. A client pinned to `v1` fetches its model list from `/v1/models` (OpenAI's endpoint, OpenAI shape) and silently parses **zero** models.
- **Auth:** `x-goog-api-key: atp-...`, `?key=atp-...`, `Authorization: Bearer atp-...` or `x-api-key: atp-...`
- **Model:** an `id` from `GET /v1beta/models` (what this entry point accepts) or `GET /v1/project/models` (everything your project may call). The model goes in the **URL**, not the body. The name does not tell you the entry point: e.g. `gemini-3-5-flash` is served on `/v1/chat/completions`, `gemini-3-5-flash-lite` here.

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
    http_options=types.HttpOptions(base_url="https://api.atptoken.ai", api_version="v1beta"),
)

resp = client.models.generate_content(
    model="gemini-2.5-pro",  # an id from /v1beta/models
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

Streaming is a different endpoint, `:streamGenerateContent` (there is no `stream` field); the SDK's `generate_content_stream` does this for you. Each `data:` event is a complete `GenerateContentResponse` object; the last one carries `finishReason` and `usageMetadata`. There is **no `[DONE]` sentinel** — the stream ends when the connection closes.

```python
for chunk in client.models.generate_content_stream(
    model="gemini-2.5-pro",
    contents="Count to five.",
):
    print(chunk.text, end="")
```

## Notes

- A model your project does not allow returns **403** at create time and is not billed. Not being on a list does not mean unusable.
- Files: send bytes inline with `inlineData`, or `fileData.fileUri` pointing at your own bucket / Gemini File API URI. A gateway-uploaded file id (`an_<ulid>`) does **not** work on this entry point (`404 file_unavailable_for_failover`).
- Tools: `tools[].functionDeclarations`; return results as a `functionResponse` part matched by name. The assistant role is `model`.
- For status codes and retry guidance see `atptoken-gateway/references/errors.md`.
