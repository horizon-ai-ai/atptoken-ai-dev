# 總覽

> Source: https://atptoken.ai/zh-tw/docs/overview/

ATP 是一個統一 API，讓你透過單一端點存取多種 AI 模型，同時把供應商自動備援與計費集中在一處處理。

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/)
  六個步驟，從儲值到在主控台看到第一筆請求。
- [API 參考](https://atptoken.ai/zh-tw/docs/chat/)
  端點、參數、回應與錯誤碼。
- [SDK 與 coding agent](https://atptoken.ai/zh-tw/docs/agents/)
  把 OpenAI、Anthropic、Google SDK，或 Claude Code、Codex 指向 Gateway。
- [使用主控台](https://atptoken.ai/zh-tw/docs/console-setup/)
  設定組織、專案與金鑰，再追蹤用量與帳單。

## 送出第一筆請求

把 `MODEL_ID` 換成 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的模型 ID，或從範例上方的模型選單挑一個。先把專案 API 金鑰放進 `$ATP_API_KEY`；[快速開始](https://atptoken.ai/zh-tw/docs/quickstart/)有完整步驟。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

## 你會得到什麼

- **一個端點、多種模型。** 用 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 查詢，呼叫你的專案（project）允許的任一模型。
- **三種 wire format（請求格式）。** OpenAI、Anthropic 或 Google GenAI 格式原樣可用——只換 base URL。
- **自動備援（fallback）。** 每個模型由一個供應商池服務，某個供應商降級時同一個模型 ID 仍能運作。見 [供應商路由與備援](https://atptoken.ai/zh-tw/docs/provider-routing/)。
- **單一帳單。** 跨所有模型與供應商的用量都以點數計量。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## 三種接入方式

| 方式 | 適合 |
|---|---|
| API | 完整控制、任何語言、零相依 |
| SDK | 用你既有的 OpenAI / Anthropic / Google SDK，型別安全 |
| Coding agent | Claude Code、Codex 等支援上述格式的開發代理工具 |

## AI 成本與閘道相關文章

- [企業 AI 成本管理完整指南](https://atptoken.ai/zh-tw/blog/enterprise-ai-cost-management-guide/)
- [AI 閘道選型 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026/)
- [上線後 AI 帳單為什麼會炸](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live/)

## 下一步

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 建立一把專案金鑰，六個步驟送出第一個請求。
- [運作方式](https://atptoken.ai/zh-tw/docs/how-it-works/) — 跟著一個請求走過驗證、模型授權、路由與計量。
- [價格](https://atptoken.ai/zh-tw/docs/pricing-model/) — 看 input 與 output tokens 怎麼換算成點數，而且沒有月費。
