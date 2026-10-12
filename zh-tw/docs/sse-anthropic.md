# /v1/messages 的事件序列

> Source: https://atptoken.ai/zh-tw/docs/sse-anthropic/

/v1/messages 帶 `stream: true` 時，不論由哪個上游供應商服務，都會發出下方的事件序列。

## 請求

在 [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) 設 `stream: true`。

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

`ping` 事件可能出現在串流的任何位置（通常緊接在 `message_start` 和 `content_block_start` 之後），不帶任何資料，略過即可。

### 事件

| 事件 | 何時出現 | 要讀什麼 |
| --- | --- | --- |
| `message_start` | 一次，最先 | `message.id`、`message.model`。這裡的用量**不是最終值**。 |
| `ping` | 任何時候 | 沒有內容，略過 |
| `content_block_start` | 每個內容區塊一次 | `index`、`content_block.type`（`text` 或 `tool_use`）；工具區塊還有工具的 id 與名稱 |
| `content_block_delta` | 每個區塊多次 | `delta.text`（`text_delta`）或 `delta.partial_json`（`input_json_delta`） |
| `content_block_stop` | 每個區塊一次 | `index` 這個區塊已完整 |
| `message_delta` | 一次，接近結尾 | `delta.stop_reason`，以及帶最終 `input_tokens`、`output_tokens` 的 `usage` |
| `message_stop` | 一次，最後 | 串流結束 |

## 回應

`claude-haiku-4-5` 的完整回應：

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

## 用量請讀 message_delta

token 數一律從 `message_delta` 取，不要用 `message_start`。`message_start` 的用量不是最終值；最終的 `input_tokens` 與 `output_tokens` 在 `message_delta`。

## Tool use

模型呼叫工具時，區塊以 `tool_use` 開始、`input` 是空的，參數則以 JSON 片段分散在 `input_json_delta` 事件中。把同一個 `index` 的所有 `partial_json` 接起來，在 `content_block_stop` 時一次解析。第一個片段可能是空字串。

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

工具呼叫的 `id`（例如 `toolu_…`）請當成不透明字串，在 `tool_result` 裡以 `tool_use_id` 原樣送回。

## 停止原因

| 值 | 意義 |
| --- | --- |
| `end_turn` | 模型回答完畢 |
| `max_tokens` | 輸出達到 `max_tokens`，內容被截斷 |
| `tool_use` | 模型要你執行工具並送回結果 |

`stop_reason` 依供應商對應：`stop` → `end_turn`，`length` → `max_tokens`。

## 錯誤

串流開始前就發現的錯誤，會以一般 JSON 回應加上 HTTP 狀態碼回傳，不會有事件串流。開始讀事件前，請先檢查狀態碼（或 `Content-Type: text/event-stream`）。

- 401 — 沒帶金鑰或金鑰無效。回應內容是 `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}`，沒有 `error` 物件，兩種格式都要處理。
- 402 — `insufficient_quota`：專案餘額 ≤ 0。
- 403 — `permission_denied`：這個專案沒開放該模型，或模型不存在。

如果連線在 `message_stop` 之前就中斷，請把回應視為不完整。重試建議見[錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) — 產生這個串流的端點與請求欄位
- [OpenAI SSE](https://atptoken.ai/zh-tw/docs/sse-openai/) — /v1/chat/completions 的串流區塊格式
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼先檢查什麼
