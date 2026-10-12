# /v1/chat/completions

> Source: https://atptoken.ai/docs/chat/

`POST /v1/chat/completions`

Use this endpoint with any OpenAI SDK client. The request body follows OpenAI's chat completions schema unchanged. The `model` field must be a value returned by `GET /v1/models`.

## Request

Replace `MODEL_ID` with a model id from [GET /v1/models](https://atptoken.ai/docs/models/).

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.chat.completions.create(
    model="MODEL_ID",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.chat.completions.create({
  model: "MODEL_ID",
  messages: [{ role: "user", content: "hi" }],
});
console.log(r.choices[0].message.content);
```

## Parameters

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id from GET /v1/models. |
| messages | array · required | Chat messages, each { role, content }. |
| max_tokens | integer | Max output tokens. Reasoning models spend their thinking inside this budget — set it too low and you get a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| temperature | number | Sampling temperature, 0–2. |
| stream | boolean | Stream the response as SSE chunks. |
| tools | array | Tool/function definitions (OpenAI tool schema). |

## Response

```
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "model": "<model>",
  "choices": [
    {
      "index": 0,
      "message": { "role": "assistant", "content": "..." },
      "finish_reason": "stop"
    }
  ],
  "usage": { "prompt_tokens": 9, "completion_tokens": 12, "total_tokens": 21 }
}
```

## Next steps

- [Server-Sent Events](https://atptoken.ai/docs/sse-openai/) — Stream this endpoint's response with `stream: true`.
- [OpenAI SDK](https://atptoken.ai/docs/sdk-openai/) — Call this endpoint from the official OpenAI SDK.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means, including a `200` with empty content.
