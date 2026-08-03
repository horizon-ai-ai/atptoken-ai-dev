# /v1/messages

> Source: https://atptoken.ai/zh-cn/docs/messages/

`POST /v1/messages`

Anthropic Messages 请求会被 Gateway 接受并正规化。最上层的 `system` 栏位必须是 **字串**。Anthropic cache_control 功能用的阵列形式尚未支援 — 送阵列会回传 400 `invalid_request_error`。`anthropic-version` header 会被接受并原样转送。

| Field | Type | Description |
|---|---|---|
| model | string · required | 来自 GET /v1/models 的 model id。 |
| max_tokens | integer · required | 最大输出 token 数（Anthropic 必填）。开 extended thinking 时思考预算也算在内——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| messages | array · required | 对话轮次，每则为 { role, content }。 |
| system | string | System prompt。必须是字串，不能是阵列。 |
| temperature | number | 取样温度，0–1。 |
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
