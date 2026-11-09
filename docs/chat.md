# /v1/chat/completions

> Source: https://atptoken.ai/docs/chat/

`POST /v1/chat/completions`

Use this endpoint with the official `openai` SDK (Python or Node) — only the base URL changes. The request body follows OpenAI's chat completions schema. The `model` must be one this endpoint serves: [GET /v1/models](https://atptoken.ai/docs/models/) lists exactly those.

> **stream defaults to true here**
>
> On `/v1/chat/completions`, `stream` defaults to `true` — the opposite of OpenAI's own API. Leave it out and you get SSE ending in `data: [DONE]` instead of one JSON object. Always send `stream` explicitly; the examples below send `false`.

## Request

Replace `MODEL_ID` with a model id from [GET /v1/models](https://atptoken.ai/docs/models/).

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.chat.completions.create(
    model="MODEL_ID",
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.chat.completions.create({
  model: "MODEL_ID",
  stream: false,
  messages: [{ role: "user", content: "hi" }],
});
console.log(r.choices[0].message.content);
```

## Parameters

Only `model` and `messages` are required. The table lists the common optional fields of OpenAI's chat completions schema. The Gateway forwards fields as they are, so one model may accept a field that another rejects — do not assume every field works on every model.

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id from GET /v1/models. |
| messages | array · required | Chat messages, each { role, content }. `role` is `system`, `developer`, `user`, `assistant` or `tool`. `content` is a string or an array of parts (`text`, `image_url`, `input_audio`). |
| max_completion_tokens | integer | Max output tokens. `max_tokens` is the older name and still works. Reasoning models spend their thinking inside this budget — set it too low and you get a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| stream | boolean | Defaults to `true` on this endpoint. `false` returns one JSON object. |
| stream_options | object | For example, usage at the end of the stream. See [Server-Sent Events](https://atptoken.ai/docs/sse-openai/). |
| temperature / top_p | number | Sampling. `temperature` is 0–2. |
| stop | string or array | Stop sequences. |
| n | integer | How many candidates to generate. |
| seed | integer | Best-effort reproducibility. |
| tools / tool_choice | array / object | Tool definitions (`tools[].function.parameters`, a JSON Schema) and how the model may use them. |
| parallel_tool_calls | boolean | Allow several tool calls at once. |
| response_format | object | JSON mode or JSON schema. |
| reasoning_effort | string | How hard the model thinks. |
| logprobs / top_logprobs | boolean / integer | Token probabilities. |
| frequency_penalty / presence_penalty | number | Repetition penalties, -2.0 to 2.0. |
| logit_bias | object | Per-token bias. |
| metadata / user | object / string | Your own labels. |
| audio / modalities | object / array | Audio output. |
| prompt_cache_key | string | Cache grouping hint. Every model accepts it, but on most it has no effect, and no response field tells you whether it worked. |

Multimodal input is set per model. Most models on this endpoint reject a `file` content part; for files, see [Files](https://atptoken.ai/docs/files/).

## Tool calls

The Gateway does not run your tools. A tool round has three steps:

1. You send `messages` and `tools`; the model answers with `tool_calls`.
2. You run the tool in your own code.
3. You send the result back as a `role: "tool"` message, matched by `tool_call_id`.

```
"messages": [
  {"role": "user", "content": "What is 2+2? Use the calc tool."},
  {"role": "assistant", "tool_calls": [
    {"id": "call_1", "type": "function",
     "function": {"name": "calc", "arguments": "{\"expr\":\"2+2\"}"}}
  ]},
  {"role": "tool", "tool_call_id": "call_1", "content": "4"}
]
```

`arguments` is a JSON **string**, not an object — parse it before you use it.

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

## /v1/responses

`POST /v1/responses` is the same SDK's other entry point (the OpenAI Responses API), not a different model family. The body differs from chat completions:

- `input` instead of `messages`.
- `instructions` for the system prompt.
- `max_output_tokens` for the output limit.
- Flat function tools: `{type:"function", name, parameters}`.
- Stateless: `store` and `previous_response_id` are ignored, so send the full `input` every turn.

`stream` defaults to **`false`** on `/v1/responses` — the opposite of `/v1/chat/completions`. Moving code between the two silently flips streaming, so send `stream` explicitly on both.

## Errors you will see first

A request is checked in this order before any output starts: the model is not on your project's allowed list → `403`; your balance is used up → `402`; no capacity right now → `429`.

- 403 — The model is not on your project's allowed list. Not a key or balance problem.
- 402 — `insufficient_quota`: your balance is used up. Do not retry; add credits first.
- 422 — This model is not served on this endpoint. The message names the endpoint that serves it.
- 429 — Rate limited, or no capacity for this model right now. Follow `Retry-After`.

A `200` does not prove the model saw everything you sent: a request missing a message is still valid and still `200`. To confirm content arrived, put a value the model cannot guess in the message and ask for it back.

## Next steps

- [Server-Sent Events](https://atptoken.ai/docs/sse-openai/) — Stream this endpoint's response with `stream: true`.
- [OpenAI SDK](https://atptoken.ai/docs/sdk-openai/) — Call this endpoint from the official OpenAI SDK.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means, including a `200` with empty content.
