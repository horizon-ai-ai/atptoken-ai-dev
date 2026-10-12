# 常見問題

> Source: https://atptoken.ai/zh-tw/docs/faq/

連接 Gateway、可呼叫哪些模型，以及用量如何計費的常見問題與簡短解答。

## 連接 Gateway

### 我需要特別的 SDK 嗎？

不用。Gateway 相容 OpenAI、Anthropic 與 Google GenAI SDK——把它們指向 Gateway base URL 並用專案（project） API 金鑰即可。見 [Integrations](https://atptoken.ai/zh-tw/docs/agents/)。

### base URL 是什麼？

Anthropic 與 Gemini 格式用 `https://api.atptoken.ai`,OpenAI 格式用 `https://api.atptoken.ai/v1`。各 SDK 頁會列出確切值。

### 可以串流回應嗎？

可以。設 `stream: true`,Gateway 會以對應你 SDK 的格式串流 SSE。見 [OpenAI SSE](https://atptoken.ai/zh-tw/docs/sse-openai/) 與 [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/)。

## 模型與可用性

### 我的金鑰能呼叫哪些模型？

只有它所屬專案的 allowed list 上的模型。[GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 列出平台提供的清單；存取權在 request time 依專案強制檢查——所以清單是選單，不是金鑰的權限。

### 某個供應商掛掉會怎樣？

每個模型由一個供應商池 服務，Gateway 會自動切換。若某模型的所有供應商都不可用，你會收到帶 `Retry-After` 的 `503`。見 [供應商路由與備援](https://atptoken.ai/zh-tw/docs/provider-routing/)。

### 為什麼 reasoning 模型回傳 200 但內容是空的？

`max_tokens` 設太低了。推理模型（extended thinking）的思考會吃同一個額度；額度在產生可見輸出前就用完，你會拿到空的 `200`——通常用量為零、也不會扣點數。把 `max_tokens` 調高到「思考+預期輸出」都夠用。見[常見回應](https://atptoken.ai/zh-tw/docs/errors/)。

### ATP Token 只有文字模型嗎？

不是。目錄還包含圖像、影片、語音(TTS)與 embedding 模型。各模態的用途與計費方式見[媒體模型](https://atptoken.ai/zh-tw/docs/media/)。

## 計費與用量

### 怎麼計費？點數可以退款嗎？

用量以 input + output tokens 計量，並以點數支付(1 點數 = USD 0.01)。儲值與點數皆不可退款。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) 與 [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/)。

### 我怎麼看花了多少？

用量頁依模型與金鑰彙整點數與 tokens；請求紀錄提供每筆請求的稽核軌跡。見 [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/) 與 [追蹤消耗](https://atptoken.ai/zh-tw/docs/spend/)。

## 下一步

- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 建立一把專案金鑰，送出第一個請求。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 用量怎麼換算成點數、點數花在哪裡。
