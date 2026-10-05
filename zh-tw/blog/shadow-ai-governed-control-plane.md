# 什麼是 Shadow AI（影子 AI）？風險、實例與收回管控的做法（2026）

> 來源: https://atptoken.ai/zh-tw/blog/shadow-ai-governed-control-plane/
> 發表於: 2026-09-02 · 作者: hung-chien (AI 成長與品牌經理)

Shadow AI 是員工未經 IT 核准使用 AI 工具、帳號或 API 金鑰。整理 5 個實例、IBM 與 Verizon 2025 數據、偵測方法，以及如何用核准路徑取代。

## 重點摘要

- Shadow AI 是在 IT 未核准、未監督的情況下使用 AI 工具、帳號或 API 金鑰。IBM 2025 年資料外洩研究中，每五家組織就有一家回報曾因 Shadow AI 發生外洩。
- 常見樣態是個人聊天機器人帳號、刷公司卡的個人 API 金鑰、未經審查就開啟的 SaaS AI 功能、瀏覽器擴充功能，以及未核准的程式碼 Agent。費用報銷、SSO 紀錄、DNS 紀錄與機密掃描能找出大部分。
- 全面禁止只會讓使用轉到你看不到的地方。改成提供更快的核准路徑：幾分鐘內拿到專案金鑰、模型白名單、小額沙盒預算與逐筆請求紀錄。

依照 [IBM 的定義](https://www.ibm.com/think/topics/shadow-ai)，Shadow AI（影子 AI）是員工在 IT 部門未正式核准或監督的情況下使用 AI 工具或應用程式。實際上，它可能是一個貼進客戶合約的個人 ChatGPT 帳號，或是一支每晚刷公司卡、用個人 API 金鑰執行的腳本。本文整理五種具體樣態、2025 年的數據、四種偵測方法，以及一套讓核准路徑比影子路徑更快的設定。

## Shadow AI 一覽

| 樣態 | 什麼資料離開公司 | 誰付錢 | 最先在哪裡看到 |
|---|---|---|---|
| 個人聊天機器人帳號 | 貼上的文字與上傳的檔案 | 員工自付或報銷 | DNS 紀錄、瀏覽器遙測 |
| 腳本裡的個人 API 金鑰 | 腳本送出的任何內容 | 公司卡，事後報銷 | 費用報銷 |
| 未經審查就開啟的 SaaS AI 功能 | 原本就在該 SaaS 裡的資料 | 包在 SaaS 帳單裡 | 供應商管理後台、續約時 |
| AI 瀏覽器擴充功能 | 它能讀到的頁面內容 | 通常免費 | 端點清冊、OAuth 授權 |
| 未核准的程式碼 Agent | 原始碼與上下文裡的機密 | 個人金鑰或訂閱 | 機密掃描、對外連線紀錄 |

Shadow AI 是 Shadow IT 的一個子集。差別在於每一次提示都是一次資料傳輸，而 API 用量按 token 計費，所以一支沒人審過的腳本，可能在同一週同時帶來資料問題與費用問題。

## Shadow AI 有多普遍：2025 年數據

[IBM 2025 年資料外洩成本報告](https://newsroom.ibm.com/2025-07-30-ibm-report-13-of-organizations-reported-breaches-of-ai-models-or-applications,-97-of-which-reported-lacking-proper-ai-access-controls)（2025 年 7 月發布）指出：

- 每五家組織就有一家回報曾因 Shadow AI 發生外洩。
- Shadow AI 程度高的組織，外洩成本比程度低或沒有的組織平均高出 67 萬美元。
- 13% 的組織回報 AI 模型或應用程式遭入侵，其中 97% 缺乏適當的 AI 存取控管。
- 只有 37% 的組織有管理 AI 或偵測 Shadow AI 的政策。

[Verizon 2025 年資料外洩調查報告（DBIR）](https://www.verizon.com/business/resources/reports/2025-dbir-data-breach-investigations-report.pdf)補上身分這一面：15% 的員工經常在公司裝置上使用生成式 AI；其中 72% 以非公司電子郵件作為帳號識別，17% 使用公司電子郵件但沒有整合身分驗證。

72% 這個數字和離職流程直接相關。用個人信箱註冊的帳號不在你的身分提供者管轄範圍內，停用員工的 SSO 登入並不會關掉它。

## 五個 Shadow AI 實例

### 1. 用個人 ChatGPT 或 Claude 帳號處理公司資料

財務分析師把董事會備忘錄草稿貼進個人聊天機器人帳號，請它幫忙潤稿。這份資料從此依照那個人自己註冊的方案條款被處理，資安團隊完全不知道。

### 2. 腳本裡的個人 API 金鑰，刷公司卡

業務營運分析師寫了一支腳本，每晚用 GPT-5.5 摘要 2,000 份通話逐字稿。每份 6,000 個輸入 token、800 個輸出 token，合計 1,200 萬輸入 token（60 美元）與 160 萬輸出 token（48 美元），以 OpenAI [公告價格](https://developers.openai.com/api/docs/pricing)每 100 萬 token 輸入 5 美元、輸出 30 美元計算（截至 2026 年 10 月）。一晚約 108 美元，30 天約 3,240 美元，以「軟體」名目報銷，沒有任何上限。

### 3. 已核准 SaaS 裡被開啟的 AI 功能

CRM 或客服系統推出 AI 助理，某位工作區管理員就把它開了。這家供應商幾年前只針對資料儲存做過審查，新功能卻把同樣的資料送到模型供應商，適用的條款沒有人重新讀過。

### 4. 瀏覽器擴充功能

一個「AI 幫你摘要這一頁」的擴充功能，需要讀取員工開啟的每一個頁面，包括內部管理後台與人資系統。因為免費，它從來不會出現在採購流程裡。

### 5. 未核准的程式碼 Agent

外包工程師用個人金鑰讓程式碼 Agent在公司 monorepo 上工作。Agent 把 `.env` 檔讀進上下文，合約結束後仍能繼續運作，因為金鑰是外包工程師自己的。

## Shadow AI 的風險

### 資料

提示與上傳的檔案在沒有分級的情況下離開公司。適用的資料保留與訓練條款，是員工個人方案的條款，法務沒有審過。

### 費用

刷在個人卡上的 token 計費，沒有上限，也沒有負責人。財務只看到一連串小額報銷，總數要等有人把一季的報銷單加總才會出現。

### 離職

綁在個人身上的金鑰與帳號，在人離開後仍然有效。外包工程師離職後，能撤銷那把個人金鑰的只有他自己。

### 稽核

客戶的資安問卷問到「哪些 AI 供應商處理我們的資料」時，你需要一份供應商清單與請求紀錄。影子用量不會留下任何可以拿出來的紀錄。

## 怎麼偵測 Shadow AI

以下四個來源與廠商無關，多數公司手上已經有。

1. 費用報銷與信用卡帳單。搜尋過去 12 個月 AI 供應商與 AI SaaS 工具的商家名稱。同一位員工每月固定的小額扣款，通常代表有個人 API 金鑰在正式環境裡跑。
2. SSO 與 OAuth 授權紀錄。列出使用者透過「以某帳號登入」授權過的第三方應用程式，篩出不在核准清單上的 AI 工具與擴充功能。
3. 對外連線與 DNS 紀錄。查看本不該呼叫 AI 供應商 API 網域的伺服器與 CI runner 是否有連線，以及筆電上看起來像腳本在跑的流量。
4. 機密掃描。用你的機密掃描工具掃程式碼庫、CI 變數與 notebook，找 AI 供應商金鑰的格式。每一筆命中既是要輪替的外洩，也是一條要遷移的使用路徑。

把結果當成遷移清單來用。如果大家因為掃描結果被懲處，下一次掃到的會變少，實際用量卻一樣在。

## 怎麼把 Shadow AI 收回管控

影子路徑大約五分鐘：註冊、綁卡、複製金鑰。核准路徑要接近這個速度，否則大家會繼續走影子路徑。讓核准路徑有競爭力的四件事：

- 幾分鐘內就能拿到專案金鑰，每加一個新模型不必開一張採購單。
- 每個專案一份模型白名單，存取權限決定一次，每次呼叫都強制執行。
- 一筆小額沙盒預算，不會長成意外帳單。
- 逐筆請求紀錄，看得出每次呼叫來自哪個專案、哪把金鑰、哪個模型。

## 在 ATP Token 上怎麼設定

ATP Token 讓每個團隊用一把專案金鑰，透過 OpenAI、Anthropic 與 Gemini SDK 使用 11 家廠商的 70+ 個模型，上述控管都在閘道層執行。

### 步驟 1：建立 Team 組織與沙盒工作區

建立 Team 組織，才能邀請成員與指派角色；接著在正式工作區旁邊新增一個實驗用工作區。見[設定組織](https://atptoken.ai/zh-tw/docs/console-setup)。

### 步驟 2：每個團隊建一個專案並選擇允許的模型

在 Resources 頁建立專案，選擇允許的模型（至少一個）。呼叫清單以外的模型，會在送到任何供應商之前就回傳 `403`，流程見[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)。想先比較模型的人，可以在寫程式之前先到主控台的 Studio 試用。

### 步驟 3：分配一筆小額預算

例如分配 2,000 點數（20 美元，1 點數 = 0.01 美元）給沙盒專案。專案只能花被分配到的額度，分配額就是上限；餘額用完時請求會回傳 `402`。操作步驟見[團隊預算上限設定](https://atptoken.ai/zh-tw/docs/cb-budget-caps)，額度怎麼抓可參考[有效的 AI 花費上限](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)。

### 步驟 4：發一把金鑰，換掉影子腳本裡的那把

金鑰以 `atp-` 開頭，只顯示一次。以實例 2 的逐字稿腳本來說，要改的只有 base URL 與金鑰：

```python
import os
from openai import OpenAI

client = OpenAI(
    base_url="https://api.atptoken.ai/v1",
    api_key=os.environ["ATP_API_KEY"],  # 專案金鑰
)
```

實例 5 的程式碼 Agent，則用環境變數把 Claude Code 指向閘道，做法見[在 ATP 上執行 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code)：

```bash
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"
```

模型 ID 必須在專案的允許清單上，例如 [Claude Sonnet 4.6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/)。

### 步驟 5：用正確的角色加入成員

在工作區或專案層級以 Member 身分邀請同事，他們可以使用預算但不能挪動；Admin 負責管理金鑰與分配。見[團隊與角色](https://atptoken.ai/zh-tw/docs/team)。

### 步驟 6：檢視用量，離職時撤銷金鑰

用量頁依模型與金鑰拆分點數與 token。請求紀錄逐筆列出時間、範圍、模型、狀態、請求 ID 與 token 數，保留 7 天，定位是除錯用。活動紀錄則記下登入、邀請與額度變更（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。有人離職時，在 API 金鑰頁撤銷他的專案金鑰：撤銷後立即失效，並留在清冊中供稽核（[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。

ATP 只看得到經過它的流量。聊天機器人帳號、擴充功能與 SaaS 功能仍要靠上面的偵測方法；改變的是，你找到的腳本與 Agent 有了一條核准的路可以搬過去。

[快速開始](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)
- [模型目錄與存取控管](https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control)
- [AI 治理清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist)

## 常見問題

### 什麼是 Shadow AI？

Shadow AI（影子 AI）是員工在 IT 部門未核准、未監督的情況下使用 AI 工具、應用程式、帳號或 API 金鑰。典型情況是用個人 ChatGPT 或 Claude 帳號處理公司資料，或在公司腳本裡跑個人 API 金鑰。

### Shadow AI 有哪些實例？

常見例子包括：用個人聊天機器人帳號摘要客戶文件、在腳本裡放個人 API 金鑰並刷公司卡、在已核准的 SaaS 工具裡未經審查就開啟 AI 功能、安裝 AI 瀏覽器擴充功能，以及在核准工具清單之外使用程式碼 Agent。

### Shadow AI 有什麼風險？

主要風險是公司資料依照沒人審過的條款被處理、費用掛在沒有上限的個人卡上、離職後存取權限仍在，以及稽核時拿不出任何紀錄。IBM 2025 年資料外洩成本報告指出，Shadow AI 程度高的組織，外洩成本平均多出 67 萬美元。

### 怎麼偵測 Shadow AI？

先從手上已有的四個來源著手：費用報銷與信用卡帳單、SSO 與 OAuth 授權紀錄、對 AI 供應商網域的對外連線與 DNS 紀錄，以及對程式碼庫與 CI 變數的機密掃描。

### 禁止 AI 工具能阻止 Shadow AI 嗎？

通常不能。大家會把工作移到個人裝置與帳號上，你的紀錄裡反而看不到。真正能減少 Shadow AI 的，是一條和個人路徑一樣快上手、又內建預算與紀錄的核准路徑。

---

Tags: Shadow AI, AI 治理, ATP
