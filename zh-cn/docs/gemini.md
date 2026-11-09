# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/zh-cn/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST 风格的 `generateContent` 与 `streamGenerateContent` 路由，在 `/v1` 与 `/v1beta` 底下都支持。

请用 `google-genai` SDK（Python 或 Node），不是已弃用的 `google-generativeai`。把 base URL 指到 `https://api.atptoken.ai`，`apiVersion` 设成 `"v1beta"`。

> **apiVersion 要设成 v1beta**
>
> 钉在 `apiVersion: "v1"` 的客户端会去 `/v1/models` 拿模型清单。那是 OpenAI 的清单端点、回 OpenAI 格式，所以 Gemini SDK 会解析出 **0 个**模型，而且不会报错。聊天呼叫不受影响：`/v1/models/{model}:generateContent` 和 `/v1beta/models/{model}:generateContent` 都是 Gemini 路由，两条都能用。

## 路由

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/v1beta/models/{model}:generateContent` | 一次回应；SDK 默认的前缀 |
| POST | `/v1beta/models/{model}:streamGenerateContent` | Server-Sent Events |
| POST | `/v1/models/{model}:generateContent` | 同 `/v1beta` |
| POST | `/v1/models/{model}:streamGenerateContent` | 同 `/v1beta` |

模型放在 **URL** 里，不放在 body。`{model}` 是 `GET /v1beta/models` 回传的 id，这份清单列的就是这些路由收得下的模型，例如 `gemini-3-5-flash-lite`。项目的完整清单见 [GET /v1/project/models](https://atptoken.ai/zh-cn/docs/models/)。

从模型名称看不出该走哪个入口。`gemini-3-5-flash` 在 `/v1/chat/completions` 服务，`gemini-3-5-flash-lite` 则在这里。打错入口会回 `422`，消息会指名正确的入口。

## 验证

下面几种都可以用，依你的客户端默认即可。见[验证方式](https://atptoken.ai/zh-cn/docs/auth/)。

| 方式 | 范例 |
| --- | --- |
| `x-goog-api-key` header | `x-goog-api-key: atp-...`——Google GenAI SDK 的默认 |
| `key` query 参数 | `…:generateContent?key=atp-...`——log 会遮蔽，但仍建议用 header |
| Bearer header | `Authorization: Bearer atp-...` |
| `x-api-key` header | `x-api-key: atp-...` |

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
    http_options={"base_url": "https://api.atptoken.ai", "api_version": "v1beta"},
)
r = client.models.generate_content(
    model="<model from GET /v1beta/models>",
    contents="hi",
)
print(r.text)
```

```Node.js
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: "atp-...",
  httpOptions: { baseUrl: "https://api.atptoken.ai", apiVersion: "v1beta" },
});
const r = await ai.models.generateContent({
  model: "<model from GET /v1beta/models>",
  contents: "hi",
});
console.log(r.text);
```

`contents`、`systemInstruction` 与 `generationConfig`（例如 `maxOutputTokens`、`temperature`）都使用 Gemini 的栏位名称。

其他最上层栏位还有工具（`tools`、`toolConfig`）、安全设定、快取内容与标签。Gateway 会原样转送栏位，所以同一个栏位可能 A 模型收、B 模型拒。

### 文件

- 图片、音讯、文件用 `inlineData`（base64）内嵌。
- 或用 `fileData` 带模型读得到的 `fileUri`——你自己的 bucket 或 Gemini File API 的 URI，会原样转送。
- 上传到 Gateway 的文件（`an_<ulid>`）在这个入口**用不了**：引用它会回 `404 file_unavailable_for_failover`。请改用 `inlineData` 内嵌字节。

### 工具呼叫

工具宣告放在 `tools[].functionDeclarations`。模型的呼叫会以 `functionCall` part 回来；你把结果放在 `user` 回合的 `functionResponse` part 送回，用**名称**对应（没有 id）。这个入口的助理角色叫 `model`，不是 `assistant`。

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

每个 `data:` 事件都是一个完整的 `GenerateContentResponse` JSON 物件，不是 OpenAI 那种增量 delta。

`finishReason` 在最后一个区块之前都是 `null`，最后一个区块同时带有 `usageMetadata`。没有 `[DONE]` 行——连线关闭就代表串流结束。等 `data: [DONE]` 的程式在这里会一直卡住。

## 与 Google API 的差异

| 功能 | Google 的 API | Gateway |
| --- | --- | --- |
| 不加 `?alt=sse` 的 `streamGenerateContent` | 一个 JSON 阵列 | Server-Sent Events |

## 错误

- 401 — `token_revoked`：没带密钥或密钥无效。完全没送密钥也是这个错误。
- 402 — `insufficient_quota`：余额用完。不要重试，先充值。
- 403 — 这个项目没开放该模型，或模型不存在。不收费。
- 404 — `file_unavailable_for_failover`：你引用了上传的 `an_<ulid>` 文件。请改用 `inlineData`。
- 422 — 这个模型不在这个入口服务。消息会指名正确的入口。
- 429 — 限流，或这个模型此刻没有可用容量。依 `Retry-After` 等待。

各状态码的意义与先检查什么，见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 下一步

- [Google GenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-google/) — 把 SDK 指向 Gateway，程式码不用改
- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 密钥可以放的位置，以及 `401` 代表什么
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么
