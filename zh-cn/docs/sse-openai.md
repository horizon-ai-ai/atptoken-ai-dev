# Server-Sent Events

> Source: https://atptoken.ai/zh-cn/docs/sse-openai/

当你在 /v1/chat/completions 设定 `stream: true`，Gateway 会把上游供应商回应以 OpenAI 格式的 SSE chunk 串流出来。

## 请求

加上 `"stream": true`。在 `/v1/chat/completions` 这本来就是默认，但还是要明确送：`/v1/responses` 默认是 `false`，程式在两者之间搬动时，串流行为会不声不响地反过来。curl 要加 `-N`，输出才不会被缓冲。

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

每个 chunk 带的是增量的 `delta`。串流以 `data: [DONE]` 结束，请等这一行。

只要是串流请求，Gateway 一律会向上游送 `stream_options: {"include_usage": true}`，就算你没写也一样，因为计费需要 token 数。所以串流尾端、`data: [DONE]` 之前，一定会多一个带 `usage` 的 chunk。你自己送 `stream_options` 也没关系。

```
data: {"choices":[{"delta":{"content":"Hel"}}],…}
data: {"choices":[{"delta":{"content":"lo"}}],…}
data: [DONE]
```

## 串流开始前的错误

送出任何 chunk 之前，请求会先依序检查：模型不在项目允许清单 → `403`；余额用完 → `402`；此刻没有可用容量 → `429`。这些会以一般 JSON 错误加上 HTTP 状态码回传，不会有串流，所以读 chunk 前先检查状态码。见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## /v1/responses 的串流格式不同

`/v1/responses` 用具名事件（`event: <type>` 加 `data: {...}`），每个事件带递增的 `sequence_number`。

- 文字在 `response.output_text.delta` 事件里。
- 串流以 `response.completed` 结束，里面有完整的 `output[]` 和 `usage`。
- 如果答案被 `max_output_tokens` 截断，`response.completed` 的 `status` 会是 `"incomplete"`。

## 下一步

- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 产生这个串流的端点与请求栏位
- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — /v1/messages 的事件序列
- [OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai/) — 用官方 SDK 串流
