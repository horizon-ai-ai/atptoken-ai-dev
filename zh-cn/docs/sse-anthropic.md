# /v1/messages 的事件序列

> Source: https://atptoken.ai/zh-cn/docs/sse-anthropic/

/v1/messages 带 `stream: true` 时，不论由哪个上游供应商服务，都会发出下方的事件序列。

## 请求

在 [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) 设 `stream: true`。

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

## 事件序列

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

`ping` 事件可能出现在串流的任何位置（通常紧接在 `message_start` 和 `content_block_start` 之后），不带任何数据，略过即可。

### 事件

| 事件 | 何时出现 | 要读什么 |
| --- | --- | --- |
| `message_start` | 一次，最先 | `message.id`、`message.model`。这里的用量**不是最终值**。 |
| `ping` | 任何时候 | 没有内容，略过 |
| `content_block_start` | 每个内容区块一次 | `index`、`content_block.type`（`text` 或 `tool_use`）；工具区块还有工具的 id 与名称 |
| `content_block_delta` | 每个区块多次 | `delta.text`（`text_delta`）或 `delta.partial_json`（`input_json_delta`） |
| `content_block_stop` | 每个区块一次 | `index` 这个区块已完整 |
| `message_delta` | 一次，接近结尾 | `delta.stop_reason`，以及带最终 `input_tokens`、`output_tokens` 的 `usage` |
| `message_stop` | 一次，最后 | 串流结束 |

## 回应

`claude-haiku-4-5` 的完整回应：

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

## 用量请读 message_delta

token 数一律从 `message_delta` 取，不要用 `message_start`。`message_start` 的用量不是最终值；最终的 `input_tokens` 与 `output_tokens` 在 `message_delta`。

## Tool use

模型呼叫工具时，区块以 `tool_use` 开始、`input` 是空的，参数则以 JSON 片段分散在 `input_json_delta` 事件中。把同一个 `index` 的所有 `partial_json` 接起来，在 `content_block_stop` 时一次解析。第一个片段可能是空字串。

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

工具呼叫的 `id`（例如 `toolu_…`）请当成不透明字串，在 `tool_result` 里以 `tool_use_id` 原样送回。

## 停止原因

| 值 | 意义 |
| --- | --- |
| `end_turn` | 模型回答完毕 |
| `max_tokens` | 输出达到 `max_tokens`，内容被截断 |
| `tool_use` | 模型要你执行工具并送回结果 |

`stop_reason` 依供应商对应：`stop` → `end_turn`，`length` → `max_tokens`。

## 错误

串流开始前就发现的错误，会以一般 JSON 回应加上 HTTP 状态码回传，不会有事件串流。开始读事件前，请先检查状态码（或 `Content-Type: text/event-stream`）。

- 401 — 没带密钥或密钥无效。回应内容是 `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}`，没有 `error` 物件，两种格式都要处理。
- 402 — `insufficient_quota`：项目余额 ≤ 0。
- 403 — `permission_denied`：这个项目没开放该模型，或模型不存在。

如果连线在 `message_stop` 之前就中断，请把回应视为不完整。重试建议见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 产生这个串流的端点与请求栏位
- [OpenAI SSE](https://atptoken.ai/zh-cn/docs/sse-openai/) — /v1/chat/completions 的串流区块格式
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么
