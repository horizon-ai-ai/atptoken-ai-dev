# 三種可接受的金鑰位置

> Source: https://atptoken.ai/zh-tw/docs/auth/

Gateway 可從下列位置讀取專案（project） API 金鑰。使用你的 SDK 預設送出的方式即可；Gateway 會在轉送供應商前移除這把金鑰。

## 金鑰放在哪裡

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、Anthropic SDK、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK（Gemini 建議用這個） |
| `?key=atp-…` | Gemini REST client。Log 會遮蔽這個 query param——可以的話優先用 header 形式。 |

## 驗證失敗時

三者都沒帶 → `401`。金鑰被停用或過期 → `401`。

## 下一步

- [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/) — 建立專案金鑰，以及撤銷金鑰
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — `401` 代表什麼、先檢查什麼
- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 用專案金鑰送出第一個請求
