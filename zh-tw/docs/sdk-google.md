# Google GenAI SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-google/

直接用 Google GenAI SDK，不改任何東西。把 base URL 設成 Gateway、以 `x-goog-api-key`（SDK 預設）驗證，並呼叫 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的任一模型。

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 驗證 | `x-goog-api-key: atp-…`（SDK 預設） |
| 模型 | GET /v1/models 的任一 id |

```
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

`generateContent` 與 `streamGenerateContent` 路由在 `/v1` 與 `/v1beta`（SDK 預設）底下皆可用。完整端點規格：[/v1/models/{model}:generateContent](https://atptoken.ai/zh-tw/docs/gemini/)。
