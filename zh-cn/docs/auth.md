# 三种可接受的 key 位置

> Source: https://atptoken.ai/zh-cn/docs/auth/

Gateway 可从下列位置读取 project API key。使用你的 SDK 预设送出的方式即可；Gateway 会在转送 provider 前移除这把 key。

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、Anthropic SDK、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK（Gemini 建议用这个） |
| `?key=atp-…` | Gemini REST client。Log 会遮蔽这个 query param — 可以的话优先用 header 形式。 |

三者都没带 → `401`。key 被停用或过期 → `401`。
