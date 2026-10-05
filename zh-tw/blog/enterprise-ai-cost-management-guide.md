# LLM 成本優化：企業 AI 成本管理指南與 10 個降本槓桿（2026）

> 來源: https://atptoken.ai/zh-tw/blog/enterprise-ai-cost-management-guide/
> 發表於: 2026-08-05 · 作者: hung-chien (AI 成長與品牌經理)

LLM 成本優化怎麼做：企業 AI 成本管理的四層做法、10 個有出處或實算效果的槓桿、依任務挑選模型，以及 30 天導入計畫。

## 重點摘要

- LLM 成本管理分四層：每次請求的價格、單一結算單位、每把金鑰都有負責人、每個專案都有上限。每一層都有一個這個月就能設好的做法。
- 影響最大的槓桿是模型選擇與輸出長度。以 ATP 牌價計算，一則客服回覆從 claude-sonnet-4-6 換到 claude-haiku-4-5，成本從 $0.010032 降到 $0.003344，前提是品質守得住。
- OpenAI 與 Anthropic 的 Batch API 把非同步工作定價為標準價的 50%，Anthropic 的快取讀取是基本輸入的 0.1 倍。直接呼叫原廠時可以善用。

LLM 成本管理，是對公司在語言模型上的花費做計價、歸屬與設上限；LLM 成本優化，則是在品質不降的前提下，壓低每個有用輸出的花費。這篇整理四層做法並各給一個具體動作，附上 10 個成本優化槓桿表、依任務挑模型的建議，以及 30 天導入計畫。

文中模型單價都是模型頁上的 ATP 牌價，截至 2026 年 10 月。原廠計價資訊都連到原廠自己的頁面。

| 層 | 先設好的做法 | ATP 文件 |
|---|---|---|
| 1. Token 經濟 | 為前三大請求型態算出每 1,000 次的成本 | [計價模式](https://atptoken.ai/zh-tw/docs/pricing-model) |
| 2. 點數 | 用點數編列單月預算，再分到各工作區 | [點數怎麼運作](https://atptoken.ai/zh-tw/docs/credits) |
| 3. 歸屬 | 每個服務、每個環境各一個專案與金鑰 | [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys) |
| 4. 上限與覆核 | 每個專案分配固定預算，每週看用量 | [預算上限設定](https://atptoken.ai/zh-tw/docs/cb-budget-caps) |

## 第一層：token 經濟

做法：在爭論月總額之前，先把佔大部分流量的三種請求型態，算出每 1,000 次的成本。

一則客服回覆在 claude-sonnet-4-6（每 100 萬 token $3 / $15）上用 1,284 個輸入與 412 個輸出 token，成本是 1,284 × 3 ÷ 1,000,000 + 412 × 15 ÷ 1,000,000 = $0.010032，每 1,000 次 $10.03。每月 30 萬則就是 $3,009.60。每種型態都有這個數字後，下面每個槓桿都能換算成金額。完整算法與五個模型並排比較，見 [LLM token 成本怎麼算](https://atptoken.ai/zh-tw/blog/how-to-read-your-ai-bill)。

## 第二層：以點數作為結算單位

做法：用點數編列單月預算，沿階層往下分配，讓財務對同一種單位對帳，工程仍保有模型層級的細節。

在 ATP Token 上，1 點 = 0.01 美元。一個月 $3,000 就是 30 萬點，也就是三次 1,000 美元的 Scale 儲值。點數沿組織 → 工作區 → 專案流動，每一層都顯示 Available、Received、Allocated、Consumed。隨用隨付的點數不會過期，儲值不可退款，所以依當月需要儲值，不必一次備足一年。

## 第三層：用專案與金鑰確立歸屬

做法：每個服務、每個環境各一個專案，各自一把金鑰。

六個服務、分測試與正式環境，就是 12 個專案、12 把金鑰。一把金鑰只屬於一個專案，並沿用該專案的可用模型與點數餘額，所以用量頁「依金鑰」的拆分，直接就是「依負責人」的花費。外包人員離開時，撤銷他那個專案的金鑰會立即生效，其他 11 個服務照常運作。做法說明見[一個專案一把金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)。

## 第四層：上限與每週覆核

做法：每個專案都給固定分配額，每週看一次用量。

專案只能花它被分配到的點數。分配 5,000 點的測試專案，上限就是 $50：餘額用完時呼叫回傳 `402`，花超過分配額的專案會被標示 In debt，直到補足點數。整個週末跑不停的測試排程，損失大約就是 $50。

覆核方面，ATP 的[請求紀錄](https://atptoken.ai/zh-tw/docs/monitoring)保留 7 天的逐筆資料（模型、狀態、輸入與輸出 token、請求 ID），每週看一次，就能在細節還在時抓到異常。月底對帳用[帳務事件](https://atptoken.ai/zh-tw/docs/console-api-billing)，這份 90 天帳本才是計費依據。

## 10 個 LLM 成本優化槓桿

效果不是引用原廠定價頁，就是用上面的客服回覆例子實算（claude-sonnet-4-6 上輸入 1,284 / 輸出 412，$0.010032）。

| # | 槓桿 | 典型效果 | 在哪裡設定 |
|---|---|---|---|
| 1 | 依任務選模型 | claude-haiku-4-5（$1 / $5）處理同一請求為 $0.003344，是 claude-sonnet-4-6 的三分之一 | 程式中的模型 ID；專案可用模型 |
| 2 | 限制輸出長度 | 輸出從 412 降到 250 token，每次省 $0.00243（24%） | `max_tokens`、回覆格式、提示指示 |
| 3 | 設定推理預算 | 1,500 個 thinking token 每次多 $0.0225，因為推理按輸出計費 | 推理強度或 thinking 預算參數 |
| 4 | 精簡上下文 | 每一輪都帶 20,000 token 文件，輸入每輪 $0.06；改帶 2,000 token 的檢索片段是 $0.006 | 應用程式的上下文組裝 |
| 5 | 使用原廠提示快取 | Anthropic 快取讀取為基本輸入的 0.1 倍（[Anthropic 定價](https://platform.claude.com/docs/en/about-claude/pricing)）；OpenAI 列出 GPT-5.5 快取輸入 $0.50，一般輸入 $5 | 原廠快取設定，直接呼叫原廠時 |
| 6 | 非同步工作改用批次 | OpenAI 的 Batch 與 Flex 為標準價的 50%（[OpenAI 定價](https://developers.openai.com/api/docs/pricing)）；Anthropic Batch API 為標準價的 50% | 原廠 Batch API，用於評測、回補、夜間排程 |
| 7 | 專案只開放需要的模型 | 為 gpt-5.6-luna（輸出 $6）建的專案，叫不到 gpt-5.5（輸出 $30），輸出單價差 5 倍 | ATP 專案可用模型；其他模型回傳 `403` |
| 8 | 每個專案固定分配額 | 分配 5,000 點的測試專案約在 $50 停下 | ATP 資源頁的分配樹 |
| 9 | 限制 agent 步數與重試 | 10 步、每步重送 30,000 token = 30 萬輸入 token = 每項任務 $0.90；5 步 = $0.45 | Agent 框架設定 |
| 10 | 每週覆核並清理閒置金鑰 | 沒有固定百分比；在 7 天請求細節還在時找出花最多的金鑰 | 用量頁依金鑰檢視；API 金鑰頁 |

槓桿 1 到 4 與 9 適用任何供應商。槓桿 5 與 6 是原廠各自規則的計價方案，要逐家估算。槓桿 7、8、10 是在 ATP 主控台設定的控制。

## 依任務挑選模型

槓桿 1 通常省最多，但要先做評測。把每個工作負載的 50 到 100 則真實提示，丟給兩到三個候選模型，比完品質再轉移流量。

| 工作負載 | 候選模型（ATP 牌價，每 100 萬 token 輸入 / 輸出） | 並排比較頁 |
|---|---|---|
| 大量分類、路由、標籤 | qwen-3-7-flash $0.03 / $0.13；[deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/) $0.20 / $0.40 | [Qwen vs DeepSeek](https://atptoken.ai/zh-tw/compare/qwen-vs-deepseek/) |
| 客服回覆與內部助理 | claude-haiku-4-5 $1 / $5；gemini-3-5-flash $1.50 / $9；claude-sonnet-4-6 $3 / $15 | [Gemini vs GPT](https://atptoken.ai/zh-tw/compare/gemini-vs-gpt/) |
| 寫程式與長推理 | [claude-opus-4-8](https://atptoken.ai/zh-tw/models/claude-opus-4-8/) $5 / $25；gpt-5.5 $5 / $30；deepseek-v4-pro $2.40 / $4.80 | [DeepSeek vs Claude](https://atptoken.ai/zh-tw/compare/deepseek-vs-claude/)、[最適合寫程式的 LLM](https://atptoken.ai/zh-tw/guides/best-llm-for-coding/) |

不同模型的 token 數也不一樣。Anthropic 指出 Claude 4.7 以後的 tokenizer，同樣文字大約多產生 30% 的 token，所以要用自己的提示比成本，單看價目表不準。

## Agent：衡量每次完成任務的成本

寫程式或做研究的 agent，一項工作會發出很多次請求，每一步都可能重送完整上下文。Anthropic 表示 Claude Code 平均每位開發者每個活躍日約 $13，每月約 $150 到 $250；在 plan mode 下，agent teams 的 token 用量約是一般工作階段的 7 倍（[Claude Code 成本](https://code.claude.com/docs/en/costs)）。

每次請求成本持平，每項任務成本卻可能一路上升，所以兩個都要追。Agent 放在自己的專案、用自己的分配額，迴圈失控時先撞到自己的上限，正式環境不受影響。Coding agent 的做法見 [coding agent 成本控制清單](https://atptoken.ai/zh-tw/blog/coding-agents-cost-control-checklist)。

## 30 天導入計畫

- 第 1 週：列出所有使用中的金鑰與原廠帳號，以及背後的服務。為前三大請求型態算出每 1,000 次成本。
- 第 2 週：建立組織、工作區，每個服務、每個環境各一個專案。把花費最高的三個服務換成專案金鑰；OpenAI、Anthropic、Gemini SDK 只要換 base URL 與金鑰。
- 第 3 週：為每個專案分配每月點數、設定可用模型，並把 agent 移到獨立專案。對最貴的工作負載套用槓桿 1 到 4。
- 第 4 週：用帳務事件結算當月，逐專案比對 Consumed 與 Allocated，據此設定下個月的分配額。

## 指標看板

| 指標 | 負責人 | 頻率 |
|---|---|---|
| 各專案已消耗 vs 已分配點數 | 平台與財務 | 每週 |
| 各請求型態每 1,000 次成本 | 工程 | 每週 |
| 每次完成 agent 任務成本 | Agent 負責人 | 每週 |
| `402` 與 `403` 回應佔比 | 平台 | 每日 |
| 已撤銷或 30 天未使用的金鑰 | 資安 | 每月 |

## 在 ATP Token 上怎麼設定

1. 建立 Team 組織，再到資源頁建立工作區與專案。
2. 為每個專案選擇可用模型並分配點數。Team 組織裡的金鑰花的是組織分配的點數，不動用個人錢包。
3. 每個專案建立一把 `atp-` 金鑰。金鑰只顯示一次；API 金鑰頁列出所有工作區的金鑰，任何一把都能隨時撤銷。
4. 每週依模型與金鑰看用量頁，有異常時在 7 天內用請求紀錄追查。

[從快速開始接入](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [LLM token 成本怎麼算？公式與 AI 帳單讀法](https://atptoken.ai/zh-tw/blog/how-to-read-your-ai-bill)
- [上線後 AI 帳單為什麼會暴增](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live)
- [Token 計價 vs 按席次計價：AI 預算怎麼編](https://atptoken.ai/zh-tw/blog/from-seats-to-tokens-ai-budgeting)

## 常見問題

### 什麼是 LLM 成本優化？

LLM 成本優化是在不犧牲品質的前提下，降低每個有用輸出的花費：依任務選對模型、限制輸入與輸出 token、在適用處使用原廠的批次與快取計價，並對每個專案設上限，讓出錯時損失有限。

### 降低 LLM 成本最快的方法是什麼？

先從模型選擇與輸出長度下手。claude-sonnet-4-6 的輸出是輸入的 5 倍、gpt-5.5 是 6 倍，同家族較小的模型每 token 成本可能只有三分之一。換模型前，先用 50 到 100 則真實提示測品質。

### 怎麼把 AI 成本歸到各團隊？

每個服務、每個環境各給一個專案與一把金鑰，再依金鑰看用量。在 ATP Token 上，一把金鑰只屬於一個專案，所以依金鑰的用量就是依負責人的用量。

### AI agent 怎麼改變成本管理？

Agent 完成一項工作會發出很多次請求，每一步都可能重送完整上下文。除了每次請求成本，也要追蹤每次完成任務的成本，並在 agent 設定裡限制步數與重試。

### 批次處理能降低 LLM 成本嗎？

在原廠層級可以。OpenAI 的 Batch 與 Flex 定價為標準價的 50%，Anthropic 的 Batch API 也是標準價的 50%，代價是非同步完成。適合評測、回補資料與夜間批次。

---

Tags: LLM 成本優化, AI 成本管理, ATP
