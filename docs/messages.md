# /v1/messages

> Source: https://atptoken.ai/docs/messages/

`POST /v1/messages`

`POST /v1/messages` takes Anthropic Messages requests. Use the official `anthropic` SDK (Python or Node) unchanged: set `base_url` to `https://api.atptoken.ai` and pass your ATP key as `api_key`. The SDK sends it as `x-api-key`, which the Gateway accepts.

> **Three things to get right on this endpoint**
>
> 1. `max_tokens` is **required** here — unlike `/v1/chat/completions`. It is the field most often missed when moving from the OpenAI SDK.
> 2. Send the `anthropic-version` header with the value shown in the curl example. The SDK sets it for you.
> 3. `stream` defaults to **`true`** — the opposite of Anthropic's own API. Leave it out and you get SSE instead of one JSON object. Always send `stream` explicitly.

## Request

Use a model id your project allows. Most `claude-*` models are served here and are **not** in `GET /v1/models`; get the full list from [GET /v1/project/models](https://atptoken.ai/docs/models/).

```curl
curl https://api.atptoken.ai/v1/messages \
  -H "x-api-key: $ATP_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model from GET /v1/project/models>",
    "max_tokens": 256,
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key=os.environ["ATP_API_KEY"])
msg = client.messages.create(
    model="<model from GET /v1/project/models>",
    max_tokens=256,
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

```Node.js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ baseURL: "https://api.atptoken.ai", apiKey: process.env.ATP_API_KEY });
const msg = await client.messages.create({
  model: "<model from GET /v1/project/models>",
  max_tokens: 256,
  stream: false,
  messages: [{ role: "user", content: "hi" }],
});
console.log(msg.content[0].text);
```

The Anthropic SDK's `models.list()` calls `/v1/models`. The shape is compatible, so it does not fail — it just returns a shorter list, because most `claude-*` models are missing from it. Use `GET /v1/project/models` instead.

## Parameters

Required: `model`, `max_tokens`, `messages`. The Gateway forwards fields as they are, so one model may accept a field that another rejects.

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id your project allows (see GET /v1/project/models). |
| max_tokens | integer · required | Max output tokens. With extended thinking, the thinking budget counts against it — too low returns a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| messages | array · required | Conversation turns, each { role, content }. `content` is a string or an array of content blocks (`text`, `image`, …). |
| system | string or array | System prompt, as a string or an array of text blocks. Top level — not inside `messages`. |
| stream | boolean | Defaults to `true` on this endpoint. `false` returns one JSON object. |
| temperature / top_p / top_k | number | Sampling. `temperature` is 0–1. |
| stop_sequences | array of strings | Stop sequences. |
| tools / tool_choice | array / object | Tool definitions use `input_schema`, not OpenAI's `function.parameters`. |
| thinking | object | Extended thinking. |
| output_config | object | For example `{"effort": "high"}`. |
| cache_control | object | Top-level form: lands on the last cacheable block automatically. |
| metadata | object | Your own labels. |
| container | object | Execution environment (code execution / Skills). |
| diagnostics | object | Cache diagnostics. |
| inference_geo | string | Inference region. |
| service_tier | string | `auto` or `standard_only`. |

## Tool calls

Tool results go back in a **`user`** message as a `tool_result` block — not as `role: "tool"`. Match them with `tool_use_id`. The model's `tool_use.input` is an object, not a string.

```
{"role": "assistant", "content": [
  {"type": "tool_use", "id": "toolu_abc", "name": "get_weather", "input": {"location": "Paris"}}
]},
{"role": "user", "content": [
  {"type": "tool_result", "tool_use_id": "toolu_abc", "content": "72°F and sunny"}
]}
```

If you send OpenAI's `role: "tool"` here, the Gateway forwards it as is. Some models read it; others return `200` and ignore it. Use this endpoint's own format.

## Prompt caching

Put `cache_control: {"type": "ephemeral"}` on the **last block** of the stable prefix, or put `cache_control` at the top level of the body and it lands on the last cacheable block. For a 1-hour TTL use `{"type": "ephemeral", "ttl": "1h"}`. Check `usage.cache_read_input_tokens` and `usage.cache_creation_input_tokens` to see whether it hit.

Caching matches the prefix in the order `tools` → `system` → `messages`; any byte that changes in the prefix invalidates everything after it. Keep stable content first and per-request values (timestamps, request ids) after the last `cache_control`.

`cache_control` is not allowed on blocks inside `tool_result.content` — put it on the `tool_result` itself, or the request is rejected.

## Count tokens

`POST /v1/messages/count_tokens` takes `messages` (plus optional `model`, `system`, `tools`) and returns `{"input_tokens": <n>}`. It is not billed and does not stream.

## Next steps

- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence you get with `stream: true`
- [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic/) — call this endpoint from the official SDK
- [Error codes](https://atptoken.ai/docs/errors/) — what to check first for each status code
