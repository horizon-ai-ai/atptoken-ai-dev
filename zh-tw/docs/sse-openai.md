# Server-Sent Events

> Source: https://atptoken.ai/zh-tw/docs/sse-openai/

當你在 /v1/chat/completions 設定 `stream: true`，Gateway 會把上游供應商回應以 OpenAI 格式的 SSE chunk 串流出來。

## 請求

加上 `"stream": true`。curl 要加 `-N`，輸出才不會被緩衝。

```curl
curl -N https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}],
    "stream": true
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
stream = client.chat.completions.create(
    model="MODEL_ID",
    messages=[{"role": "user", "content": "hi"}],
    stream=True,
)
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const stream = await client.chat.completions.create({
  model: "MODEL_ID",
  messages: [{ role: "user", content: "hi" }],
  stream: true,
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? "");
}
```

## 用量與串流結束

最後一個 chunk 含 `usage` 物件；串流以 `data: [DONE]` 結束。

## 下一步

- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 產生這個串流的端點與請求欄位
- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — /v1/messages 的事件序列
- [OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai/) — 用官方 SDK 串流
