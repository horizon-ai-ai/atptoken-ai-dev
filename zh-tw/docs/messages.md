# /v1/messages

> Source: https://atptoken.ai/zh-tw/docs/messages/

`POST /v1/messages`

`POST /v1/messages` 接受 Anthropic Messages 請求。官方 `anthropic` SDK（Python 或 Node）不用改：把 `base_url` 設成 `https://api.atptoken.ai`，`api_key` 直接填 ATP 金鑰。SDK 會用 `x-api-key` 送出，Gateway 接受這個 header。

> **這個端點有三件事一定要對**
>
> 1. `max_tokens` 在這裡是**必填**，`/v1/chat/completions` 不是。從 OpenAI SDK 搬過來最常漏這個。
> 2. 要帶 `anthropic-version` header，值照下面 curl 範例。用 SDK 會自動帶。
> 3. `stream` 預設是 **`true`**，和 Anthropic 官方 API 相反。不送的話會收到 SSE，而不是一個 JSON。請一律明確送 `stream`。

## 請求

用專案開放的模型 ID。大部分 `claude-*` 模型在這裡服務，**不在** `GET /v1/models` 裡；完整清單請用 [GET /v1/project/models](https://atptoken.ai/zh-tw/docs/models/)。

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

Anthropic SDK 的 `models.list()` 會去打 `/v1/models`。格式相容，所以不會報錯，只是清單比較短：大部分 `claude-*` 模型不在裡面。請改用 `GET /v1/project/models`。

## 參數

必填：`model`、`max_tokens`、`messages`。Gateway 會原樣轉送欄位，所以同一個欄位可能 A 模型收、B 模型拒。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 專案開放的模型 ID（見 GET /v1/project/models）。 |
| max_tokens | integer · 必填 | 最大輸出 token 數。開 extended thinking 時思考預算也算在內——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| messages | array · 必填 | 對話輪次，每則為 { role, content }。`content` 可以是字串，或內容區塊陣列（`text`、`image` 等）。 |
| system | string or array | 系統提示，字串或文字區塊陣列皆可。放在最上層，不放在 `messages` 裡。 |
| stream | boolean | 這個端點預設 `true`。送 `false` 會拿到一個 JSON。 |
| temperature / top_p / top_k | number | 取樣。`temperature` 範圍 0–1。 |
| stop_sequences | array of strings | 停止序列。 |
| tools / tool_choice | array / object | 工具定義用 `input_schema`，不是 OpenAI 的 `function.parameters`。 |
| thinking | object | 延伸思考（extended thinking）。 |
| output_config | object | 例如 `{"effort": "high"}`。 |
| cache_control | object | 放在最上層時，會自動落在最後一個可快取的區塊上。 |
| metadata | object | 你自己的標記。 |
| container | object | 執行環境（程式碼執行 / Skills）。 |
| diagnostics | object | 快取診斷。 |
| inference_geo | string | 指定推論地區。 |
| service_tier | string | `auto` 或 `standard_only`。 |

## 工具呼叫

工具結果要放在 **`user`** 訊息裡，用 `tool_result` 區塊送回，不是 `role: "tool"`。以 `tool_use_id` 對應。模型回的 `tool_use.input` 是物件，不是字串。

```
{"role": "assistant", "content": [
  {"type": "tool_use", "id": "toolu_abc", "name": "get_weather", "input": {"location": "Paris"}}
]},
{"role": "user", "content": [
  {"type": "tool_result", "tool_use_id": "toolu_abc", "content": "72°F and sunny"}
]}
```

如果在這裡送 OpenAI 的 `role: "tool"`，Gateway 會原樣轉送。有的模型讀得到，有的回 `200` 卻當作沒收到。請用這個端點自己的寫法。

## 提示快取

把 `cache_control: {"type": "ephemeral"}` 放在穩定前綴的**最後一個區塊**上；或把 `cache_control` 放在 body 最上層，它會自動落在最後一個可快取的區塊。要 1 小時 TTL 就用 `{"type": "ephemeral", "ttl": "1h"}`。有沒有命中，看 `usage.cache_read_input_tokens` 和 `usage.cache_creation_input_tokens`。

快取是比對前綴，順序是 `tools` → `system` → `messages`；前綴裡任何一個 byte 變了，後面全部失效。穩定的內容放前面，每次都變的（時間戳、逐請求 id）放在最後一個 `cache_control` 之後。

`cache_control` 不能放在 `tool_result.content` 裡的區塊上，要放就放在 `tool_result` 本身，否則請求會被拒絕。

## 計算 token

`POST /v1/messages/count_tokens` 收 `messages`（可選 `model`、`system`、`tools`），回 `{"input_tokens": <n>}`。不計費，也不串流。

## 下一步

- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — 帶 `stream: true` 時收到的事件序列
- [Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic/) — 用官方 SDK 呼叫這個端點
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼先檢查什麼
