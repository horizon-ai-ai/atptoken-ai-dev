# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/zh-tw/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST 風格的 `generateContent` 與 `streamGenerateContent` 路由，在 `/v1` 與 `/v1beta`（Google GenAI SDK 預設）底下皆支援。以 `x-goog-api-key` 驗證——這是 SDK 的預設。

## 路由

| 方法 | 路徑 | 說明 |
| --- | --- | --- |
| POST | `/v1beta/models/{model}:generateContent` | 一次回應；SDK 預設的前綴 |
| POST | `/v1beta/models/{model}:streamGenerateContent` | Server-Sent Events |
| POST | `/v1/models/{model}:generateContent` | 同 `/v1beta` |
| POST | `/v1/models/{model}:streamGenerateContent` | 同 `/v1beta` |

`{model}` 是 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的 id，例如 `gemini-3-5-flash-lite`。

## 驗證

三種方式都可以用，依你的客戶端預設即可。見[驗證方式](https://atptoken.ai/zh-tw/docs/auth/)。

| 方式 | 範例 |
| --- | --- |
| `x-goog-api-key` header | `x-goog-api-key: atp-...`——Google GenAI SDK 的預設 |
| `key` query 參數 | `…:generateContent?key=atp-...`——log 會遮蔽，但仍建議用 header |
| Bearer header | `Authorization: Bearer atp-...` |

## 請求

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

`contents`、`systemInstruction` 與 `generationConfig`（例如 `maxOutputTokens`、`temperature`）都使用 Gemini 的欄位名稱。

## 回應

#### 回應

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

token 數在 `usageMetadata`，`responseId` 是 Gateway 的 id，不是 Google 的。

## 串流

`streamGenerateContent` 一律以 Server-Sent Events 回應（`Content-Type: text/event-stream`），加不加 `?alt=sse` 都一樣。這點和 Google 自己的 API 不同：Google 在沒加 `alt=sse` 時會回傳一個 JSON 陣列，預期拿到陣列的客戶端需要改成處理 SSE。Google GenAI SDK 本來就會要求 SSE，可以直接使用。

#### 請求

```
curl -N "https://api.atptoken.ai/v1beta/models/gemini-3-5-flash-lite:streamGenerateContent?alt=sse" \
  -H "x-goog-api-key: atp-..." \
  -H "Content-Type: application/json" \
  -d '{ "contents": [{ "role": "user", "parts": [{ "text": "Say hi in 3 words" }] }] }'
```

#### 回應

```
data: {"candidates":[{"content":{"parts":[{"text":"Hello there"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":", friend!"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":""}],"role":"model"},"finishReason":"STOP","index":0}],"usageMetadata":{"candidatesTokenCount":5,"promptTokenCount":31,"totalTokenCount":36}}
```

每個區塊只帶新增的文字。`finishReason` 在最後一個區塊之前都是 `null`，最後一個區塊同時帶有 `usageMetadata`。沒有 `[DONE]` 行——連線關閉就代表串流結束。

## 與 Google API 的差異

| 功能 | Google 的 API | Gateway |
| --- | --- | --- |
| 不加 `?alt=sse` 的 `streamGenerateContent` | 一個 JSON 陣列 | Server-Sent Events |

## 錯誤

- 401 — 沒帶金鑰或金鑰無效。
- 403 — 這個專案沒開放該模型，或模型不存在。

各狀態碼的意義與先檢查什麼，見[錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## 下一步

- [Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google/) — 把 SDK 指向 Gateway，程式碼不用改
- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 金鑰可以放的位置，以及 `401` 代表什麼
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼先檢查什麼
