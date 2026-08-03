# 運作方式

> Source: https://atptoken.ai/zh-tw/docs/how-it-works/

Gateway 位在你的 client 與上游模型 provider 之間。不論你用哪種 SDK 格式，每個請求都會經過相同的四個階段。

## 1. 驗證

Project API key 會先被驗證，並在轉送上游前移除 — provider 永遠看不到你的 ATP key。缺失、被停用或過期的 key 會以 `401` 拒絕。見 [驗證方式](https://atptoken.ai/zh-tw/docs/auth/)。

## 2. 授權模型

請求的模型必須在該 project 的 allowed list 上。若不在，會在送到任何 provider 前以 `403` 拒絕 — 模型存取權是設在 project、不是設在 key。見 [模型查詢](https://atptoken.ai/zh-tw/docs/models/)。

## 3. 路由到 provider

Gateway 會從該模型設定的 provider pool 挑一個，遇到 provider 錯誤或逾時就 fail over 到另一個，因此同一個 model id 能跨 provider 保持穩定。見 [Provider routing & fallbacks](https://atptoken.ai/zh-tw/docs/provider-routing/)。

## 4. 計量與計費

Input 與 output tokens 會被計量，並以 credits 從該 project 餘額扣款。餘額耗盡時請求會以 `402` 拒絕。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

### Gateway 改變什麼、又不改變什麼

Gateway 轉譯驗證與路由，但把你的 request 與 response body 維持在 SDK 本來就預期的形狀。

| 幫你處理 | 維持不變 |
|---|---|
| Key 驗證與 provider 驗證 | Request body schema（依 SDK 格式） |
| 模型存取檢查 | Response body schema |
| Provider 挑選與 fallback | 串流事件序列 |
| 計量與 credit 扣款 | 模型行為與輸出 |

因為 wire format 原樣通過，把既有的 OpenAI、Anthropic 或 Gemini 整合搬過來，通常只是改 base URL 與 key。

### 四個階段再往下看

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/)
  三種可接受的 key 放置位置，以及 `401` 到底代表什麼。
- [模型查詢](https://atptoken.ai/zh-tw/docs/models/)
  把 model id 寫死之前，先列出這把 project key 能呼叫哪些模型。
- [Provider routing](https://atptoken.ai/zh-tw/docs/provider-routing/)
  pool 怎麼排序，以及 Gateway 什麼時候會切到下一個 provider。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)
  哪些東西會被計量，以及 project 餘額用完時會發生什麼事。

#### 延伸閱讀

- [OpenAI API vs 企業 AI 閘道](https://atptoken.ai/zh-tw/blog/openai-api-vs-enterprise-ai-gateway/)
- [AI 閘道選型 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026/)
