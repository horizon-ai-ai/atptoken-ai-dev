# 三种可接受的密钥位置

> Source: https://atptoken.ai/zh-cn/docs/auth/

Gateway 可从下列位置读取项目（project） API 密钥。使用你的 SDK 默认送出的方式即可；Gateway 会在转送供应商前移除这把密钥。

## 密钥放在哪里

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、Anthropic SDK、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK（Gemini 建议用这个） |
| `?key=atp-…` | Gemini REST client。Log 会遮蔽这个 query param——可以的话优先用 header 形式。 |

## 验证失败时

三者都没带 → `401`。密钥被停用或过期 → `401`。

## 下一步

- [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/) — 建立项目密钥，以及撤销密钥
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — `401` 代表什么、先检查什么
- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 用项目密钥送出第一个请求
