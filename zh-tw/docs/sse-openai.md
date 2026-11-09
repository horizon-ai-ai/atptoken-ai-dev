# Server-Sent Events

> Source: https://atptoken.ai/zh-tw/docs/sse-openai/

當你在 /v1/chat/completions 設定 `stream: true`，Gateway 會把上游供應商回應以 OpenAI 格式的 SSE chunk 串流出來。

## 請求

加上 `"stream": true`。在 `/v1/chat/completions` 這本來就是預設，但還是要明確送：`/v1/responses` 預設是 `false`，程式在兩者之間搬動時，串流行為會不聲不響地反過來。curl 要加 `-N`，輸出才不會被緩衝。

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

每個 chunk 帶的是增量的 `delta`。串流以 `data: [DONE]` 結束，請等這一行。

只要是串流請求，Gateway 一律會向上游送 `stream_options: {"include_usage": true}`，就算你沒寫也一樣，因為計費需要 token 數。所以串流尾端、`data: [DONE]` 之前，一定會多一個帶 `usage` 的 chunk。你自己送 `stream_options` 也沒關係。

```
data: {"choices":[{"delta":{"content":"Hel"}}],…}
data: {"choices":[{"delta":{"content":"lo"}}],…}
data: [DONE]
```

## 串流開始前的錯誤

送出任何 chunk 之前，請求會先依序檢查：模型不在專案允許清單 → `403`；餘額用完 → `402`；此刻沒有可用容量 → `429`。這些會以一般 JSON 錯誤加上 HTTP 狀態碼回傳，不會有串流，所以讀 chunk 前先檢查狀態碼。見[錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## /v1/responses 的串流格式不同

`/v1/responses` 用具名事件（`event: <type>` 加 `data: {...}`），每個事件帶遞增的 `sequence_number`。

- 文字在 `response.output_text.delta` 事件裡。
- 串流以 `response.completed` 結束，裡面有完整的 `output[]` 和 `usage`。
- 如果答案被 `max_output_tokens` 截斷，`response.completed` 的 `status` 會是 `"incomplete"`。

## 下一步

- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 產生這個串流的端點與請求欄位
- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — /v1/messages 的事件序列
- [OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai/) — 用官方 SDK 串流
