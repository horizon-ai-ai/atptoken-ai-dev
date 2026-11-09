# Google GenAI SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-google/

直接用 Google GenAI SDK（`google-genai`：Python 是 `from google import genai`，Node 是 `@google/genai`），不改任何東西。舊的 `google-generativeai` 已棄用。把 base URL 設成 Gateway、`apiVersion` 設 `v1beta`，以 `x-goog-api-key`（SDK 預設）驗證，並呼叫在這個入口服務的模型。

## 設定 client

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| API 版本 | `v1beta` |
| 驗證 | `x-goog-api-key: atp-…`（SDK 預設） |
| 模型 | GET /v1beta/models 的任一 id |

`GET /v1beta/models` 是 Gemini 自己的清單端點，只列能在 `:generateContent`／`:streamGenerateContent` 呼叫的模型。`GET /v1/models` 是 OpenAI 的清單，不是這一份。要看專案在所有入口允許的全部模型，打 `GET /v1/project/models`。不在這裡服務的模型會回 `422`，訊息會指名正確的入口。

```
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

## 支援的路由

`generateContent` 與 `streamGenerateContent` 路由在 `/v1` 與 `/v1beta` 底下皆可用。模型放在網址裡，不放在 body。這裡沒有 `stream` 欄位：要串流就改打 `:streamGenerateContent`。完整端點規格：[/v1/models/{model}:generateContent](https://atptoken.ai/zh-tw/docs/gemini/)。

> **apiVersion 要維持 v1beta**
>
> 釘在 `v1` 的客戶端會去 `/v1/models` 拿模型清單，那是 OpenAI 的端點、回 OpenAI 的格式，SDK 會解析出 0 個模型，而且不會報錯。聊天呼叫不受影響，受影響的只有清單。

用 Gemini 上傳協定（`/upload/v1beta/files`）傳的檔案，這個入口的模型拿不到——引用它會回錯。圖片和音訊請改用 `inlineData` 直接內嵌。

## 下一步

- [/v1/models/{model}:generateContent](https://atptoken.ai/zh-tw/docs/gemini/) — 這個端點的參數與回應格式。
- [列出平台可用模型](https://atptoken.ai/zh-tw/docs/models/) — 取得要填進 `model` 的模型 ID。
- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 金鑰可以放在哪些位置，包括 `x-goog-api-key`。
