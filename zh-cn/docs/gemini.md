# /v1/models/{model}:generateContent

> Source: https://atptoken.ai/zh-cn/docs/gemini/

`POST /v1/models/{model}:generateContent`

Gemini REST 风格的 `generateContent` 与 `streamGenerateContent` 路由，在 `/v1` 与 `/v1beta`（Google GenAI SDK 预设）底下皆支援。以 `x-goog-api-key` 验证 — 这是 SDK 的预设。

#### Request

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
