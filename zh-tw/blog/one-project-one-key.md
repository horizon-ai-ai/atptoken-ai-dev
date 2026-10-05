# LLM API 金鑰管理：一專案一金鑰，附 30 天遷移流程（2026）

> 來源: https://atptoken.ai/zh-tw/blog/one-project-one-key/
> 發表於: 2026-08-07 · 作者: hung-chien (AI 成長與品牌經理)

LLM API 的 API 金鑰管理：共用金鑰會在哪裡出事、如何每個專案發一把金鑰、各環境金鑰放在哪，以及一份 30 天遷移流程。

## 重點摘要

- 每個工作負載有自己的專案和自己的金鑰，撤銷、輪替、追查花費時一次只影響一個服務。
- OpenAI 建議每位成員使用各自的 API 金鑰，且永遠不要把金鑰放在用戶端程式碼；正式服務則需要工作負載專屬的金鑰，員工離職才不會拖垮服務。
- 從共用金鑰遷出約需 30 天：盤點呼叫方、建立專案、先切非正式環境、正式服務逐一切換，最後撤銷。

LLM API 的金鑰管理，是一套決定誰能拿到金鑰、每把金鑰能存取什麼、存在哪裡、以及怎麼輪替與撤銷的規則。在正式環境撐得住的做法是一專案一金鑰：每個工作負載有自己的專案，專案的金鑰帶著自己的模型清單與預算。以下依序整理共用金鑰出事的三種情境、發金鑰的做法、各環境金鑰該放哪的對照表，以及一份 30 天遷移流程。

## 共用金鑰出事的三種情境

### 已離職的外包工程師

一位外包工程師用公司唯一的一把 API 金鑰做 RAG 原型，金鑰放在本機的 `.env` 檔案裡，週五離職。同一把金鑰也在跑客服機器人、每晚的摘要任務和內部的 Slack 助理。當天下午撤銷它，三個服務一起壞；不撤銷，等於一位已離職的外包手上還有一把能用的金鑰。多數團隊選擇「下個 sprint 再輪替」，而下個 sprint 總是排滿。

一專案一金鑰的話，這位外包從頭到尾只拿到自己沙盒專案的金鑰。撤銷它，其他什麼都不受影響。

### 被推上公開 repo 的金鑰

有人把含金鑰的設定檔 commit 到公開 repo。撿到的人送出的流量會算在你的帳單上，而且因為每個服務都送同一把金鑰，對方的請求在用量資料裡跟你的完全一樣。處理方式跟外包的情境相同，同樣會帶來一次停機。

### 沒人說得清的花費暴衝

月帳單翻倍。供應商的儀表板看得出哪個模型用量上升，但每筆請求都帶同一把金鑰，沒人能說是哪個產品造成的。財務要按產品拆帳，工程師花兩天比對各服務日誌的時間戳。

## 各家廠商的建議

OpenAI 的 [API 金鑰安全最佳實務](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) 要求每位團隊成員使用各自的 API 金鑰、定期輪替並設定到期，且永遠不要把金鑰放在用戶端程式碼。OpenAI 也建議 staging 與正式環境分成不同專案，各自設定上限（[正式環境最佳實務](https://developers.openai.com/api/docs/guides/production-best-practices)）。Anthropic 可以把 API 金鑰限定在單一 Console [工作區](https://platform.claude.com/docs/en/manage-claude/workspaces)。Vercel AI Gateway 的金鑰可以同時設定預算與到期日，適合有明確結束日的外包金鑰（[Vercel 預算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)）。

個人金鑰解決的是人員離職的問題。正式服務不該跑在某個人的金鑰上，否則移除這個人，服務也跟著停。實際可行的分法是：個人金鑰給個人沙盒，每個部署中的工作負載各有一把專案金鑰。

## 發金鑰的做法

1. **每個工作負載、每個環境各一個專案。** `support-bot-prod` 與 `support-bot-staging` 是兩個獨立專案，各有各的金鑰。
2. 服務使用專案金鑰，一個專案一把。需要實驗的人有自己的沙盒專案。
3. 金鑰以「服務、環境、發行月份」命名，例如 `support-bot-prod-2026-10`，在日誌或 repo 裡撿到時能直接對到負責人。
4. 金鑰從主控台直接放進 secret manager，不要貼到聊天、工單或文件裡。
5. 用重疊方式輪替：在同一個專案發新金鑰、部署、確認流量已經轉移，再撤銷舊的。

## 各環境的金鑰放在哪

| 環境 | 專案 | 金鑰存放位置 | 誰能讀取 |
|---|---|---|---|
| 正式服務 | `support-bot-prod` | 雲端 secret manager，部署時注入為環境變數 | 該服務的執行身分 |
| Staging | `support-bot-staging` | 同一個 secret manager，不同的 secret 路徑 | Staging 部署角色 |
| CI 評測 | `ci-evals` | CI 的 secret 儲存（例如 GitHub Actions secrets） | 只有 pipeline |
| 本機開發 | `dev-<name>` 沙盒 | 列在 `.gitignore` 的 `.env` 檔案 | 該開發者 |
| Coding agent | `agent-<name>` 沙盒 | shell 中的 `ANTHROPIC_AUTH_TOKEN`，或 `~/.claude/settings.json` 的 `env` 區塊（[在 ATP 上跑 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code)） | 該開發者 |
| 瀏覽器或行動 App | 無 | 不存放。App 呼叫你的後端，由後端持有金鑰 | 後端以外沒有人 |

## ATP Token 的金鑰怎麼運作

ATP Token 是四層結構：組織、工作區、專案、金鑰（[設定組織](https://atptoken.ai/zh-tw/docs/console-setup)）。一把金鑰只屬於一個專案，並繼承該專案允許的模型與點數餘額。模型權限按專案設定，從不按金鑰設定，所以同一個專案裡的兩把金鑰能呼叫的模型永遠相同。

建立金鑰的精靈會請你填名稱、選擇工作區與專案，並可選擇先撥入一些起始點數。金鑰以 `atp-` 開頭、長度 92 字元，完整金鑰只在建立時顯示一次，之後只看得到前綴（[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。API 金鑰頁面列出組織內所有工作區與專案的每一把金鑰，可依名稱或前綴搜尋。撤銷的金鑰立即失效，並留在清單中供稽核。

追查花費時，用量頁面依模型與金鑰顯示點數與 token，請求紀錄則記下每次呼叫的模型、狀態、token 數與請求 ID（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。請求紀錄保留 7 天，事件發生後請盡快檢查可疑的金鑰。閘道在轉發請求前會移除你的 `atp-` 金鑰，上游供應商永遠看不到它（[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)）。

誰能做什麼由角色決定：Admin 管理成員、資源、金鑰與點數分配，Member 則使用自己有權限的內容（[團隊與角色](https://atptoken.ai/zh-tw/docs/team)）。

## 遷移流程：從一把共用金鑰到專案金鑰

| 時間 | 步驟 | 完成條件 |
|---|---|---|
| 第 1 天 | 在 repo、CI secrets 和 secret manager 裡搜尋共用金鑰的前綴，列出每個呼叫方並指定負責人。 | 每個呼叫方旁邊都有一個名字 |
| 第 2–3 天 | 每個呼叫方建一個專案，選定允許的模型、分配小額預算、發金鑰。 | 每個專案的金鑰都已放進 secret manager |
| 第 4–10 天 | 先遷非正式環境：staging、CI、沙盒。在 ATP 上要改的是 base URL、`atp-` 金鑰和模型 ID（[從 OpenAI 遷移](https://atptoken.ai/zh-tw/docs/cb-migrate-openai)）。 | 非正式環境流量出現在新金鑰下 |
| 第 11–20 天 | 正式服務一次搬一個，挑低流量時段，每搬完一個就檢查該金鑰的用量。 | 每個服務的用量都出現在自己的金鑰下 |
| 第 21–27 天 | 觀察共用金鑰。還有流量就代表有漏掉的呼叫方，找出來搬走。 | 共用金鑰連續 7 天沒有流量 |
| 第 28 天 | 撤銷共用金鑰。 | 已撤銷，並記錄原因與時間 |
| 第 30 天 | 寫下外洩處理程序：撤銷、在同一專案發新金鑰、重新部署、檢查該金鑰的用量。 | 程序已放進值班手冊 |

這份流程最好搭配每個專案的預算，外洩或陷入迴圈的金鑰也會撞到上限。請見 [AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)。

[快速開始：建立專案金鑰](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [模型目錄與存取控制](https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control)
- [AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)
- [企業 AI 治理檢查清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist)

## 常見問題

### 什麼是 LLM API 的金鑰管理？

就是一套規則：誰能拿到 API 金鑰、每把金鑰能存取什麼、存在哪裡、怎麼輪替與撤銷。對 LLM API 來說，它也決定了你能不能看出是哪個服務花掉這筆錢。

### 每位開發者都該有自己的 OpenAI API 金鑰嗎？

OpenAI Help Center 建議每位團隊成員使用各自的 API 金鑰。個人金鑰用在個人沙盒；正式服務則給它自己的專案金鑰，開發者離職時線上服務才不會跟著停。

### LLM API 金鑰外洩時該怎麼做？

先撤銷，再在同一個專案發一把新金鑰、重新部署用到它的服務，並檢查該金鑰有沒有不是你送出的流量。一專案一金鑰的話，受影響的只有那一個服務。

### 一把 ATP Token 金鑰可以存取多個專案嗎？

不行。ATP Token 金鑰只屬於一個專案，並繼承該專案允許的模型與點數餘額。要用另一個專案，就在那個專案發金鑰。

---

Tags: API 金鑰管理, API 金鑰, LLM 資安, ATP
