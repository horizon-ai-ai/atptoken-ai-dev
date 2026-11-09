---
name: atptoken-openai
description: Call the Atptoken LLM Gateway using the OpenAI SDK or OpenAI-compatible HTTP API — chat completions, the Responses API, and streaming. Use when the user has OpenAI-format code/tools and wants them to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the OpenAI surface

Point any OpenAI-compatible client at the gateway base URL and use your `atp-` key as the API key. No code changes beyond `base_url` + key.

- **Base URL:** `https://api.atptoken.ai/v1`
- **Auth:** `Authorization: Bearer atp-...` (or `x-api-key: atp-...`)
- **Model:** an `id` from `GET /v1/models` — that list is exactly what `/v1/chat/completions` and `/v1/responses` accept
- **`stream`:** defaults to `true` on `/v1/chat/completions` and `false` on `/v1/responses`. Always send it explicitly.

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/chat/completions` | Standard chat completions (most common). |
| `POST /v1/responses` | OpenAI Responses API (e.g. tools that default to `wire_api="responses"`). |
| `POST /v1/embeddings` | Text embeddings (OpenAI Embeddings-compatible). |
| `GET /v1/models` | Models your project may call on `/v1/chat/completions` and `/v1/responses` only. |
| `GET /v1/project/models` | Every model your project may call, on any entry point (`{"data":[{"id":…}]}`). |

> Video, image generation, and text-to-speech are on a separate media surface (`/omni/media/v1/...`) — see the **atptoken-video** / **atptoken-image** / **atptoken-audio** skills.

## Python (official `openai` SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.atptoken.ai/v1",
    api_key="atp-...",  # your Atptoken key
)

resp = client.chat.completions.create(
    model="gpt-5",  # an id from /v1/models
    stream=False,  # this endpoint defaults to stream=true
    messages=[{"role": "user", "content": "Explain a gateway in one sentence."}],
)
print(resp.choices[0].message.content)
```

## Node / TypeScript

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "https://api.atptoken.ai/v1",
  apiKey: process.env.ATPTOKEN_API_KEY, // atp-...
});

const resp = await client.chat.completions.create({
  model: "gpt-5",
  stream: false, // this endpoint defaults to stream: true
  messages: [{ role: "user", content: "Explain a gateway in one sentence." }],
});
console.log(resp.choices[0].message.content);
```

## Streaming

Set `stream: true`. The gateway always sends `stream_options: {"include_usage": true}` upstream on streaming requests, so the stream ends with an extra chunk carrying `usage`. Sending it yourself (as below) is harmless:

```python
stream = client.chat.completions.create(
    model="gpt-5",
    messages=[{"role": "user", "content": "Count to five."}],
    stream=True,
    stream_options={"include_usage": True},
)
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

The response is standard OpenAI SSE (`data: {...}` lines ending with `data: [DONE]`).

## curl

```bash
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false
  }'
```

## Embeddings

`POST /v1/embeddings`, OpenAI Embeddings-compatible. `input` is a string or an array of strings.

```python
emb = client.embeddings.create(
    model="text-embedding-3-small",  # embedding models are not in /v1/models; see /v1/project/models
    input=["hello world", "second text"],
)
print(len(emb.data), len(emb.data[0].embedding))
```

```bash
curl https://api.atptoken.ai/v1/embeddings \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" -H "Content-Type: application/json" \
  -d '{ "model": "text-embedding-3-small", "input": "hello world" }'
```

Response is the standard OpenAI shape (`{"object":"list","data":[{"embedding":[...]}],"model":...,"usage":{...}}`). A model that isn't an embedding model returns **422** `no_embedding_provider`.

## Notes

- Each model is served on **one** entry point; the name does not tell you which. `GET /v1/models` lists only this surface's chat models — most `claude-*` models are on `/v1/messages` (see **atptoken-anthropic**), Gemini-only ones on `/v1beta/models/{model}:generateContent`, media and embeddings elsewhere. Calling a model on the wrong entry point returns **422** with a message naming the right one.
- Not being on a list does not mean unusable. A model your project does not allow returns **403** `permission_denied` at create time and is not billed.
- `/v1/responses` is stateless: `store` and `previous_response_id` are ignored — send the full `input` every turn.
- HTTP 200 does not prove the model saw everything you sent; fields and roles are forwarded as is and some models silently ignore what they don't understand.
- Errors use the OpenAI error shape (`{"error": {...}}`). See `atptoken-gateway/references/errors.md` for status codes and retry guidance.
