# /v1/embeddings

> Source: https://atptoken.ai/docs/embeddings/

`POST /v1/embeddings`

Turn text, images, audio or video into vectors with one synchronous call. The request body follows OpenAI's embeddings schema, so the official `openai` SDK works with only the base URL changed. Embeddings bill on **input tokens only** — there is no output meter. Rates are on the [pricing page](https://atptoken.ai/pricing/).

## Request

`input` is one string or an array; each element becomes one vector, returned in the same order. A string is embedded as text. For images, audio or video, send an object instead of a string — see the input types section.

```curl
curl https://api.atptoken.ai/v1/embeddings \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-embedding-2-text",
    "input": ["first passage", "second passage"]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.embeddings.create(
    model="gemini-embedding-2-text",
    input=["first passage", "second passage"],
)
print(len(r.data), len(r.data[0].embedding))
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.embeddings.create({
  model: "gemini-embedding-2-text",
  input: ["first passage", "second passage"],
});
console.log(r.data.length, r.data[0].embedding.length);
```

## Parameters

Only `model` and `input` are required.

| Field | Type | Description |
|---|---|---|
| model | string · required | An embedding model id from the table below. It must be on your project's allowed list. |
| input | string, object, or array of either · required | What to embed. A string is text. An object is one content part (`inlineData` or `fileData`), or a whole content with a `parts` array. An array returns one vector per element, in the same order. |
| dimensions | integer | Vector length. Send a value the model supports (see the table) to get shorter vectors; leave it out for the model's native size. |
| encoding_format | string | Only `float` is returned. |
| user | string | A free-form identifier for your own tracing. It does not change the result. |

## Response

```
{
  "object": "list",
  "model": "gemini-embedding-2-text",
  "data": [
    { "object": "embedding", "index": 0, "embedding": [0.0123, -0.0456, ...] },
    { "object": "embedding", "index": 1, "embedding": [0.0078, 0.0211, ...] }
  ],
  "usage": { "prompt_tokens": 11, "total_tokens": 11 }
}
```

- `data[].index` is the position of that element in `input`.
- `usage.prompt_tokens` is the billed amount, summed over every element in the request.
- A batch is all-or-nothing: if any element fails, the request returns an error and nothing is billed.

## Models

| Model | Native size | `dimensions` | Input per element |
|---|---|---|---|
| gemini-embedding-2-text | 3072 | 128 to 3072 | text, up to 8,192 tokens |
| gemini-embedding-2-image | 3072 | 128 to 3072 | images (PNG, JPEG, WebP, BMP, HEIC, HEIF, AVIF), up to 6 |
| gemini-embedding-2-audio | 3072 | 128 to 3072 | audio (MP3, WAV), up to 180 seconds |
| gemini-embedding-2-video | 3072 | 128 to 3072 | video (MP4, MPEG), up to 120 seconds |
| text-embedding-3-large | 3072 | any value up to 3072 | text, up to 8,191 tokens |
| text-embedding-3-small | 1536 | any value up to 1536 | text, up to 8,191 tokens |

The four Gemini ids are one model with one meter per content type. They write vectors into the same 3072-dimension space, so a vector from one can be compared with a vector from another — text against images, or a query against a video. Rates per id are on the [pricing page](https://atptoken.ai/pricing/).

## Input types

Each element of `input` is one of the following:

| Element | Shape | What it becomes |
|---|---|---|
| string | `"a passage of text"` | one text part |
| inline data | `{ "inlineData": { "mimeType": "image/png", "data": "<base64>" } }` | one part carrying the bytes |
| file reference | `{ "fileData": { "mimeType": "image/png", "fileUri": "https://…" } }` | one part the model fetches itself |
| content | `{ "parts": [ { "text": "…" }, { "inlineData": { … } } ] }` | several parts, one vector for all of them |

Objects are forwarded as sent. A part the model cannot use — an unknown key, a file over its limit, or a URL it cannot fetch — returns `400` with the model's own message.

#### Request with an image

```
curl https://api.atptoken.ai/v1/embeddings \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-embedding-2-image",
    "input": [
      { "inlineData": { "mimeType": "image/png", "data": "iVBORw0KGgo..." } }
    ]
  }'
```

> **The id sets the rate**
>
> Every Gemini id accepts every element type, and the request bills at the rate of the id you called. Send images through `gemini-embedding-2-image`, audio through `-audio`, video through `-video`, and text through `-text`.

## Billing

Embeddings bill on input tokens only. For the Gemini ids the token count follows the content: text by tokens, image at 258 tokens per image, audio at 25 tokens per second, and video at 66 tokens per frame at one frame per second. A content element with several parts bills the sum of its parts. Every element shares one 8,192-token window, and content past it is dropped rather than refused. How tokens turn into credits is on [Credits](https://atptoken.ai/docs/credits/).

## Errors

- 400 — `input` is missing or empty, or an element the model rejects: an unknown part key, a file over its limit, or a URL it cannot fetch. The message is the model's own.
- 402 — `insufficient_quota`: your balance is used up. Do not retry; add credits first.
- 403 — The model is not on your project's allowed list. Not a key or balance problem.
- 422 — `embedding_error`: this id is not served as an embedding model for your project. Check it against `GET /v1/project/models`.
- 429 — Rate limited, or no capacity for this model right now. Follow `Retry-After`.

## Next steps

- [Model discovery](https://atptoken.ai/docs/models/) — List every model id your project may call, embeddings included.
- [Media models](https://atptoken.ai/docs/media/) — Image, video and audio generation on the same key.
- [Credits](https://atptoken.ai/docs/credits/) — How billed tokens turn into credits.
