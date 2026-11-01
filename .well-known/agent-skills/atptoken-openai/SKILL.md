---
name: atptoken-openai
description: Call the Atptoken LLM Gateway using the OpenAI SDK or OpenAI-compatible HTTP API — chat completions, the Responses API, and streaming. Use when the user has OpenAI-format code/tools and wants them to run against Atptoken (api.atptoken.ai) with an atp- API key. See atptoken-gateway for base URL, auth, models, and errors.
---

# Atptoken via the OpenAI surface

Point any OpenAI-compatible client at the gateway base URL and use your `atp-` key as the API key. No code changes beyond `base_url` + key.

- **Base URL:** `https://api.atptoken.ai/v1`
- **Auth:** `Authorization: Bearer atp-...`
- **Model:** any `id` from `GET /v1/models`

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/chat/completions` | Standard chat completions (most common). |
| `POST /v1/responses` | OpenAI Responses API (e.g. tools that default to `wire_api="responses"`). |
| `POST /v1/embeddings` | Text embeddings (OpenAI Embeddings-compatible). |
| `GET /v1/models` | List allowed model names. |

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
  messages: [{ role: "user", content: "Explain a gateway in one sentence." }],
});
console.log(resp.choices[0].message.content);
```

## Streaming

Set `stream: true`. For accurate token usage on the final chunk, also request usage:

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
    model="text-embedding-3-small",  # an embedding id from /v1/models
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

- Use model `id`s from `GET /v1/models`; an unknown/disallowed model returns **403**.
- Errors use the OpenAI error shape (`{"error": {...}}`). See `atptoken-gateway/references/errors.md` for status codes and retry guidance.
- The model you name may be served by a non-OpenAI provider underneath — the response is always translated back to OpenAI format.
