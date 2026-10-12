# /v1/chat/completions

> Source: https://atptoken.ai/zh-cn/docs/chat/

`POST /v1/chat/completions`

用任何 OpenAI SDK 呼叫这个端点。Request body 完全沿用 OpenAI 的 chat completions schema。`model` 栏位必须是 `GET /v1/models` 回传的值。

## 请求

把 `MODEL_ID` 换成 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的模型 ID。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.chat.completions.create(
    model="MODEL_ID",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.chat.completions.create({
  model: "MODEL_ID",
  messages: [{ role: "user", content: "hi" }],
});
console.log(r.choices[0].message.content);
```

## 参数

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 来自 GET /v1/models 的模型 ID。 |
| messages | array · 必填 | 对话消息，每则为 { role, content }。 |
| max_tokens | integer | 最大输出 token 数。reasoning 模型的思考也吃这个额度——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| temperature | number | 取样温度，0–2。 |
| stream | boolean | 以 SSE chunk 串流回应。 |
| tools | array | Tool/function 定义（OpenAI tool schema）。 |

## 回应

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

## 下一步

- [Server-Sent Events](https://atptoken.ai/zh-cn/docs/sse-openai/) — 用 `stream: true` 串流这个端点的回应。
- [OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai/) — 从官方 OpenAI SDK 呼叫这个端点。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么，包括内容为空的 `200`。
