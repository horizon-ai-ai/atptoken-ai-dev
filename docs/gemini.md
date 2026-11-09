# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST-style `generateContent` and `streamGenerateContent` routes are supported under both `/v1` and `/v1beta`.

Use the `google-genai` SDK (Python or Node), not the deprecated `google-generativeai`. Point its base URL at `https://api.atptoken.ai` and set `apiVersion` to `"v1beta"`.

> **Set apiVersion to v1beta**
>
> A client pinned to `apiVersion: "v1"` asks for its model list at `/v1/models`. That is OpenAI's list endpoint and answers in OpenAI's shape, so the Gemini SDK parses **zero** models — without an error. Chat calls are not affected: `/v1/models/{model}:generateContent` and `/v1beta/models/{model}:generateContent` are both Gemini routes and both work.

## Routes

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/v1beta/models/{model}:generateContent` | one response; the SDK default prefix |
| POST | `/v1beta/models/{model}:streamGenerateContent` | Server-Sent Events |
| POST | `/v1/models/{model}:generateContent` | same as `/v1beta` |
| POST | `/v1/models/{model}:streamGenerateContent` | same as `/v1beta` |

The model goes in the **URL**, not in the body. `{model}` is an id from `GET /v1beta/models`, which lists what these routes accept — for example `gemini-3-5-flash-lite`. The full list for your project is [GET /v1/project/models](https://atptoken.ai/docs/models/).

You cannot tell the entry point from a model's name. `gemini-3-5-flash` is served on `/v1/chat/completions`, while `gemini-3-5-flash-lite` is served here. Call a model on the wrong entry point and you get `422` with a message that names the right one.

## Authentication

All of these work; use whichever your client sends. See [Authentication](https://atptoken.ai/docs/auth/).

| Form | Example |
| --- | --- |
| `x-goog-api-key` header | `x-goog-api-key: atp-...` — the Google GenAI SDK default |
| `key` query parameter | `…:generateContent?key=atp-...` — logs scrub it, but prefer a header |
| Bearer header | `Authorization: Bearer atp-...` |
| `x-api-key` header | `x-api-key: atp-...` |

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
    http_options={"base_url": "https://api.atptoken.ai", "api_version": "v1beta"},
)
r = client.models.generate_content(
    model="<model from GET /v1beta/models>",
    contents="hi",
)
print(r.text)
```

```Node.js
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: "atp-...",
  httpOptions: { baseUrl: "https://api.atptoken.ai", apiVersion: "v1beta" },
});
const r = await ai.models.generateContent({
  model: "<model from GET /v1beta/models>",
  contents: "hi",
});
console.log(r.text);
```

`contents`, `systemInstruction` and `generationConfig` (for example `maxOutputTokens`, `temperature`) use the Gemini field names.

Other top-level fields include tools, tool config, safety settings, cached content and labels. The Gateway forwards fields as they are, so one model may accept a field that another rejects.

### Files

- Send images, audio and documents inline as `inlineData` (base64).
- Or send `fileData` with a `fileUri` the model can read — your own bucket or a Gemini File API URI, forwarded unchanged.
- A file uploaded to the Gateway (`an_<ulid>`) **cannot** be used on this entry point: referencing it returns `404 file_unavailable_for_failover`. Embed the bytes with `inlineData` instead.

### Tool calls

Declare tools in `tools[].functionDeclarations`. The model's call comes back as a `functionCall` part, and you return the result as a `functionResponse` part in a `user` turn, matched by **name** (there is no id). The assistant role on this entry point is `model`, not `assistant`.

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

Each `data:` event is a complete `GenerateContentResponse` JSON object, not an OpenAI-style delta.

`finishReason` is `null` until the last chunk, which also carries `usageMetadata`. There is no `[DONE]` line — the stream ends when the connection closes. Code that waits for `data: [DONE]` will hang here.

## Differences from Google's API

| Feature | Google's API | The Gateway |
| --- | --- | --- |
| `streamGenerateContent` without `?alt=sse` | one JSON array | Server-Sent Events |

## Errors

- 401 — `token_revoked`: missing or invalid key. Sending no key also returns this.
- 402 — `insufficient_quota`: your balance is used up. Do not retry; add credits first.
- 403 — the model is not enabled for this project or does not exist. Not billed.
- 404 — `file_unavailable_for_failover`: you referenced an uploaded `an_<ulid>` file. Use `inlineData`.
- 422 — the model is not served on this entry point. The message names the right one.
- 429 — rate limited, or no capacity for this model right now. Follow `Retry-After`.

See [Error codes](https://atptoken.ai/docs/errors/) for every status and what to check first.

## Next steps

- [Google GenAI SDK](https://atptoken.ai/docs/sdk-google/) — point the SDK at the Gateway and call it unchanged
- [Authentication](https://atptoken.ai/docs/auth/) — every place your key can go, and what a `401` means
- [Error codes](https://atptoken.ai/docs/errors/) — what to check first for each status code
