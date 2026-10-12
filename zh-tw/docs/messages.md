# /v1/messages

> Source: https://atptoken.ai/zh-tw/docs/messages/

`POST /v1/messages`

Anthropic Messages 請求會被 Gateway 接受並正規化。

## 請求

`anthropic-version` header 會被接受並原樣轉送。

```curl
curl https://api.atptoken.ai/v1/messages \
  -H "Authorization: Bearer atp-..." \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model from GET /v1/models>",
    "max_tokens": 256,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/models>",
    max_tokens=256,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

```Node.js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ baseURL: "https://api.atptoken.ai", apiKey: "atp-..." });
const msg = await client.messages.create({
  model: "<model from GET /v1/models>",
  max_tokens: 256,
  messages: [{ role: "user", content: "hi" }],
});
console.log(msg.content[0].text);
```

## 參數

最上層的 `system` 欄位可以是字串，也可以是文字區塊陣列（區塊上的 `cache_control` 會被接受）。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 來自 GET /v1/models 的模型 ID。 |
| max_tokens | integer · 必填 | 最大輸出 token 數（Anthropic 必填）。開 extended thinking 時思考預算也算在內——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| messages | array · 必填 | 對話輪次，每則為 { role, content }。 |
| system | string or array | System prompt，字串或文字區塊陣列皆可。 |
| temperature | number | 取樣溫度，0–1。 |
| stream | boolean | 以 Anthropic SSE 事件串流。 |

## 下一步

- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — 帶 `stream: true` 時收到的事件序列
- [Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic/) — 用官方 SDK 呼叫這個端點
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼先檢查什麼
