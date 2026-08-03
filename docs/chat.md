# /v1/chat/completions

> Source: https://atptoken.ai/docs/chat/

`POST /v1/chat/completions`

Use this endpoint with any OpenAI SDK client. The request body follows OpenAI's chat completions schema unchanged. The `model` field must be a value returned by `GET /v1/models`.

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id from GET /v1/models. |
| messages | array · required | Chat messages, each { role, content }. |
| max_tokens | integer | Max output tokens. Reasoning models spend their thinking inside this budget — set it too low and you get a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| temperature | number | Sampling temperature, 0–2. |
| stream | boolean | Stream the response as SSE chunks. |
| tools | array | Tool/function definitions (OpenAI tool schema). |

#### Response

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
