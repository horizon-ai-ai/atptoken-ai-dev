# AI API 花費上限比較：OpenAI、Anthropic、OpenRouter、Vercel 與 ATP Token（2026）

> 來源: https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work/
> 發表於: 2026-08-12 · 作者: hung-chien (AI 成長與品牌經理)

AI API 花費上限比較：OpenAI 用量限制、Claude 工作區上限、OpenRouter、Vercel 與 ATP Token 到達上限時各回傳什麼，附一份實際預算拆分。

## 重點摘要

- 同樣叫花費上限，行為各不相同：OpenAI 硬上限回傳 429，Anthropic 工作區上限回傳 400，Vercel 與 OpenRouter 金鑰上限回傳 402，OpenRouter guardrail 回傳 403。
- 重置週期也不同：OpenAI 與 Anthropic 按月重置，OpenRouter 與 Vercel 可選每日、每週或每月，ATP Token 的專案分配不會重置，直到你再撥點數。
- 按工作負載拆預算：每月 USD 2,000 等於 200,000 點，分給正式環境客服機器人、staging 專案、coding agent 沙盒，並保留一筆未分配的備用額度。

AI API 花費上限，是一把金鑰、一個專案、工作區或組織在平台停止服務其請求之前，最多能花掉的模型用量。上限設在哪一層，跟金額本身一樣重要：下面比較的五個地方，在範圍、重置週期，以及到達上限時程式收到的 HTTP 狀態碼上都不一樣。本文整理截至 2026 年 10 月的狀況，最後用 ATP Token 點數拆一份每月 USD 2,000 的預算，算式全部列出。

## AI API 花費上限一覽

| 設定位置 | 範圍 | 重置 | 到達上限時 | 狀態碼 |
|---|---|---|---|---|
| [OpenAI API](https://developers.openai.com/api/docs/guides/rate-limits) | 組織或專案 | 每月 | 花費提醒：只通知，流量照常。硬上限：受影響的請求失敗 | 429 |
| [Anthropic Console](https://platform.claude.com/docs/en/api/rate-limits) | 組織或工作區（工作區上限不能超過組織上限） | 每月 | 請求被拒，直到調高上限或當月結束 | 自訂上限 400；等級上限 429 |
| [OpenRouter guardrails](https://openrouter.ai/docs/guides/features/guardrails) | 每位成員或每把金鑰 | 每日、每週或每月 | 請求被拒 | 403 |
| [OpenRouter 金鑰點數上限](https://openrouter.ai/docs/api-reference/limits) | 每把金鑰 | 每日、每週、每月或不重置 | 請求被拒 | 402 |
| [Vercel AI Gateway 預算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets) | 團隊、專案、金鑰或團隊成員 | 每日、每週、每月或不重置 | 軟上限：跨過上限的那一筆會完成，之後的請求被拒 | 402 |
| [ATP Token](https://atptoken.ai/zh-tw/docs/credits) | 專案，點數由組織、工作區一路撥到專案 | 不重置；分配會一直留著，直到花完或被移走 | 專案餘額用盡後請求被拒 | 402 |

工程師最常略過的是狀態碼那一欄，而它決定了用戶端接下來怎麼做。429 看起來像一般的速率限制，多數 SDK 會自動重試。Anthropic 文件特別註明，花費等級上限的 429 不帶 `retry-after` 標頭，在恢復之前重試都會失敗。402 或 400 重試也不會成功。用戶端應該讀錯誤內容，然後停下來。

## 各平台怎麼執行花費上限

### OpenAI：專案花費上限

OpenAI 建議把 staging 與正式環境分成不同專案，並且可以[替每個專案設定自訂的速率與花費上限](https://developers.openai.com/api/docs/guides/production-best-practices)。在專案的 Limits 設定裡，可以設定每月花費上限、通知門檻，以及這個專案能用哪些模型（[OpenAI Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)）。

花費提醒會發通知，流量照常。硬性花費上限會讓受影響的請求回傳 429。兩者之上還有用量等級：Tier 1 每月 USD 100，Tier 5 每月 USD 200,000。要注意的是狀態碼共用。處理速率限制的重試迴圈，如果不檢查錯誤內容，會一直打一個預算已經用完的專案。

### Anthropic Console：工作區花費上限

Claude Console 的[工作區](https://platform.claude.com/docs/en/manage-claude/workspaces)各自有每月花費上限與速率上限，只能設得比組織低，不能更高。API 金鑰可以限定在單一工作區。Default Workspace 無法設定上限，所以想被管住的金鑰要放在具名的工作區。

到達你自己設定的上限時，請求回傳 HTTP 400（`invalid_request_error`），訊息會寫何時恢復。等級上限（Start 每月 USD 500、Build USD 1,000、Scale USD 200,000）則回傳 429，用量暫停到下個月 1 日 00:00 UTC。Console 自動建立的 Claude Code 工作區，是唯一支援每位使用者每月花費上限的工作區。

### OpenRouter：guardrails 與單一金鑰點數上限

OpenRouter 有兩套機制。Guardrails 由組織管理員針對成員或金鑰設定，可帶一個每日、每週或每月重置的美元花費上限；超過的請求收到 403。Guardrail 也能放模型白名單與供應商白名單，多個 guardrail 同時適用時，以最嚴格的規則為準。

單一金鑰點數上限所有方案都能用。每把金鑰有 `limit` 與 `limit_reset`（每日、每週、每月或不重置），在 UTC 午夜重置。額度用完的金鑰回傳 402。工作區層級預算則是 Enterprise 功能（[OpenRouter 部落格](https://openrouter.ai/blog/insights/governing-team-ai-spend/)）。

### Vercel AI Gateway：疊加的預算

Vercel 的預算有四種範圍（團隊、專案、API 金鑰、團隊成員），而且會疊加，一筆請求必須通過範圍內的每一個預算。重置週期可選每日、每週、每月或不重置，皆以 UTC 計。超過預算回傳 402 與 `quota_for_entity_exceeded`，訊息會寫出是哪個範圍用完。

Vercel 把預算定位為軟上限：檢查發生在每筆請求開始時，所以跨過上限的那一筆仍會完成。可選的 email 提醒在 50%、75%、100% 觸發。有兩個細節容易踩到：API 金鑰的花費永遠不會算進專案預算（專案預算只看該專案部署的 OIDC token），BYOK 的花費也不計入任何預算。

### ATP Token：每個專案的預付分配

在 ATP Token，上限就是錢本身。點數（1 點 = USD 0.01）由組織撥到工作區、再撥到專案，每把金鑰都從自己專案的餘額扣。專案只能花掉分配給它的額度。餘額用盡時，閘道在計量階段以 402 拒絕請求（[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)）。花超過分配額度的專案會被標示為 In debt，直到補足為止。

這裡沒有重置週期。隨用隨付點數不會過期，沒用完的分配會留到下個月。所以月預算需要每月做一次分配，或使用專案自動儲值：隨用隨付的專案在餘額低於門檻時自動補點，受單次扣款上限與每月扣款上限約束。開啟自動儲值後，真正的天花板是那個每月扣款上限。

## 團隊願意遵守的上限設計原則

1. **每個工作負載分開設上限。** 每個正式服務一個專案，staging 一個，每個沙盒一個。組織層級的總上限一觸發，所有產品會一起停，包括正常運作的那些。金鑰的部分請見[一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)。
2. 在用戶端程式裡把預算錯誤當成終止狀態。402、Anthropic 的 400 上限錯誤、花費上限造成的 429，都對應到「停止並通知負責人」，不要套用指數退避重試。
3. 每個上限都從單位成本推算。每筆請求的 token 數乘上模型費率，再乘上預估量，得到一個能向財務說明、流量變了也能調整的數字。
4. 在最上層保留未分配的備用額度。正式環境如果在 27 號見底，管理員幾分鐘內就能撥點過去，不必動到 staging。
5. 每週對照一次 Allocated 與 Consumed。ATP Token 的[用量頁面](https://atptoken.ai/zh-tw/docs/spend)在每一層都同時顯示兩者。想要自動警示的話，可以從 [Console API](https://atptoken.ai/zh-tw/docs/console-api-usage) 輪詢專案即時餘額，發到你自己的頻道。

## 實際算一次：每月 USD 2,000 的 AI 預算換成點數

USD 2,000 等於 200,000 點。以下是拆給三個工作負載加一筆備用額度的一種做法。

| 專案 | 工作區 | 允許的模型 | 分配 | 可以支撐 |
|---|---|---|---|---|
| support-bot-prod | Production | [claude-haiku-4-5](https://atptoken.ai/zh-tw/models/claude-haiku-4-5/) | 140,000 點（USD 1,400） | 約 400,000 則回覆 |
| support-bot-staging | Pre-production | claude-haiku-4-5 | 10,000 點（USD 100） | 約 28,500 次測試呼叫 |
| coding-agent-sandbox | Engineering | [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/) | 30,000 點（USD 300） | 約 23 個開發者工作天 |
| 未分配備用額度 | 組織 | 無 | 20,000 點（USD 200） | 緊急補點 |

客服機器人。claude-haiku-4-5 的 ATP 牌價是每百萬輸入 token USD 1、每百萬輸出 token USD 5。一則典型回覆用 2,000 個輸入 token、300 個輸出 token，成本是 2,000 × 1 / 1,000,000 + 300 × 5 / 1,000,000 = USD 0.0035，也就是 0.35 點。140,000 點 ÷ 0.35 = 每月 400,000 則回覆，約每天 13,300 則。

整個週末都在跑的 staging 任務。假設一個重試 bug 每秒打 5 次請求，每次一樣 0.35 點，等於每秒燒掉 1.75 點，10,000 點的 staging 分配大約撐 10,000 ÷ 1.75 ≈ 5,700 秒，約 95 分鐘。接著 staging 收到 402，正式環境照常回覆客戶。如果沒有拆開，同一個迴圈從週五 18:00 跑到週一 09:00（63 小時，226,800 秒），會花掉 226,800 × 1.75 = 396,900 點，幾乎是整個月預算的兩倍。

Coding agent。Anthropic 公布的 Claude Code 平均成本是[每位開發者每個活躍日約 USD 13](https://code.claude.com/docs/en/costs)。照這個平均，USD 300 約可支撐 23 個開發者工作天，大約是一位開發者一個月的工作日。沙盒在下午撞到 402 時，先看那個 session 在做什麼，再決定要不要補點。為什麼 agent 每項任務比單次呼叫貴，請見[什麼是 agent 稅](https://atptoken.ai/zh-tw/blog/what-is-the-agent-tax)。

下個月 1 日不會重置任何東西。如果客服機器人用掉 120,000 點，它還有 20,000 點；再撥 120,000 點就回到 140,000。

## 在 ATP Token 上怎麼設定

1. 建立 Team 組織，再到 Resources 頁面建立工作區（Production、Pre-production、Engineering）（[設定組織](https://atptoken.ai/zh-tw/docs/console-setup)）。
2. 建立每個專案並選擇允許的模型，每個專案至少一個（[工作區與專案](https://atptoken.ai/zh-tw/docs/resources)）。
3. 沿著樹狀結構分配點數：組織、工作區、專案。備用額度留在組織層，不要分出去。
4. 每個專案發一把金鑰，金鑰繼承該專案的模型與餘額（[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。
5. 在用戶端把 402 視為「預算用盡」，並通知專案負責人（[常見回應](https://atptoken.ai/zh-tw/docs/errors)）。

[設定有預算上限的團隊](https://atptoken.ai/zh-tw/docs/cb-budget-caps)

## 延伸閱讀

- [為什麼 AI 帳單上線後會爆](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live)
- [一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)
- [Coding agent 成本控管清單](https://atptoken.ai/zh-tw/blog/coding-agents-cost-control-checklist)

## 常見問題

### OpenAI 的用量限制有哪些？

有兩種。用量等級（usage tier）替組織設定每月上限，Tier 1 為每月 USD 100，Tier 5 為 USD 200,000；另外你可以替組織或單一專案設定自己的花費上限。花費提醒只會通知，流量照常；硬性花費上限會讓受影響的請求回傳 429。

### Claude API 可以設定花費上限嗎？

可以。在 Claude Console 可替組織與每個工作區設定每月花費上限，工作區上限不能高於組織上限，Default Workspace 無法設定。到達自己設定的上限時，請求會回傳 HTTP 400（invalid_request_error），直到調高上限或進入下個月。

### AI API 金鑰到達花費上限時會怎樣？

看平台而定。OpenAI 硬上限回傳 429，Anthropic 自訂上限回傳 400，Vercel AI Gateway 預算與 OpenRouter 單一金鑰點數上限回傳 402，OpenRouter guardrail 預算回傳 403，ATP Token 在專案餘額用盡時回傳 402。重試邏輯應把這些都當成停止訊號。

### ATP Token 的花費上限會每月重置嗎？

不會。ATP Token 專案只能花掉分配給它的點數，而隨用隨付點數不會過期，沒用完的分配會留到下個月。要做月預算，就每月重新分配一次，或開啟專案自動儲值並設定每月扣款上限。

### staging 和實驗應該跟正式環境共用 AI 預算嗎？

不應該。替 staging 和沙盒各開一個專案或工作區，給小額上限。staging 的重試迴圈會先撞到自己的上限而停下，正式環境繼續服務。

---

Tags: AI API 花費上限, OpenAI 用量限制, AI 預算, ATP
