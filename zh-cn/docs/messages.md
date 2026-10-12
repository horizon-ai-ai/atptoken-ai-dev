# /v1/messages

> Source: https://atptoken.ai/zh-cn/docs/messages/

`POST /v1/messages`

Anthropic Messages 请求会被 Gateway 接受并正规化。

## 请求

`anthropic-version` header 会被接受并原样转送。

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

## 参数

最上层的 `system` 栏位可以是字串，也可以是文字区块阵列（区块上的 `cache_control` 会被接受）。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 来自 GET /v1/models 的模型 ID。 |
| max_tokens | integer · 必填 | 最大输出 token 数（Anthropic 必填）。开 extended thinking 时思考预算也算在内——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| messages | array · 必填 | 对话轮次，每则为 { role, content }。 |
| system | string or array | System prompt，字串或文字区块阵列皆可。 |
| temperature | number | 取样温度，0–1。 |
| stream | boolean | 以 Anthropic SSE 事件串流。 |

## 下一步

- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — 带 `stream: true` 时收到的事件序列
- [Anthropic SDK](https://atptoken.ai/zh-cn/docs/sdk-anthropic/) — 用官方 SDK 呼叫这个端点
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么
