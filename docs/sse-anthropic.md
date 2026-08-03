# Event sequence for /v1/messages

> Source: https://atptoken.ai/docs/sse-anthropic/

/v1/messages with `stream: true` emits this event sequence regardless of which upstream provider served the request:

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

`stop_reason` maps from the provider: `stop` → `end_turn`, `length` → `max_tokens`.
