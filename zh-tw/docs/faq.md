# 常見問題

> Source: https://atptoken.ai/zh-tw/docs/faq/

連接 Gateway、可呼叫哪些模型，以及用量如何計費的常見問題與簡短解答。

## 連接 Gateway

### 有 MCP 伺服器嗎？

有：`atptoken-api-docs`，網址 `https://mcp.atptoken.ai/mcp`。它讓 Claude Code、Codex 等 agent 有 API 文件、即時查模型、送影片任務前的檢查。加上它不需要金鑰；只有「即時查模型」要帶你的金鑰。各工具的安裝指令見 [SDK 與 coding agent](https://atptoken.ai/zh-tw/docs/agents/)。

### 我需要特別的 SDK 嗎？

不用。官方 OpenAI、Anthropic 與 Google GenAI（`google-genai`）SDK 原樣可用——把它們指向 Gateway base URL 並用專案（project） API 金鑰即可。舊的 `google-generativeai` 已棄用。每個模型只走一個 SDK、一個入口；打錯會回 `422`，訊息會指名正確的入口。見 [Integrations](https://atptoken.ai/zh-tw/docs/agents/)。

### base URL 是什麼？

Anthropic 與 Gemini 格式用 `https://api.atptoken.ai`（Gemini 另外要設 `apiVersion: "v1beta"`），OpenAI 格式用 `https://api.atptoken.ai/v1`。各 SDK 頁會列出確切值。這個網域只服務 `/v1*` 與 `/omni/*`，打其他路徑（例如 `/api`）會回 `404`。

### 可以串流回應嗎？

可以，而且 `stream` 一定要明確送。`/v1/chat/completions` 與 `/v1/messages` 預設是 `true`（跟 OpenAI、Anthropic 官方相反）；`/v1/responses` 預設是 `false`。Gemini 沒有 `stream` 欄位，要換成 `:streamGenerateContent` 端點。見 [OpenAI SSE](https://atptoken.ai/zh-tw/docs/sse-openai/) 與 [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/)。

## 模型與可用性

### 我的金鑰能呼叫哪些模型？

只有它所屬專案允許清單上的模型。完整清單用同一把金鑰打 `GET /v1/project/models`，文字、媒體、向量模型都在裡面。`GET /v1/models` 只是 OpenAI 的清單：只列 `/v1/chat/completions` 與 `/v1/responses` 收的 chat 模型，所以多數 `claude-*`（走 `/v1/messages`）、Gemini（在 `/v1beta/models`）、媒體與向量模型都不在上面。清單上沒有，不代表不能用；專案真的沒開權限時，建立請求會回 `403`，不收費。見 [模型查詢](https://atptoken.ai/zh-tw/docs/models/)。

### 某個供應商掛掉會怎樣？

每個模型由一個供應商池 服務，Gateway 會自動切換。若某模型的所有供應商都不可用，你會收到帶 `Retry-After` 的 `503`。見 [供應商路由與備援](https://atptoken.ai/zh-tw/docs/provider-routing/)。

### 為什麼 reasoning 模型回傳 200 但內容是空的？

`max_tokens` 設太低了。推理模型（extended thinking）的思考會吃同一個額度；額度在產生可見輸出前就用完，你會拿到空的 `200`——通常用量為零、也不會扣點數。把 `max_tokens` 調高到「思考+預期輸出」都夠用。見[常見回應](https://atptoken.ai/zh-tw/docs/errors/)。

### ATP Token 只有文字模型嗎？

不是。目錄還包含圖像、影片、語音(TTS)與 embedding 模型。媒體只有非同步：建立任務、輪詢，再在 24 小時內從簽章網址下載。各模態的用途與計費方式見[媒體模型](https://atptoken.ai/zh-tw/docs/media/)。

## 計費與用量

### 怎麼計費？點數可以退款嗎？

用量以 input + output tokens 計量，並以點數支付(1 點數 = USD 0.01)。儲值與點數皆不可退款。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) 與 [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/)。

### 我怎麼看花了多少？

用量頁依模型與金鑰彙整點數與 tokens；請求紀錄提供每筆請求的稽核軌跡。計費以「請求」為單位，不是以「嘗試」為單位：一個請求在紀錄裡可能有好幾列，不要加總。見 [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/) 與 [追蹤消耗](https://atptoken.ai/zh-tw/docs/spend/)。

## 下一步

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 建立一把專案金鑰，送出第一個請求。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 用量怎麼換算成點數、點數花在哪裡。
