# /v1/messages

> Source: https://atptoken.ai/zh-tw/docs/messages/

`POST /v1/messages`

Anthropic Messages 請求會被 Gateway 接受並正規化。最上層的 `system` 欄位必須是 **字串**。Anthropic cache_control 功能用的陣列形式尚未支援 — 送陣列會回傳 400 `invalid_request_error`。`anthropic-version` header 會被接受並原樣轉送。

| Field | Type | Description |
|---|---|---|
| model | string · required | 來自 GET /v1/models 的 model id。 |
| max_tokens | integer · required | 最大輸出 token 數（Anthropic 必填）。開 extended thinking 時思考預算也算在內——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| messages | array · required | 對話輪次，每則為 { role, content }。 |
| system | string | System prompt。必須是字串，不能是陣列。 |
| temperature | number | 取樣溫度，0–1。 |
| stream | boolean | 以 Anthropic SSE 事件串流。 |

#### Request

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
