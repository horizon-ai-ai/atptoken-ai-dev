# LLM 閘道比較 2026：OpenRouter、Vercel AI Gateway、LiteLLM、Portkey、Helicone 與 ATP Token

> 來源: https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026/
> 發表於: 2026-08-21 · 作者: hung-chien (AI 成長與品牌經理)

LLM 閘道是做什麼的，以及截至 2026 年 10 月，六個閘道在部署方式、計費、花費上限、模型白名單與 API 格式上的差異。

## 重點摘要

- LLM 閘道讓應用用一個 API 呼叫多家模型，並處理金鑰、供應商路由與容錯、請求紀錄與花費上限。
- 到了 2026 年，多數閘道都有預算與紀錄。真正的差別在：閘道跑在哪裡、怎麼付錢、預算綁在什麼單位上，以及上限是硬是軟。
- 依限制條件選：必須自架（LiteLLM、Portkey 或 Helicone 開源版）、要最大的模型目錄（OpenRouter）、部署在 Vercel（Vercel AI Gateway）、要每個專案預付預算並各自設模型白名單（ATP Token）。

LLM 閘道是位於應用與模型供應商之間的服務：程式只對一個 API 呼叫多家模型，金鑰、路由與容錯、請求紀錄與花費上限由閘道處理。本文用同一份清單比較 2026 年團隊常列入考慮的六個閘道，每一項價格與功能都附上該廠商截至 2026 年 10 月的官方文件連結。

## LLM 閘道做哪些事

依請求經過的順序，有五件事：

1. 一個 API 呼叫多家模型。程式對同一個 base URL 送出熟悉的格式（通常是 OpenAI 格式），換模型只改 `model` 欄位。
2. 驗證與金鑰。閘道發自己的金鑰，供應商憑證不必放進應用。
3. 存取規則。決定這把金鑰能不能呼叫這個模型。
4. 路由與容錯。為模型挑一個供應商，失敗時改送別家。
5. 計量、紀錄與上限。逐筆記錄 token 與費用，預算到了就擋下。

在 ATP Token 上，這幾個階段對應到可以實測的狀態碼：金鑰錯誤 401、模型不在專案允許清單 403、供應商失敗 502 或 503、專案點數用完 402（[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)、[錯誤](https://atptoken.ai/zh-tw/docs/errors)）。

## 六個閘道一覽

| | 跑在哪裡 | 你付的錢 | 預算綁在 | 到上限時 | 模型白名單 | API 格式 |
|---|---|---|---|---|---|---|
| [OpenRouter](https://openrouter.ai/pricing) | 代管 | 供應商價格＋購買點數刷卡 5.5%（Standard） | API 金鑰、成員；工作區需 Enterprise | 拒絕 | 對成員或金鑰設 guardrails | OpenAI 相容、Anthropic Messages |
| [Vercel AI Gateway](https://vercel.com/docs/ai-gateway/pricing) | 代管 | 供應商定價，token 不加價；可能有金流手續費 | 團隊、專案、金鑰、成員 | 402，軟上限 | 供應商白名單（付費加購） | AI SDK、OpenAI Chat 與 Responses、Anthropic Messages |
| [LiteLLM](https://docs.litellm.ai/docs/proxy/users) | 自架（開源） | 自家供應商帳單＋主機；可選 Enterprise 授權 | 金鑰、使用者、團隊、客戶 | 拒絕 | 依金鑰或團隊設 access group | OpenAI 相容 |
| [Portkey](https://portkey.ai/pricing) | 代管；另有開源與 VPC 選項 | 免費方案、Production 每月 49 美元、Enterprise 另議 | 供應商或虛擬金鑰（Enterprise 與部分 Pro） | 金鑰到上限即失效 | 本文未比較 | OpenAI 相容 |
| [Helicone](https://docs.helicone.ai/gateway/overview) | 開源（Apache）或代管 | 見廠商說明 | 本文未比較 | — | 本文未比較 | OpenAI 相容 |
| [ATP Token](https://atptoken.ai/zh-tw/docs/how-it-works) | 代管 | 預付點數，依各模型定價扣抵；5 美元起 | 專案，額度由工作區與組織往下撥 | 餘額用完回傳 402 | 每個專案一份，送到供應商前檢查（403） | OpenAI、Anthropic、Gemini |

「本文未比較」代表我們在廠商公開文件中沒有找到該項細節，正式採用前請向廠商確認。

## 怎麼選：六個問題

### 1. 閘道必須跑在哪裡？

如果流量不能經過第三方，候選名單就是自架：LiteLLM proxy、Helicone 開源閘道，或 Portkey 的開源與 VPC 選項。本文其他選項都是代管。

### 2. 想怎麼付錢？

有三種模式：

- 供應商價格加上儲值手續費。OpenRouter：Standard 刷卡 5.5%（最低 0.80 美元）、Business 8%（[FAQ](https://openrouter.ai/docs/faq)）。
- 照供應商定價、token 不加價。Vercel AI Gateway，可能有金流手續費（[定價](https://vercel.com/docs/ai-gateway/pricing)）。
- 預付點數，依各模型定價扣抵。ATP Token：1 點 = 0.01 美元，按量付費點數不會過期，儲值 5 美元起（[點數](https://atptoken.ai/zh-tw/docs/credits)）。各模型費率見[定價頁](https://atptoken.ai/zh-tw/pricing)。

自架閘道沒有平台費，成本在供應商帳單與工程時間。

### 3. 預算綁在什麼上面？是硬上限嗎？

這是各閘道差最多的地方。

- OpenRouter：guardrails 裡的預算掛在成員或金鑰上，按日、週、月重置；工作區預算需 Enterprise（[guardrails](https://openrouter.ai/docs/guides/features/guardrails)）。
- Vercel：團隊、專案、金鑰、成員四種預算。Vercel 稱之為軟上限：跨過上限的那一筆仍會完成，之後的請求回傳 402（[預算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)）。
- LiteLLM：依金鑰、使用者、團隊或客戶設預算，重置週期如 `30d`。
- ATP Token：點數沿組織 → 工作區 → 專案往下撥，專案只能花自己的額度。沒有重置週期，專案用到餘額為零就回傳 402，直到有人再撥款（[預算上限設定](https://atptoken.ai/zh-tw/docs/cb-budget-caps)）。

週期重置的預算適合「這把金鑰每月不超過 500 美元」；預付額度適合「這條產品線這一季有 5,000 美元」。

### 4. 應用現在用哪些 SDK 格式？

多數閘道支援 OpenAI 格式。如果有服務用 Anthropic SDK（Claude Code 就是）或 Google GenAI SDK，要確認是否原生支援：OpenRouter 與 Vercel 有 Anthropic Messages 文件；ATP Token 可直接使用 OpenAI、Anthropic、Google GenAI 三種官方 SDK（[OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai)、[Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic)、[Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google)）。

### 5. 需要哪些模型與模態？

OpenRouter 列出 80+ 家供應商、500+ 個模型。ATP Token 有 11 家供應商、70+ 個模型，包含 [Seedance 2.0](https://atptoken.ai/zh-tw/models/seedance-2-0/)、[Kling v3 Pro](https://atptoken.ai/zh-tw/models/kling-v3-pro/) 等影片模型，以及 [Nano Banana Pro](https://atptoken.ai/zh-tw/models/nano-banana-pro/) 等圖像模型（[媒體模型](https://atptoken.ai/zh-tw/docs/media)）。如果只需要幾個前沿 LLM，目錄大小沒有其他問題重要。

### 6. 紀錄保留什麼、保留多久？

Portkey 公布各方案的保留期：免費方案紀錄 3 天，Production 30 天。ATP Token 的請求紀錄保留 7 天，定位是除錯視圖，帳務以帳務事件為準（[請求紀錄 API](https://atptoken.ai/zh-tw/docs/console-api-logs)）。如果每月檢討花費，請每週匯出或彙整。

## 各閘道細看

### OpenRouter

- 適合：需要最大的代管模型目錄、要快速評估模型。
- 控管：組織、工作區、含預算與模型及供應商白名單的 guardrails、ZDR 規則；所有方案都能對單把金鑰設點數上限。
- 要注意：購買點數的手續費、點數可能在一年後失效、開立發票只有 Enterprise。完整說明見 [OpenRouter 替代方案（團隊版）](https://atptoken.ai/zh-tw/blog/openrouter-vs-enterprise-governance)。

### Vercel AI Gateway

- 適合：部署在 Vercel 的團隊，或想要照供應商定價計費的代管閘道。
- 控管：四種預算範圍、50/75/100% 花費通知、請求紀錄、供應商與模型容錯。
- 要注意：預算是軟上限；用自帶供應商金鑰的花費不計入預算；部分控管是付費加購。

### LiteLLM

- 適合：想完全掌控、本來就在維運基礎設施的平台團隊。
- 控管：虛擬金鑰、多層預算、用 access group 管模型。
- 要注意：要自己維運。使用者與金鑰層級的依模型預算需要 Enterprise 授權。

### Portkey

- 適合：希望閘道、觀測與 guardrails 在同一個產品裡的團隊。
- 控管：對供應商或虛擬金鑰設預算上限，可設通知門檻、每週或每月重置，適用 Enterprise 與部分 Pro 方案（[預算上限](https://portkey.ai/docs/product/ai-gateway/virtual-keys/budget-limits)）。每月 49 美元的 Production 方案起有角色權限控管。
- 要注意：各方案有紀錄額度（免費每月 1 萬筆，Production 10 萬筆）。

### Helicone

- 適合：以觀測為主的團隊；閘道開源，以 Rust 撰寫。
- 控管：記錄每筆請求的 token 與費用，支援 100+ 個模型的路由、容錯與快取。
- 要注意：預算與存取控管功能請依需求向廠商確認，閘道總覽文件中沒有看到。

### ATP Token

- 適合：多個團隊共用一筆 AI 預算，每個專案要有撥好的額度與審核過的模型清單。
- 控管：組織 → 工作區 → 專案的階層、綁專案的金鑰、每個專案的允許模型、以點數額度作為上限、逐筆請求紀錄、Owner／Admin／Member 角色（[團隊與角色](https://atptoken.ai/zh-tw/docs/team)）。
- 要注意：模型目錄比 OpenRouter 小；點數不可退款；請求紀錄保留 7 天。

## 同時用兩個閘道

很多團隊最後會有兩個：一個大目錄閘道做研究與評估，一個有治理的閘道跑正式環境。讓這種配置不出事的規則是：正式環境的金鑰不放在研究帳號裡，每個正式服務各有自己的金鑰與預算。參考[一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)。

## 在 ATP Token 上實際比一次

1. 建立一個專案，啟用兩三個想比較的模型，例如 [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/)、[gemini-3-5-flash](https://atptoken.ai/zh-tw/models/gemini-3-5-flash/) 與 [deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/)。
2. 撥少量點數當作這次測試的上限，例如 500 點（5 美元）。
3. 把現有的 OpenAI、Anthropic 或 Google GenAI client 指向閘道，用同一組提示詞跑每個模型。
4. 在請求紀錄裡比較每筆請求的 token 與點數（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。模型並排比較頁見 [/compare](https://atptoken.ai/zh-tw/compare/gemini-vs-gpt/)。

[從快速開始上手](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [OpenRouter 替代方案（團隊版）](https://atptoken.ai/zh-tw/blog/openrouter-vs-enterprise-governance)
- [OpenAI API 與 OpenAI 相容閘道](https://atptoken.ai/zh-tw/blog/openai-api-vs-enterprise-ai-gateway)
- [AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)

## 常見問題

### 什麼是 LLM 閘道？

LLM 閘道是位於應用與模型供應商之間的服務，對外提供一個能呼叫多家模型的 API。依產品不同，它也負責驗證、供應商路由與容錯、請求紀錄、花費上限與模型權限。

### 最好的 LLM 閘道是哪一個？

沒有單一答案，要看你的限制條件。必須自架選 LiteLLM，要最大的代管模型目錄選 OpenRouter，應用在 Vercel 上選 Vercel AI Gateway，想以專案為單位預付預算並設模型白名單選 ATP Token。

### LLM 閘道和 LLM proxy 一樣嗎？

大致一樣。proxy 把請求轉給供應商、維持穩定的 API；閘道是更廣的說法，指同時負責金鑰、預算、模型權限與紀錄的 proxy。

### LiteLLM 免費嗎？

LiteLLM proxy 開源、自架免費；你付的是供應商費用與主機成本。部分功能，例如使用者與金鑰層級的依模型預算，需要 Enterprise 授權。

### 用了閘道還需要供應商帳號嗎？

自架閘道需要，因為它用你的金鑰呼叫供應商。OpenRouter、Vercel AI Gateway、ATP Token 這類代管閘道可以自己計收模型用量，部分也接受你自帶供應商金鑰。

---

Tags: LLM 閘道, AI 閘道, ATP
