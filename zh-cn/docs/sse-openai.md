# Server-Sent Events

> Source: https://atptoken.ai/zh-cn/docs/sse-openai/

当你在 /v1/chat/completions 设定 `stream: true`，Gateway 会把上游供应商回应以 OpenAI 格式的 SSE chunk 串流出来。

## 请求

加上 `"stream": true`。curl 要加 `-N`，输出才不会被缓冲。

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

## 用量与串流结束

最后一个 chunk 含 `usage` 物件；串流以 `data: [DONE]` 结束。

## 下一步

- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 产生这个串流的端点与请求栏位
- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — /v1/messages 的事件序列
- [OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai/) — 用官方 SDK 串流
