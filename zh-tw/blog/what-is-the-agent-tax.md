# 什麼是 agent tax？一步步算出 AI agent 的成本（2026）

> 來源: https://atptoken.ai/zh-tw/blog/what-is-the-agent-tax/
> 發表於: 2026-07-31 · 作者: hung-chien (AI 成長與品牌經理)

AI agent 成本會隨步數增加，因為每一步都重送整段上下文。以牌價試算一個 20 步的 agent，並整理五個降低 agent tax 的做法。

## 重點摘要

- Agent tax 是用多次模型呼叫完成一項工作所多出的 token 成本，因為每次呼叫都會重送不斷變長的上下文。
- 一個 20 步的 agent，基礎上下文 8,000 token、每步增加 2,000 token，總共讀入 540,000 個輸入 token：在 claude-sonnet-4-6 上每項任務約 1.77 美元，單輪對話只要 0.03 美元。
- 把工具輸出先摘要，成本約可減半；專案分配額度則替成本設上限。每項完成任務的成本，要把自己的任務 ID 對應到 request ID 來算。

Agent tax 是 AI agent 為了完成一項工作，每一步都重送整段且不斷變長的上下文，因而多付的 token 成本。單輪對話只為上下文付一次錢；20 步的 agent 要付 20 次，而且每次都比上一次大一點。以下用牌價逐行計算一項 agent 任務，再整理影響最大的五個做法。

| 執行形態 | 輸入 token | 輸出 token | claude-sonnet-4-6 成本 |
|---|---|---|---|
| 單輪對話 | 8,000 | 500 | 0.03 美元 |
| 20 步 agent | 540,000 | 10,000 | 1.77 美元 |
| 20 步 agent，工具輸出先摘要 | 255,000 | 10,000 | 0.92 美元 |

## AI agent 成本怎麼累加：20 步範例

假設一個 agent 每項任務從 8,000 token 的基礎上下文開始（系統提示、工具定義、任務內容）。每一步附加約 2,000 token 的工具結果與模型輸出，每一步寫出 500 個輸出 token。因此第 *i* 步讀入 8,000 + 2,000 × (i − 1) 個輸入 token。

20 步的輸入 token：

Σ = 20 × 8,000 + 2,000 × (0 + 1 + … + 19) = 160,000 + 2,000 × 190 = **540,000 token**

輸出 token：20 × 500 = 10,000。

基礎上下文只占輸入的 30%（540,000 中的 160,000），另外 70% 是同一批工具結果在後面的步驟中被重複讀入。光是最後 8 步就讀了 312,000 token，比前 12 步加起來（228,000）還多。

以 ATP 牌價（每百萬 token，截至 2026 年 10 月）計算：

| 模型（輸入／輸出） | 輸入成本 | 輸出成本 | 每項任務 | 每月 10,000 項任務 |
|---|---|---|---|---|
| [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/)（3／15 美元） | 0.54 × 3 = 1.62 美元 | 0.01 × 15 = 0.15 美元 | 1.77 美元 | 17,700 美元 |
| [gemini-3-5-flash](https://atptoken.ai/zh-tw/models/gemini-3-5-flash/)（1.5／9 美元） | 0.54 × 1.5 = 0.81 美元 | 0.01 × 9 = 0.09 美元 | 0.90 美元 | 9,000 美元 |
| [deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/)（0.2／0.4 美元） | 0.54 × 0.2 = 0.108 美元 | 0.01 × 0.4 = 0.004 美元 | 0.112 美元 | 1,120 美元 |

同樣的基礎上下文若用單輪回答，在 claude-sonnet-4-6 上是 8,000 × 3/M + 500 × 15/M = 0.024 + 0.0075 = 0.0315 美元。Agent 任務約是它的 56 倍。這個倍數就是 agent tax：費率沒變，變的是 token 數量。

Anthropic 公布過一個實際數字：在 Claude Code 中，隊友以 plan 模式執行時，agent teams 的 token 用量約為一般工作階段的 7 倍，因為每個隊友都有自己的上下文視窗（[Claude Code 費用說明](https://code.claude.com/docs/en/costs)）。

## 降低 agent tax 的五個做法

### 1. 限制步數

輸入大致隨步數的平方成長，貴的是後段的步驟。設定硬性上限，達到時回傳明確的失敗。如果同一項任務 12 步就能完成，輸入降到 12 × 8,000 + 2,000 × 66 = 228,000 token，每項任務從 1.77 美元降為 0.77 美元。

### 2. 工具輸出進入上下文前先摘要

把完整檔案內容與完整 API 回應換成簡短摘要，或只留關鍵的幾行。若每步增量從 2,000 降到 500 token，輸入變成 160,000 + 500 × 190 = 255,000 token：0.765 + 0.15 = 每項任務 0.92 美元，少 48%。

### 3. 子步驟改用較便宜的模型

很多步驟只是讀一段工具結果，再決定下一個要呼叫什麼。決策步驟留在 claude-sonnet-4-6，其餘交給 deepseek-v4-flash。以 6 個決策步驟、14 個子步驟、每步平均 27,000 個輸入 token 計：

- Sonnet：162,000 × 3/M + 3,000 × 15/M = 0.486 + 0.045 = 0.531 美元
- Flash：378,000 × 0.2/M + 7,000 × 0.4/M = 0.0756 + 0.0028 = 0.078 美元
- 合計：每項任務約 0.61 美元，比全用 Sonnet 少 66%

切換前先用自己的任務測試品質；[DeepSeek 與 Claude 比較](https://atptoken.ai/zh-tw/compare/deepseek-vs-claude/)可以當起點。

### 4. 在供應商支援時使用 prompt caching

Agent 的大部分輸入，是上一步已經送過的前綴。在 Anthropic 自家 API 上，快取讀取的費率是基本輸入的 0.1 倍，5 分鐘快取寫入是 1.25 倍（[Anthropic 定價](https://platform.claude.com/docs/en/about-claude/pricing)）。在 20 步範例中，540,000 個輸入 token 有 494,000 個是重複內容。以 Anthropic 的 Sonnet 4.6 費率計，是 494,000 × 0.30/M + 46,000 × 3.75/M + 0.15 美元輸出 = 0.148 + 0.173 + 0.15，每項任務約 0.47 美元。快取有存活時間，等待慢速工具的步驟可能錯過快取。要依賴這個做法前，先確認你的供應商如何計算快取 token。

### 5. 給每個 agent 獨立的預算

把每個 agent 放進自己的專案，並分配點數給它。專案只能花被分配到的額度，餘額用完後請求會回傳 `402`，卡住的迴圈會停在上限，而不是拖到月底才被發現。每月 10,000 項 Sonnet 任務，分配額度就是 1,770,000 點（1 點 = 0.01 美元）。設定方式見[設定有預算上限的團隊](https://atptoken.ai/zh-tw/docs/cb-budget-caps)。

## 如何衡量每項完成任務的成本

閘道看得到請求，但只有你的應用程式知道哪些請求屬於同一項任務。ATP 的每個回應都帶有 `x-request-id` 標頭。把它和你自己的任務或工作階段 ID、步驟編號，以及任務最後是否成功一起記錄。

接著：

1. 從請求紀錄取出這些 request ID 對應的列，每列顯示模型、狀態與輸入／輸出 token（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。紀錄保留 7 天，請每週用[請求紀錄 API](https://atptoken.ai/zh-tw/docs/console-api-logs) 匯出。
2. 把 token 乘上模型牌價，依任務加總。
3. 用總成本（包含失敗與中途放棄的任務）除以完成的任務數。

失敗的任務要算進分子。成功率 80%、每次嘗試 1.77 美元的 agent，每項完成任務的成本是 1.77 / 0.8 = 2.21 美元。

紀錄裡要留意一種模式：內容為空的 `200`。在推理模型上，這通常代表 `max_tokens` 不足以涵蓋思考預算。ATP 通常會回報零用量、不扣點數，但沒有調高 `max_tokens` 就重試的 agent，會一直重複這個空回應（[錯誤](https://atptoken.ai/zh-tw/docs/errors)）。

[了解計價方式](https://atptoken.ai/zh-tw/pricing)

## 延伸閱讀

- [Claude Code 費用怎麼算：每位開發者一天多少錢，以及 10 項控管](https://atptoken.ai/zh-tw/blog/coding-agents-cost-control-checklist)
- [為什麼 LLM 成本在上線後暴增](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live)
- [怎麼讀懂 AI 帳單](https://atptoken.ai/zh-tw/blog/how-to-read-your-ai-bill)

## 常見問題

### 跑一個 AI agent 要花多少錢？

主要取決於步數與上下文增長，而不是每 token 的單價。一個從 8,000 token 開始、每步增加 2,000 token 的 20 步 agent，會讀入 540,000 個輸入 token、寫出 10,000 個輸出 token，以每百萬 token 3／15 美元計，每項任務約 1.77 美元。

### 為什麼 AI agent 比一般對話 API 貴？

對話 API 只送一次上下文。Agent 每一步都會再送一次，而且每次都附上新的工具結果，所以輸入 token 大致隨步數的平方成長。

### 怎麼計算每項任務的 AI agent 成本？

輸入 token 總和 = 基礎 × 步數 + 增量 × (0 + 1 + … + 步數 − 1)，再加上輸出 token，各自乘上模型費率。正式環境中，把自己的任務 ID 與每個 request ID 一起記錄，再用總成本除以完成的任務數。

### 怎麼降低 AI agent 的 token 成本？

限制步數、工具輸出進入上下文前先摘要、子步驟改用較便宜的模型、在供應商以較低費率計算快取讀取時使用 prompt caching，並給每個 agent 專案獨立的點數分配。

---

Tags: Agent tax, AI agent 成本, ATP
