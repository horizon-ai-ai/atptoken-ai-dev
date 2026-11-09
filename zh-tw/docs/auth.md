# 金鑰放在哪裡

> Source: https://atptoken.ai/zh-tw/docs/auth/

Gateway 可從下列位置讀取專案（project）API 金鑰。`Authorization: Bearer` 和 `x-api-key` 在每個端點都有效，所以官方 OpenAI、Anthropic、Google GenAI SDK 都不用改，只要換 base URL。Gateway 會在轉送請求前移除這把金鑰。

## 先拿到金鑰

金鑰不是從 API 申請的。到 [atptoken.ai](https://atptoken.ai) 登入，依序選擇或建立 組織 → 工作區 → 專案，再到專案裡建立金鑰。一把金鑰屬於一個專案：能用哪些模型、費用算在誰頭上，都由那個專案決定。見[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/)。

## 金鑰放在哪裡

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、curl |
| `x-api-key: atp-…` | Anthropic SDK（`api_key=`）、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK |
| `?key=atp-…` | Gemini REST client。Log 會遮蔽這個 query param——可以的話優先用 header。 |

## 驗證失敗時

沒帶、被停用、過期或不存在的金鑰，都回 `401`，代碼是 `token_revoked`，訊息是「API key has been revoked or does not exist」。**完全沒送金鑰也是同一個錯誤**，所以先確認 header 真的有送出去，再懷疑金鑰本身。

`403` 是另一回事：金鑰沒問題，但模型不在這個專案的允許清單上。見[錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## 下一步

- [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/) — 建立專案金鑰，以及撤銷金鑰
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — `401` 代表什麼、先檢查什麼
- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 用專案金鑰送出第一個請求
