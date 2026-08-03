# /v1/messages 的事件序列

> Source: https://atptoken.ai/zh-cn/docs/sse-anthropic/

/v1/messages 带 `stream: true` 时，不论由哪个上游 provider 服务，都会发出以下事件序列：

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

`stop_reason` 依 provider 对应：`stop` → `end_turn`，`length` → `max_tokens`。
