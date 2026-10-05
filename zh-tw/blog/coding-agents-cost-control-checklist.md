# Claude Code 費用怎麼算：每位開發者一天多少錢，以及 10 項控管（2026）

> 來源: https://atptoken.ai/zh-tw/blog/coding-agents-cost-control-checklist/
> 發表於: 2026-08-14 · 作者: hung-chien (AI 成長與品牌經理)

Claude Code 費用平均約每位開發者每個活躍日 13 美元。以 25 人團隊試算月預算，並列出 10 項把 coding agent 花費控制在上限內的做法。

## 重點摘要

- Anthropic 公布的 Claude Code 平均費用約為每位開發者每個活躍日 13 美元、每月 150–250 美元，90% 使用者每個活躍日低於 30 美元。
- 25 位開發者、每月 20 個活躍日，基準是每月 6,500 美元；其中 5 位重度使用者用量加倍，就變成 7,800 美元。
- 十項控管：獨立專案、每人一把金鑰、以分配額度當上限、只開 Sonnet 的白名單、固定預設模型、工作階段習慣、無人值守執行的預算、agent teams 改為申請制、每週查請求紀錄、離職即撤銷。

團隊的 Claude Code 費用，是開發者工作時 CLI 送出每個請求所累積的 token 帳單；Anthropic 公布的平均值約為每位開發者每個活躍日 13 美元。本文把這個數字換算成 25 人團隊的月預算，算出少數重度使用者會多出多少，並列出十項控管與各自的實際設定。

| 問題 | 簡答 |
|---|---|
| 每位開發者平均費用 | 每個活躍日約 13 美元，每月 150–250 美元 |
| 常見上緣 | 90% 使用者每個活躍日低於 30 美元 |
| 25 位開發者、20 個活躍日 | 每月基準 6,500 美元 |
| 同一團隊、5 位重度使用者用量加倍 | 每月 7,800 美元 |
| 最可避免的花費來源 | 沒清除的長工作階段、Opus 當預設、agent teams |

## Claude Code 怎麼計費

截至 2026 年 10 月，Anthropic 的 [Claude Code 費用說明頁](https://code.claude.com/docs/en/costs)指出，在企業部署中，平均費用約為每位開發者每個活躍日 13 美元、每月 150–250 美元，且 90% 使用者每個活躍日低於 30 美元。Anthropic 建議先用小規模試行團隊建立自己的基準，再擴大導入。

費用怎麼落到你身上，取決於開發者用什麼方式登入。Pro 與 Max 訂閱已包含用量。Team 與 Enterprise 方案的每位成員使用每個席位的額度，依滾動 5 小時與每週兩個區間重置，並與 Claude 對話共用；只有管理員開啟 usage credits 後，成員才能超過額度繼續使用。透過 Claude Console、雲端供應商，或 ATP Token 這類閘道使用時，Claude Code 按 token 向組織計費。

本文討論的是按 token 計費的情況：除了你自己設的上限，沒有任何東西會讓工作階段停下來。

## 25 人團隊的 Claude Code 費用試算

假設 25 位開發者每月 20 個工作天都使用 Claude Code，以 Anthropic 的平均 13 美元計算：

25 位開發者 × 20 個活躍日 × 13 美元 = **每月 6,500 美元**

換算每人 260 美元，略高於 Anthropic 的每月 150–250 美元區間，因為 20 個活躍日假設每個人每個工作天都在用。

平均值會掩蓋長尾。假設其中 5 位開發者常開長工作階段或同時跑多個實例，費用是平均的 2 倍（每個活躍日 26 美元）：

| 情境 | 算式 | 每月費用 | ATP 點數 |
|---|---|---|---|
| 基準 | 25 × 20 × 13 美元 | 6,500 美元 | 650,000 |
| 5 位重度使用者 2 倍 | (20 × 20 × 13) + (5 × 20 × 26) = 5,200 + 2,600 美元 | 7,800 美元 | 780,000 |
| 再加一週 agent team | 7,800 美元 + 5 天 × (91 − 13 美元) | 8,190 美元 | 819,000 |

最後一列假設一位一般用量的開發者連續 5 天使用 agent team。Anthropic 表示，隊友在 plan 模式下執行時，agent teams 的 token 用量約為一般工作階段的 7 倍，因此每天是 7 × 13 = 91 美元，而不是 13 美元。ATP Token 以點數計費，1 點 = 0.01 美元。

## 控管 Claude Code 花費的 10 項做法

### 1. 給 coding agent 獨立的專案

建立一個只給 Claude Code（以及其他 coding agent）使用的專案，與正式服務的專案分開。同一專案內的每把金鑰都從該專案餘額扣款，所以整晚跑迴圈的 agent 不會把面向客戶服務的預算用光。做法見[一個專案，一把金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)。

### 2. 在專案內每位開發者一把金鑰

金鑰只屬於一個專案，並繼承該專案的允許模型與餘額。每人一把金鑰，用量頁就能依金鑰顯示點數與 token，不用另外接工具就看得到每個人的花費。金鑰以 `atp-` 開頭，完整金鑰只顯示一次（[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。

### 3. 把分配額度當成每月上限

把上表中含重度使用者的數字，也就是 780,000 點，分配給這個專案。專案只能花被分配到的額度；餘額用完後，請求會回傳 `402`，直到管理員再分配。若開啟專案的自動儲值，也要設定每月上限，否則上限就不再是上限。設定步驟見[設定有預算上限的團隊](https://atptoken.ai/zh-tw/docs/cb-budget-caps)。

### 4. 白名單只開 claude-sonnet-4-6，Opus 放另一個專案

主要的 coding 專案只啟用 [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/)。以 ATP 牌價計，它是每百萬 token 輸入 3 美元、輸出 15 美元；[claude-opus-4-8](https://atptoken.ai/zh-tw/models/claude-opus-4-8/) 則是 5 美元與 25 美元，每個 token 約貴 1.67 倍。若有人切換到專案未允許的模型，閘道會在請求抵達任何供應商之前回傳 `403`。需要用 Opus 做架構設計的開發者，另開第二個專案並給較小的額度，例如 50,000 點。

### 5. 固定 ANTHROPIC_MODEL

在每位開發者的環境變數，或 `~/.claude/settings.json` 的 `env` 區塊中設定 `ANTHROPIC_MODEL="claude-sonnet-4-6"`。`--model` 參數會在單一工作階段覆蓋 `ANTHROPIC_MODEL`，所以固定模型只決定預設，真正的限制靠第 4 項的白名單。

### 6. 養成 /usage 與 /clear 的習慣

`/usage` 的 Session 區塊會顯示 token 用量，以及 Claude Code 在本機依牌價估算的金額；專案實際被扣多少，以 ATP 用量頁為準。Anthropic 建議的省錢習慣：

- 切換到不相關的工作時執行 `/clear`。舊的上下文會隨每則訊息重送，而 `/clear` 本身不花錢。
- 簡單任務用 `/effort` 調低思考強度。思考 token 以輸出 token 計費。
- 讓 `CLAUDE.md` 保持精簡，把專門指示移到需要時才載入的 skills。

### 7. 無人值守的執行用 --max-budget-usd 與 --max-turns 設限

針對 CI 與腳本，Claude Code 的 [CLI 參考文件](https://code.claude.com/docs/en/cli-reference)列出兩個 print 模式參數：`--max-budget-usd` 會在估算花費（含 subagent）達到金額時停止；`--max-turns` 在固定的 agent 回合數後結束。

```
claude -p --max-budget-usd 5.00 --max-turns 30 "fix the failing tests in src/auth"
```

這是用戶端的單次停止點。對那種整晚重試修 flaky test 的工作，專案分配額度仍是伺服器端的上限。

### 8. Agent teams 改為申請制

Agent teams 預設關閉，用 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 開啟。在 plan 模式下 token 用量約為一般工作階段的 7 倍，一位開發者跑 agent team 的花費，約等於七位開發者的一般用量。把它放在有獨立額度的另一個專案，並請團隊讓隊友使用 Sonnet、任務完成就關閉隊友。

### 9. 每週從請求紀錄檢視花費

每週一打開用量頁，依金鑰與模型排序，再看同一週的請求紀錄。每一列顯示時間、範圍、模型、狀態、request ID 與輸入／輸出 token。請求紀錄保留 7 天，所以每週檢視是不漏掉任何請求的最長間隔；要保存歷史，可用[請求紀錄 API](https://atptoken.ai/zh-tw/docs/console-api-logs) 匯出。留意用量超過團隊中位數 2 倍的金鑰、計畫外的模型，以及連續出現的 `4xx` 或 `5xx`。

### 10. 離職時撤銷金鑰

約聘人員離開時，在 API 金鑰頁撤銷他的金鑰。被撤銷的金鑰立即失效，並留在清單中供稽核；因為每人一把金鑰，其他人的工作階段不受影響。

第 6 到第 8 項背後的成本結構，見[什麼是 agent tax](https://atptoken.ai/zh-tw/blog/what-is-the-agent-tax)；哪種工作該開哪個模型，見[最適合寫程式的 LLM 指南](https://atptoken.ai/zh-tw/guides/best-llm-for-coding/)。

## 在 ATP Token 上設定 Claude Code

### 步驟 1：建立專案與分配額度

在主控台建立工作區，以及以團隊命名的專案（例如 `claude-code-platform`），只啟用 `claude-sonnet-4-6`，並分配每月點數。

### 步驟 2：每位開發者發一把金鑰

從專案為每個人建立一把金鑰，透過密碼管理工具交給本人。完整金鑰只會顯示一次。

### 步驟 3：把 Claude Code 指向閘道

Base URL 不加 `/v1`，因為 Claude Code 會自己補上 `/v1/messages`。把 `ANTHROPIC_API_KEY` 清空，避免它優先生效。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

同樣的值也可以寫在 `~/.claude/settings.json` 的 `env` 區塊。

### 步驟 4：確認

執行一次提示，再打開主控台：請求會出現在請求紀錄，花掉的點數會出現在用量頁。完整步驟見[在 ATP 上執行 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code)。

## 延伸閱讀

- [什麼是 agent tax？一步步算出 AI agent 的成本](https://atptoken.ai/zh-tw/blog/what-is-the-agent-tax)
- [真正有效的 AI 花費上限](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)
- [一個專案，一把金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)

## 常見問題

### Claude Code 每位開發者要花多少錢？

Anthropic 表示，在企業部署中平均約為每位開發者每個活躍日 13 美元、每月 150–250 美元，90% 使用者每個活躍日低於 30 美元。實際數字主要取決於模型選擇，以及每個人同時開幾個工作階段。

### Claude Code 是按訂閱收費，還是按 API 用量收費？

兩種都有。Pro 與 Max 訂閱已包含用量；Team 與 Enterprise 成員使用每個席位的額度，依滾動 5 小時與每週兩個區間重置。透過 Claude Console、雲端供應商或閘道使用時，則按 token 計費。

### 怎麼幫 Claude Code 設花費上限？

把 Claude Code 的流量放進獨立專案，並分配固定點數給它；分配額度就是上限，餘額用完後請求會回傳 402。以腳本執行時，可再加上 Claude Code 在 print 模式下的 --max-budget-usd 參數，作為單次執行的停止點。

### Claude Code 可以用 API 金鑰代替訂閱嗎？

可以。把 ANTHROPIC_BASE_URL 指到閘道，專案金鑰放進 ANTHROPIC_AUTH_TOKEN，ANTHROPIC_API_KEY 設為空字串避免它優先生效，再把 ANTHROPIC_MODEL 固定為專案允許的模型。

### 為什麼 Claude Code 的帳單比預期高？

Anthropic 自己的說明指出，API 花費意外偏高，通常來自從未清除的長工作階段，或把 Opus 留成預設模型。Agent teams 也是來源之一：隊友在 plan 模式下執行時，token 用量約為一般工作階段的 7 倍。

---

Tags: Claude Code, Coding agents, ATP
