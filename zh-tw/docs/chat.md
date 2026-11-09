# /v1/chat/completions

> Source: https://atptoken.ai/zh-tw/docs/chat/

`POST /v1/chat/completions`

用官方 `openai` SDK（Python 或 Node）呼叫這個端點，只要換 base URL。Request body 沿用 OpenAI 的 chat completions schema。`model` 必須是這個端點有服務的模型；[GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 列出的就是這些。

> **這裡的 stream 預設是 true**
>
> 在 `/v1/chat/completions`，`stream` 預設是 `true`，和 OpenAI 官方 API 相反。不送的話，你會收到以 `data: [DONE]` 結尾的 SSE，而不是一個 JSON。請一律明確送 `stream`；下面的範例都送 `false`。

## 請求

把 `MODEL_ID` 換成 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的模型 ID。

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

## 參數

必填只有 `model` 和 `messages`。下表是 OpenAI chat completions schema 常用的選填欄位。Gateway 會原樣轉送欄位，所以同一個欄位可能 A 模型收、B 模型拒，不要假設每個欄位每個模型都吃。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 來自 GET /v1/models 的模型 ID。 |
| messages | array · 必填 | 對話訊息，每則為 { role, content }。`role` 可用 `system`、`developer`、`user`、`assistant`、`tool`。`content` 可以是字串，或 part 陣列（`text`、`image_url`、`input_audio`）。 |
| max_completion_tokens | integer | 最大輸出 token 數。`max_tokens` 是舊名，仍可用。reasoning 模型的思考也吃這個額度——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| stream | boolean | 這個端點預設 `true`。送 `false` 會拿到一個 JSON。 |
| stream_options | object | 例如在串流結尾帶 usage。見 [Server-Sent Events](https://atptoken.ai/zh-tw/docs/sse-openai/)。 |
| temperature / top_p | number | 取樣。`temperature` 範圍 0–2。 |
| stop | string or array | 停止序列。 |
| n | integer | 產生幾個候選。 |
| seed | integer | 盡量重現同樣結果。 |
| tools / tool_choice | array / object | 工具定義（`tools[].function.parameters`，JSON Schema）與模型怎麼使用它們。 |
| parallel_tool_calls | boolean | 允許一次呼叫多個工具。 |
| response_format | object | JSON mode 或 JSON schema。 |
| reasoning_effort | string | 思考強度。 |
| logprobs / top_logprobs | boolean / integer | 輸出 token 機率。 |
| frequency_penalty / presence_penalty | number | 重複懲罰，-2.0 到 2.0。 |
| logit_bias | object | 逐 token 偏置。 |
| metadata / user | object / string | 你自己的標記。 |
| audio / modalities | object / array | 語音輸出。 |
| prompt_cache_key | string | 快取分組提示。每個模型都接受，但多數不生效，也沒有回應欄位能告訴你有沒有生效。 |

能不能吃多模態輸入，由各模型決定。這個端點上的模型大多拒絕 `file` 型別的 content part；要傳檔案，見[檔案](https://atptoken.ai/zh-tw/docs/files/)。

## 工具呼叫

Gateway 不會替你執行工具。一輪工具呼叫分三步：

1. 你送 `messages` 和 `tools`，模型回 `tool_calls`。
2. 你在自己的程式裡執行工具。
3. 用 `role: "tool"` 的訊息把結果送回去，以 `tool_call_id` 對應。

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

`arguments` 是 JSON **字串**，不是物件，使用前要先解析。

## 回應

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

`POST /v1/responses` 是同一個 SDK 的另一個入口（OpenAI Responses API），不是另一種模型。body 和 chat completions 不同：

- 用 `input` 取代 `messages`。
- 系統提示放 `instructions`。
- 輸出上限是 `max_output_tokens`。
- function tool 是扁平結構：`{type:"function", name, parameters}`。
- 不保存對話狀態：`store` 和 `previous_response_id` 會被忽略，所以每一輪都要送完整的 `input`。

`/v1/responses` 的 `stream` 預設是 **`false`**，和 `/v1/chat/completions` 相反。程式在兩者之間搬動時，串流行為會不聲不響地反過來，所以兩邊都要明確送 `stream`。

## 最先會遇到的錯誤

開始輸出前，請求依序檢查：模型不在專案允許清單 → `403`；餘額用完 → `402`；此刻沒有可用容量 → `429`。

- 403 — 模型不在專案的允許清單內。不是金鑰或餘額的問題。
- 402 — `insufficient_quota`：餘額用完。不要重試，先儲值。
- 422 — 這個模型不在這個端點服務。訊息會指名正確的端點。
- 429 — 限流，或這個模型此刻沒有可用容量。依 `Retry-After` 等待。

拿到 `200` 不代表模型看到了你送的全部內容：少一則訊息的請求依然合法、依然 `200`。要確認內容真的送到，在訊息裡放一個模型猜不到的值，再請它回答出來。

## 下一步

- [Server-Sent Events](https://atptoken.ai/zh-tw/docs/sse-openai/) — 用 `stream: true` 串流這個端點的回應。
- [OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai/) — 從官方 OpenAI SDK 呼叫這個端點。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼，包括內容為空的 `200`。
