# 總覽

> Source: https://atptoken.ai/zh-tw/docs/overview/

ATP 是一個統一 API，讓你透過單一 endpoint 存取多種 AI 模型，同時把 provider fallback 與計費集中在一處處理。把任何 OpenAI、Anthropic 或 Gemini 風格的 client 指向 Gateway，再以 credits 支付用量即可。

#### 你會得到什麼

- **一個 endpoint、多種模型。** 用 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 查詢，呼叫你的 project 允許的任一模型。
- **三種 wire format。** OpenAI、Anthropic 或 Google GenAI 格式原樣可用 — 只換 base URL。
- **自動 fallback。** 每個模型由一個 provider pool 服務，某個 provider 降級時同一個 model id 仍能運作。見 [Provider routing](https://atptoken.ai/zh-tw/docs/provider-routing/)。
- **單一帳單。** 跨所有模型與 provider 的用量都以 credits 計量。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

#### 三種接入方式

| 方式 | 適合 |
|---|---|
| API | 完整控制、任何語言、零相依 |
| SDKs | 用你既有的 OpenAI / Anthropic / Google SDK，型別安全 |
| Coding agents | Claude Code、Codex 等會說 wire format 的 agent |

#### 從這裡開始

第一次用 ATP？先跑一遍 [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/)，再讀 [How it works](https://atptoken.ai/zh-tw/docs/how-it-works/) 了解請求生命週期。準備好整理 key 與預算時，見 [設定你的 organization](https://atptoken.ai/zh-tw/docs/console-setup/)。

#### 延伸閱讀

- [企業 AI 成本管理完整指南](https://atptoken.ai/zh-tw/blog/enterprise-ai-cost-management-guide/)
- [AI 閘道選型 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026/)
- [上線後 AI 帳單為什麼會炸](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live/)

## 後續步驟

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 建立一把 project key，四個步驟送出第一個請求。
- [How it works](https://atptoken.ai/zh-tw/docs/how-it-works/) — 跟著一個請求走過驗證、模型授權、路由與計量。
- [價格](https://atptoken.ai/zh-tw/docs/pricing-model/) — 看 input 與 output tokens 怎麼換算成 credits，而且沒有月費。
