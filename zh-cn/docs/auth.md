# 密钥放在哪里

> Source: https://atptoken.ai/zh-cn/docs/auth/

Gateway 可从下列位置读取项目（project）API 密钥。`Authorization: Bearer` 和 `x-api-key` 在每个端点都有效，所以官方 OpenAI、Anthropic、Google GenAI SDK 都不用改，只要换 base URL。Gateway 会在转送请求前移除这把密钥。

## 先拿到密钥

密钥不是从 API 申请的。到 [atptoken.ai](https://atptoken.ai) 登录，依序选择或建立 组织 → 工作区 → 项目，再到项目里建立密钥。一把密钥属于一个项目：能用哪些模型、费用算在谁头上，都由那个项目决定。见[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 密钥放在哪里

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、curl |
| `x-api-key: atp-…` | Anthropic SDK（`api_key=`）、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK |
| `?key=atp-…` | Gemini REST client。Log 会遮蔽这个 query param——可以的话优先用 header。 |

## 验证失败时

没带、被停用、过期或不存在的密钥，都回 `401`，代码是 `token_revoked`，消息是「API key has been revoked or does not exist」。**完全没送密钥也是同一个错误**，所以先确认 header 真的有送出去，再怀疑密钥本身。

`403` 是另一回事：密钥没问题，但模型不在这个项目的允许清单上。见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 下一步

- [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/) — 建立项目密钥，以及撤销密钥
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — `401` 代表什么、先检查什么
- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 用项目密钥送出第一个请求
