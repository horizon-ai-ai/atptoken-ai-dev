# 模型目錄與存取控制：GET /v1/models 列出菜單，專案白名單決定能不能用（2026）

> 來源: https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control/
> 發表於: 2026-08-28 · 作者: hung-chien (AI 成長與品牌經理)

GET /v1/models 列出 LLM 平台提供哪些模型；模型白名單決定金鑰能呼叫哪些。附請求與回應範例、403 的意思與白名單設計。

## 重點摘要

- 在 ATP Token，GET /v1/models 回傳的是平台目錄。金鑰能呼叫什麼由專案的允許模型清單決定，清單外的模型在接觸任何供應商之前就會收到 403。
- OpenAI 用每個專案的 Model usage 設定做同一件事；OpenRouter 則用 guardrail 裡的模型白名單。
- 白名單按工作負載設計，寫明模型與牌價，例如客服機器人只允許 claude-haiku-4-5 與 gemini-3-5-flash。

模型目錄是平台能提供的模型 ID 清單，模型存取控制則是決定某把金鑰能呼叫其中哪些 ID 的規則。在 ATP Token，`GET /v1/models` 回傳目錄，而專案的允許模型清單會在每次請求時檢查，不符合的請求在聯絡任何供應商之前就回傳 403。本文列出請求與回應、說明 403 代表什麼、比較 OpenAI 與 OpenRouter 的做法，並提供四份附牌價的白名單範本。

## 兩個不同的問題

| 問題 | ATP Token 在哪裡回答 | 答案為否時 |
|---|---|---|
| 這把金鑰有效嗎？ | 驗證 | 401 |
| 平台上有這個模型嗎？ | [GET /v1/models](https://atptoken.ai/zh-tw/docs/models) | 清單裡找不到這個 ID |
| 這把金鑰的專案可以呼叫它嗎？ | 專案的允許模型 | 403，在接觸任何供應商之前 |
| 專案付得起嗎？ | 專案的點數餘額 | 402 |

順序很重要。閘道先驗證金鑰，再拿模型比對專案的允許清單，接著路由到供應商，最後依專案餘額計量 token（[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)）。一個模型可能通過第二列，卻卡在第三列。

## GET /v1/models 回傳什麼

請求使用你的專案金鑰與 OpenAI 格式的 base URL：

```
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer atp-..."
```

回應是 OpenAI 風格的清單。每個 `id` 就是請求裡 `model` 欄位要填的字串：

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

[模型探索文件](https://atptoken.ai/zh-tw/docs/models)寫明這份清單不會依你的專案篩選。用它取得最新的 ID，不要從供應商儀表板或部落格文章抄模型名稱。也不要把它當成權限清單來讀。

## 403 代表什麼

ATP Token 回傳 403，表示金鑰有效、模型 ID 也存在，但這個模型沒有在金鑰所屬的專案啟用。[常見回應](https://atptoken.ai/zh-tw/docs/errors)頁面只用一行描述：模型未在此專案啟用。請求停在授權步驟，不會送到任何供應商。和所有 ATP 錯誤一樣，回應帶有 `request_id`，並採用你所呼叫 SDK 的錯誤格式。

典型情境：一位開發者在目錄裡看到 `claude-opus-4-8`，在功能分支把客服機器人換成它。客服機器人的專案只允許 claude-haiku-4-5 與 gemini-3-5-flash，所以 staging 第一筆請求就回傳 403。這正是白名單該做的事。以 ATP 牌價計算，2,000 token 的提示加 300 token 的回覆，在 [claude-opus-4-8](https://atptoken.ai/zh-tw/models/claude-opus-4-8/)（每百萬 token 輸入 USD 5、輸出 USD 25）要 1.75 點，在 [claude-haiku-4-5](https://atptoken.ai/zh-tw/models/claude-haiku-4-5/)（USD 1 與 USD 5）只要 0.35 點，每則回覆差五倍。

由此得出兩條用戶端規則。不要重試 403，它每次都會以同樣方式失敗。把它連同請求 ID 記錄下來，交給專案負責人，由對方改程式碼裡的模型，或請 Admin 放寬清單。

## OpenAI 與 OpenRouter 怎麼做同一件事

| 平台 | 模型規則放在哪 | 粒度 |
|---|---|---|
| OpenAI API | 專案設定的 Limits 裡的 Model usage（[Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)） | 每個專案 |
| OpenRouter | Guardrail 裡的模型白名單（[guardrails](https://openrouter.ai/docs/guides/features/guardrails)） | 每位成員或每把金鑰；多個 guardrail 同時適用時，只有所有 guardrail 都允許的模型可用 |
| ATP Token | 專案的允許模型（[工作區與專案](https://atptoken.ai/zh-tw/docs/resources)） | 每個專案，從不按金鑰設定；每個專案至少一個模型 |

在 OpenAI，Model usage 設定和專案的每月花費上限、通知門檻放在一起。在 OpenRouter，同一個 guardrail 還能放花費上限與供應商白名單，以最嚴格的適用規則為準。在 ATP Token，允許清單和專案的點數分配放在一起，專案裡的每把金鑰兩者都繼承。

## 白名單設計：四個專案範本

| 專案 | 允許的模型 | ATP 牌價，每百萬 token（輸入 / 輸出） | 分配建議 |
|---|---|---|---|
| support-bot-prod | [claude-haiku-4-5](https://atptoken.ai/zh-tw/models/claude-haiku-4-5/)、[gemini-3-5-flash](https://atptoken.ai/zh-tw/models/gemini-3-5-flash/) | USD 1 / 5；USD 1.5 / 9 | 依回覆量推算 |
| coding-agent | [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/)、[gpt-5.4](https://atptoken.ai/zh-tw/models/gpt-5.4/) | USD 3 / 15；USD 2.5 / 15 | 按團隊分配，每週檢視 |
| batch-classification | [deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/)、qwen-3-7-flash | USD 0.2 / 0.4；USD 0.03 / 0.13（提示 32K 以內） | 依任務推算 |
| research-sandbox | claude-opus-4-8、[gpt-5.5](https://atptoken.ai/zh-tw/models/gpt-5.5/) | USD 5 / 25；USD 5 / 30 | 小額、固定 |

1. **從通過評測的最便宜模型開始**，再加一個來自第二家廠商的備案。同一個模型 ID 在不同供應商之間的容錯切換，閘道已經處理（[供應商路由](https://atptoken.ai/zh-tw/docs/provider-routing)）；第二個模型是給你想在程式碼裡換模型時用的。在 Gemini 與 GPT 之間選擇，請見 [Gemini vs GPT](https://atptoken.ai/zh-tw/compare/gemini-vs-gpt/)。
2. 前沿模型放在自己的專案，給小額分配。研究團隊能用 Opus 與 GPT-5.5，客服機器人則不會只差一行設定就換過去。
3. 把放寬清單當成變更申請處理。管理資源是 Admin 的權限，Activity 紀錄會記下資源更新（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。
4. 每份白名單都搭配預算。允許的模型配上無上限的餘額，帳單一樣會嚇人（[AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)）。

## 在 ATP Token 上怎麼設定

1. 在 Resources 頁面建立專案並選擇允許的模型（[工作區與專案](https://atptoken.ai/zh-tw/docs/resources)）。
2. 撥點數給專案，再從專案發金鑰（[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。
3. 呼叫 `GET /v1/models`，把精確的 ID 複製到設定檔。
4. 在 staging 對每個設定中的模型各送一筆測試請求。200 表示有權限；403 表示專案清單裡沒有這個模型。
5. 部署後在請求紀錄依狀態篩選，找出 403。

[快速開始：列出模型並送出第一筆請求](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)
- [AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)
- [LLM 閘道比較 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026)

## 常見問題

### GET /v1/models 只會顯示我的金鑰能用的模型嗎？

在 ATP Token 不是這樣。GET /v1/models 列出平台上所有可用的模型，不會依你的專案篩選。金鑰能呼叫哪些模型，由專案的允許清單決定，並在每次請求時檢查。

### 為什麼 /v1/models 裡有的模型，呼叫時卻回傳 403？

那個模型存在於平台上，但沒有在你金鑰所屬的專案啟用。ATP Token 在驗證金鑰之後檢查專案的允許清單，並在聯絡供應商之前以 403 拒絕。請改用允許的模型，或請專案 Admin 加入。

### 什麼是模型白名單？

模型白名單是一個專案、金鑰或成員被允許呼叫的模型 ID 清單。不論應用程式碼要求什麼，其他模型的請求都會被平台拒絕。

### 可以限制 OpenAI 專案能用哪些模型嗎？

可以。在 OpenAI API 平台，專案的 Limits 設定裡有 Model usage，可選擇該專案能用哪些模型，旁邊就是每月花費上限與通知門檻。

### ATP Token 的模型權限是按金鑰還是按專案設定？

按專案。同一個專案的每把金鑰都繼承相同的允許模型，而且每個專案至少要允許一個模型。

---

Tags: 模型白名單, LLM 存取控制, AI 閘道, ATP
