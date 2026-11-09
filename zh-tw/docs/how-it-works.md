# 運作方式

> Source: https://atptoken.ai/zh-tw/docs/how-it-works/

Gateway 位在你的程式 與上游模型供應商之間。不論你用哪種 SDK 格式，每個請求都會經過相同的四個階段。

## 請求經過的路徑

**一個請求經過 Gateway**

1. 你的程式 — `atp-…` 金鑰 — OpenAI、Anthropic 或 Gemini 格式
2. 驗證 — 金鑰檢查 — 缺失、停用或過期回 `401 token_revoked`
3. 授權模型 — 專案 allowed list — 模型不在清單上回 `403`，打錯入口回 `422`
4. 路由到供應商 — 自動備援 — 遇到供應商錯誤或逾時就切換
5. 計量與計費 — 點數 — 餘額耗盡回 `402`
6. 上游供應商 — 看不到你的 ATP 金鑰

## 1. 驗證

專案（project） API 金鑰會先被驗證，並在轉送上游前移除——供應商永遠看不到你的 ATP 金鑰。金鑰可以放在 `Authorization: Bearer` 或 `x-api-key`。缺失、被停用或過期的金鑰會以 `401 token_revoked` 拒絕——完全沒送金鑰也是這個，所以先檢查 header 有沒有送出去。見 [驗證方式](https://atptoken.ai/zh-tw/docs/auth/)。

## 2. 授權模型

請求的模型必須在該專案的 allowed list 上。若不在，會在送到任何供應商前以 `403` 拒絕，不收費——模型存取權是設在專案、不是設在金鑰。另外每個模型只在一個入口服務（`/v1/chat/completions` 或 `/v1/responses`、`/v1/messages`、`/v1beta/models/{model}:generateContent`）；打錯入口會回 `422`，訊息會指名正確的入口。見 [模型查詢](https://atptoken.ai/zh-tw/docs/models/)。

## 3. 路由到供應商

Gateway 會從該模型設定的供應商池 挑一個，遇到供應商錯誤或逾時就切換到另一個，因此同一個模型 ID 能跨供應商保持穩定。見 [供應商路由與備援](https://atptoken.ai/zh-tw/docs/provider-routing/)。

## 4. 計量與計費

Input 與 output tokens 會被計量，並以點數從該專案餘額扣款。計費以「請求」為單位，不是以「嘗試」為單位：一個請求在紀錄裡可能有好幾列，不要加總。餘額耗盡時請求會以 `402` 拒絕。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## Gateway 改變什麼、又不改變什麼

Gateway 轉譯驗證與路由，但把你的 request 與 response body 維持在 SDK 本來就預期的形狀。

| 幫你處理 | 維持不變 |
|---|---|
| 金鑰驗證與供應商驗證 | Request body schema（依 SDK 格式，不會幫你轉換） |
| 模型存取檢查 | Response body schema |
| 供應商挑選與自動備援（fallback） | 串流事件序列 |
| 計量與點數扣款 | 模型行為與輸出 |

因為 wire format 原樣通過，把既有的 OpenAI、Anthropic 或 Gemini 整合搬過來，通常只是改 base URL 與金鑰——前提是你要呼叫的模型就在那個 SDK 的入口服務。有兩件事不一樣：`/v1/chat/completions` 與 `/v1/messages` 的 `stream` 預設是 `true`，請明確送；還有 HTTP `200` 不代表模型看到了你送的全部內容，因為 body 會原樣轉發，不替你檢查每個模型的格式。每個回應都帶 `x-request-id`，回報問題時附上它。

## 四個階段再往下看

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/)
  金鑰可以放在哪些位置，以及 `401` 到底代表什麼。
- [模型查詢](https://atptoken.ai/zh-tw/docs/models/)
  把模型 ID 寫死之前，先列出這把專案金鑰能呼叫哪些模型。
- [供應商路由與備援](https://atptoken.ai/zh-tw/docs/provider-routing/)
  供應商池怎麼排序，以及 Gateway 什麼時候會切到下一個供應商。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)
  哪些東西會被計量，以及專案餘額用完時會發生什麼事。

## 下一步

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 透過 Gateway 送出第一個請求。
- [OpenAI API vs 企業 AI 閘道](https://atptoken.ai/zh-tw/blog/openai-api-vs-enterprise-ai-gateway/) — 直接呼叫供應商與經過閘道的差別。
- [AI 閘道選型 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026/) — 各家 AI 閘道的比較。
