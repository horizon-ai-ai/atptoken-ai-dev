# /v1/chat/completions

> Source: https://atptoken.ai/zh-tw/docs/chat/

`POST /v1/chat/completions`

用任何 OpenAI SDK 呼叫這個端點。Request body 完全沿用 OpenAI 的 chat completions schema。`model` 欄位必須是 `GET /v1/models` 回傳的值。

## 請求

把 `MODEL_ID` 換成 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的模型 ID。

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

## 參數

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 來自 GET /v1/models 的模型 ID。 |
| messages | array · 必填 | 對話訊息，每則為 { role, content }。 |
| max_tokens | integer | 最大輸出 token 數。reasoning 模型的思考也吃這個額度——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| temperature | number | 取樣溫度，0–2。 |
| stream | boolean | 以 SSE chunk 串流回應。 |
| tools | array | Tool/function 定義（OpenAI tool schema）。 |

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

## 下一步

- [Server-Sent Events](https://atptoken.ai/zh-tw/docs/sse-openai/) — 用 `stream: true` 串流這個端點的回應。
- [OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai/) — 從官方 OpenAI SDK 呼叫這個端點。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼，包括內容為空的 `200`。
