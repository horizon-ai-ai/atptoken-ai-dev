# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/zh-cn/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST 风格的 `generateContent` 与 `streamGenerateContent` 路由，在 `/v1` 与 `/v1beta`（Google GenAI SDK 默认）底下皆支持。以 `x-goog-api-key` 验证——这是 SDK 的默认。

## 路由

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/v1beta/models/{model}:generateContent` | 一次回应；SDK 默认的前缀 |
| POST | `/v1beta/models/{model}:streamGenerateContent` | Server-Sent Events |
| POST | `/v1/models/{model}:generateContent` | 同 `/v1beta` |
| POST | `/v1/models/{model}:streamGenerateContent` | 同 `/v1beta` |

`{model}` 是 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的 id，例如 `gemini-3-5-flash-lite`。

## 验证

三种方式都可以用，依你的客户端默认即可。见[验证方式](https://atptoken.ai/zh-cn/docs/auth/)。

| 方式 | 范例 |
| --- | --- |
| `x-goog-api-key` header | `x-goog-api-key: atp-...`——Google GenAI SDK 的默认 |
| `key` query 参数 | `…:generateContent?key=atp-...`——log 会遮蔽，但仍建议用 header |
| Bearer header | `Authorization: Bearer atp-...` |

## 请求

```curl
curl "https://api.atptoken.ai/v1/models/<model>:generateContent" \
  -H "x-goog-api-key: atp-..." \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{ "parts": [{ "text": "hi" }] }]
  }'
```

```Python
from google import genai

client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai"},
)
r = client.models.generate_content(
    model="<model from GET /v1/models>",
    contents="hi",
)
print(r.text)
```

```Node.js
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: "atp-...",
  httpOptions: { baseUrl: "https://api.atptoken.ai" },
});
const r = await ai.models.generateContent({
  model: "<model from GET /v1/models>",
  contents: "hi",
});
console.log(r.text);
```

`contents`、`systemInstruction` 与 `generationConfig`（例如 `maxOutputTokens`、`temperature`）都使用 Gemini 的栏位名称。

## 回应

#### 回应

```json
{
  "candidates": [
    {
      "content": {
        "parts": [{ "text": "Hello there, friend!" }],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ],
  "createTime": "2026-10-07T08:32:26.357216Z",
  "modelVersion": "gemini-3-5-flash-lite",
  "responseId": "01M3F7W9CNBGWDEBPB0NBDS0AD",
  "usageMetadata": {
    "candidatesTokenCount": 5,
    "promptTokenCount": 31,
    "totalTokenCount": 36
  }
}
```

token 数在 `usageMetadata`，`responseId` 是 Gateway 的 id，不是 Google 的。

## 串流

`streamGenerateContent` 一律以 Server-Sent Events 回应（`Content-Type: text/event-stream`），加不加 `?alt=sse` 都一样。这点和 Google 自己的 API 不同：Google 在没加 `alt=sse` 时会回传一个 JSON 阵列，预期拿到阵列的客户端需要改成处理 SSE。Google GenAI SDK 本来就会要求 SSE，可以直接使用。

#### 请求

```
curl -N "https://api.atptoken.ai/v1beta/models/gemini-3-5-flash-lite:streamGenerateContent?alt=sse" \
  -H "x-goog-api-key: atp-..." \
  -H "Content-Type: application/json" \
  -d '{ "contents": [{ "role": "user", "parts": [{ "text": "Say hi in 3 words" }] }] }'
```

#### 回应

```
data: {"candidates":[{"content":{"parts":[{"text":"Hello there"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":", friend!"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":""}],"role":"model"},"finishReason":"STOP","index":0}],"usageMetadata":{"candidatesTokenCount":5,"promptTokenCount":31,"totalTokenCount":36}}
```

每个区块只带新增的文字。`finishReason` 在最后一个区块之前都是 `null`，最后一个区块同时带有 `usageMetadata`。没有 `[DONE]` 行——连线关闭就代表串流结束。

## 与 Google API 的差异

| 功能 | Google 的 API | Gateway |
| --- | --- | --- |
| 不加 `?alt=sse` 的 `streamGenerateContent` | 一个 JSON 阵列 | Server-Sent Events |

## 错误

- 401 — 没带密钥或密钥无效。
- 403 — 这个项目没开放该模型，或模型不存在。

各状态码的意义与先检查什么，见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 下一步

- [Google GenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-google/) — 把 SDK 指向 Gateway，程式码不用改
- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 密钥可以放的位置，以及 `401` 代表什么
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么
