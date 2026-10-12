# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST-style `generateContent` and `streamGenerateContent` routes are supported under both `/v1` and `/v1beta` (the Google GenAI SDK default). Authenticate with `x-goog-api-key` — the SDK's default.

## Routes

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/v1beta/models/{model}:generateContent` | one response; the SDK default prefix |
| POST | `/v1beta/models/{model}:streamGenerateContent` | Server-Sent Events |
| POST | `/v1/models/{model}:generateContent` | same as `/v1beta` |
| POST | `/v1/models/{model}:streamGenerateContent` | same as `/v1beta` |

`{model}` is an id from [GET /v1/models](https://atptoken.ai/docs/models/) — for example `gemini-3-5-flash-lite`.

## Authentication

All three forms work; use whichever your client sends. See [Authentication](https://atptoken.ai/docs/auth/).

| Form | Example |
| --- | --- |
| `x-goog-api-key` header | `x-goog-api-key: atp-...` — the Google GenAI SDK default |
| `key` query parameter | `…:generateContent?key=atp-...` — logs scrub it, but prefer a header |
| Bearer header | `Authorization: Bearer atp-...` |

## Request

```curl
curl "https://api.atptoken.ai/v1/models/<model>:generateContent" \
  -H "x-goog-api-key: atp-..." \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{ "parts": [{ "text": "hi" }] }]
  }'
```

```Python
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

```Node.js
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: "atp-...",
  httpOptions: { baseUrl: "https://api.atptoken.ai" },
});
const r = await ai.models.generateContent({
  model: "<model from GET /v1/models>",
  contents: "hi",
});
console.log(r.text);
```

`contents`, `systemInstruction` and `generationConfig` (for example `maxOutputTokens`, `temperature`) use the Gemini field names.

## Response

#### Response

```json
{
  "candidates": [
    {
      "content": {
        "parts": [{ "text": "Hello there, friend!" }],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ],
  "createTime": "2026-10-07T08:32:26.357216Z",
  "modelVersion": "gemini-3-5-flash-lite",
  "responseId": "01M3F7W9CNBGWDEBPB0NBDS0AD",
  "usageMetadata": {
    "candidatesTokenCount": 5,
    "promptTokenCount": 31,
    "totalTokenCount": 36
  }
}
```

Token counts are in `usageMetadata`, and `responseId` is a Gateway id, not a Google one.

## Streaming

`streamGenerateContent` always answers with Server-Sent Events (`Content-Type: text/event-stream`), whether or not you add `?alt=sse`. This differs from Google's own API, which returns a single JSON array when `alt=sse` is missing — a client that expects that array needs `?alt=sse` handling instead. The Google GenAI SDK already requests SSE and works unchanged.

#### Request

```
curl -N "https://api.atptoken.ai/v1beta/models/gemini-3-5-flash-lite:streamGenerateContent?alt=sse" \
  -H "x-goog-api-key: atp-..." \
  -H "Content-Type: application/json" \
  -d '{ "contents": [{ "role": "user", "parts": [{ "text": "Say hi in 3 words" }] }] }'
```

#### Response

```
data: {"candidates":[{"content":{"parts":[{"text":"Hello there"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":", friend!"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":""}],"role":"model"},"finishReason":"STOP","index":0}],"usageMetadata":{"candidatesTokenCount":5,"promptTokenCount":31,"totalTokenCount":36}}
```

Each chunk carries only the new text. `finishReason` is `null` until the last chunk, which also carries `usageMetadata`. There is no `[DONE]` line — the stream ends when the connection closes.

## Differences from Google's API

| Feature | Google's API | The Gateway |
| --- | --- | --- |
| `streamGenerateContent` without `?alt=sse` | one JSON array | Server-Sent Events |

## Errors

- 401 — missing or invalid key.
- 403 — the model is not enabled for this project or does not exist.

See [Error codes](https://atptoken.ai/docs/errors/) for every status and what to check first.

## Next steps

- [Google GenAI SDK](https://atptoken.ai/docs/sdk-google/) — point the SDK at the Gateway and call it unchanged
- [Authentication](https://atptoken.ai/docs/auth/) — every place your key can go, and what a `401` means
- [Error codes](https://atptoken.ai/docs/errors/) — what to check first for each status code
