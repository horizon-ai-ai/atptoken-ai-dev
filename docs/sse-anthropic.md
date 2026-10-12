# Event sequence for /v1/messages

> Source: https://atptoken.ai/docs/sse-anthropic/

/v1/messages with `stream: true` emits the event sequence below regardless of which upstream provider served the request.

## Request

Set `stream: true` on [/v1/messages](https://atptoken.ai/docs/messages/).

```curl
curl -N https://api.atptoken.ai/v1/messages \
  -H "Authorization: Bearer atp-..." \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-haiku-4-5",
    "max_tokens": 256,
    "stream": true,
    "messages": [{ "role": "user", "content": "Say hi in 3 words" }]
  }'
```

```Python
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")

with client.messages.stream(
    model="claude-haiku-4-5",
    max_tokens=256,
    messages=[{"role": "user", "content": "Say hi in 3 words"}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
    final = stream.get_final_message()
print("\n", final.usage)
```

```Node.js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ baseURL: "https://api.atptoken.ai", apiKey: "atp-..." });

const stream = client.messages.stream({
  model: "claude-haiku-4-5",
  max_tokens: 256,
  messages: [{ role: "user", content: "Say hi in 3 words" }],
});
stream.on("text", (text) => process.stdout.write(text));
const final = await stream.finalMessage();
console.log("\n", final.usage);
```

## Event sequence

```
event: message_start
data: {"type":"message_start","message":{...}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

# one per delta:
event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"..."}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":N}}

event: message_stop
data: {"type":"message_stop"}
```

`ping` events can arrive anywhere in the stream (usually right after `message_start` and after `content_block_start`). They carry no data — skip them.

### Events

| Event | When | What to read |
| --- | --- | --- |
| `message_start` | once, first | `message.id`, `message.model`. Usage here is **not final**. |
| `ping` | any time | nothing — ignore it |
| `content_block_start` | once per content block | `index`, `content_block.type` (`text` or `tool_use`); for tools also the tool id and name |
| `content_block_delta` | many per block | `delta.text` (`text_delta`) or `delta.partial_json` (`input_json_delta`) |
| `content_block_stop` | once per block | the block at `index` is complete |
| `message_delta` | once, near the end | `delta.stop_reason`, and `usage` with the final `input_tokens` and `output_tokens` |
| `message_stop` | once, last | the stream is done |

## Response

A complete response from `claude-haiku-4-5`:

```
event: message_start
data: {"message":{"id":"01M3F85T5YV4BEGMA014TVTC9E","type":"message","usage":{"input_tokens":32,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"cache_creation":{"ephemeral_1h_input_tokens":0,"ephemeral_5m_input_tokens":0},"output_tokens":1},"role":"assistant","content":[],"model":"claude-haiku-4-5-20251001","stop_sequence":null,"stop_reason":null},"type":"message_start"}

event: ping
data: {"type":"ping"}

event: content_block_start
data: {"index":0,"type":"content_block_start","content_block":{"type":"text","text":""}}

event: ping
data: {"type":"ping"}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"text_delta","text":"Hi there"}}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"text_delta","text":" friend!"}}

event: content_block_stop
data: {"index":0,"type":"content_block_stop"}

event: message_delta
data: {"type":"message_delta","usage":{"input_tokens":32,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":7},"delta":{"stop_sequence":null,"stop_reason":"end_turn"}}

event: message_stop
data: {"type":"message_stop"}
```

## Read usage from message_delta

Always take token counts from `message_delta`, not `message_start`. The usage in `message_start` is not final; `message_delta` carries the final `input_tokens` and `output_tokens`.

## Tool use

When the model calls a tool, the block starts as `tool_use` with an empty `input`, and the arguments arrive as JSON fragments in `input_json_delta` events. Concatenate every `partial_json` for that `index` and parse the result once at `content_block_stop`. The first fragment can be an empty string.

```
event: ping
data: {"type":"ping"}

event: content_block_start
data: {"index":0,"type":"content_block_start","content_block":{"id":"toolu_01PGo2evEeMN4XS8geMjN7Vs","input":{},"name":"get_weather","type":"tool_use"}}

event: ping
data: {"type":"ping"}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":""}}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"{\"city\": "}}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"\"Taipe"}}

event: content_block_delta
data: {"index":0,"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"i\"}"}}

event: content_block_stop
data: {"index":0,"type":"content_block_stop"}

event: message_delta
data: {"type":"message_delta","usage":{"input_tokens":672,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":39},"delta":{"stop_sequence":null,"stop_reason":"tool_use"}}
```

Treat the tool call `id` (for example `toolu_…`) as opaque. Send it back unchanged as `tool_use_id` in your `tool_result`.

## Stop reasons

| Value | Meaning |
| --- | --- |
| `end_turn` | the model finished its answer |
| `max_tokens` | output hit `max_tokens`; the text is cut off |
| `tool_use` | the model wants you to run a tool and send the result back |

`stop_reason` maps from the provider: `stop` → `end_turn`, `length` → `max_tokens`.

## Errors

Errors found before streaming starts come back as a normal JSON response with an HTTP status and no event stream. Check the status (or `Content-Type: text/event-stream`) before you start reading events.

- 401 — no key or an invalid key. The body is `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}`, with no `error` object, so handle both shapes.
- 402 — `insufficient_quota`: project balance ≤ 0.
- 403 — `permission_denied`: the model is not enabled for this project, or does not exist.

If the connection closes before `message_stop`, treat the response as incomplete. See [Error codes](https://atptoken.ai/docs/errors/) for retry guidance.

## Next steps

- [/v1/messages](https://atptoken.ai/docs/messages/) — request fields for the endpoint that produces this stream
- [OpenAI SSE](https://atptoken.ai/docs/sse-openai/) — the chunk format on /v1/chat/completions
- [Error codes](https://atptoken.ai/docs/errors/) — what to check first for each status code
