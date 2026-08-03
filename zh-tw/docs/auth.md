# 三種可接受的 key 位置

> Source: https://atptoken.ai/zh-tw/docs/auth/

Gateway 可從下列位置讀取 project API key。使用你的 SDK 預設送出的方式即可；Gateway 會在轉送 provider 前移除這把 key。

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、Anthropic SDK、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK（Gemini 建議用這個） |
| `?key=atp-…` | Gemini REST client。Log 會遮蔽這個 query param — 可以的話優先用 header 形式。 |

三者都沒帶 → `401`。key 被停用或過期 → `401`。
