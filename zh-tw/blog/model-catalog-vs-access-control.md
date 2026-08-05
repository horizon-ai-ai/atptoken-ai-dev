# 模型目錄 vs 存取控制：為什麼 GET /v1/models 不是金鑰權限（2026）

> 來源: https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control/
> 發表於: 2026-08-28 · 作者: hung-chien (AI 成長與品牌經理)

模型目錄列出平台能提供什麼；存取控制決定專案金鑰能呼叫什麼。兩者混淆會造成 403、影子花費與虛假安全感。

## 重點摘要

- 目錄是菜單；專案白名單是許可證。GET /v1/models 回答有沒有，不回答准不准。
- 在流量到達供應商前強制白名單，政策才不是 code review 的希望。
- 白名單要搭配預算——獲准且無上限仍是帳單事件。

模型目錄是平台可服務的模型 id 列表；存取控制是決定某專案金鑰能呼叫哪些 id 的政策。

**菜單 ≠ 權限。** 在 ATP，列表描述平台；專案白名單強制存取並在違規時 403（[模型](https://atptoken.ai/zh-tw/docs/models)、[how it works](https://atptoken.ai/zh-tw/docs/how-it-works)）。混淆兩者會助長[帳單爆炸](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live)。

## 每筆請求要回答的兩個問題

平台認不認識這模型？**這個專案**可不可以呼叫？**這個專案**付不付得起（[點數](https://atptoken.ai/zh-tw/docs/credits)）？

## 設計白名單

預設拒絕 frontier；按專案不是按人（[一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key)）；放寬白名單要有管理事件 log（[監控](https://atptoken.ai/zh-tw/docs/monitoring)）；搭配 cap（[花費上限](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)）；對應用團隊說明 403 是政策不是當機（[錯誤](https://atptoken.ai/zh-tw/docs/errors)）。

## 更現代的做法

ATP Token 在專案設定允許模型，金鑰繼承，未授權呼叫不到供應商。

[工作區與專案 →](https://atptoken.ai/zh-tw/docs/resources) · [快速開始 →](https://atptoken.ai/zh-tw/docs/quickstart)

## 常見問題

### 模型目錄與模型存取控制有何不同？

目錄列出平台能路由的模型；存取控制是請求時的專案政策。

### 文件上看得到的模型為什麼回 403？

列表常是菜單；不在白名單就在出站前拒絕。

### 每個專案都該開 frontier 模型嗎？

不該；預設中階，有預算與理由再開。

### 白名單如何降低 AI 成本？

防止靜默升級高價模型；仍需花費上限。

### 模型政策該放程式碼還是平台？

平台強制為最終權威。

## 延伸閱讀

- [企業 AI 治理清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist)
- [AI 閘道選型 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026)
- [模型文件](https://atptoken.ai/zh-tw/docs/models)

[申請企業方案 →](https://atptoken.ai/zh-tw/enterprise-plan)

## 常見問題

### 模型目錄與模型存取控制有何不同？

目錄列出平台能路由的模型；存取控制是請求時允許或拒絕這些模型的專案（或金鑰）政策。

### 文件上看得到的模型為什麼回 403？

文件與列表端點常是平台菜單。若模型不在專案白名單，治理閘道會在出站前拒絕。

### 每個專案都該開 frontier 模型嗎？

不該。高頻路徑預設中階；僅在有預算與書面理由的專案啟用 frontier。

### 白名單如何降低 AI 成本？

防止應用程式碼靜默升到高價模型。成本控制仍需花費上限；白名單去掉意外高級路由。

### 模型政策該放程式碼還是平台？

平台強制能扛住客戶端 bug 與分叉。程式碼可給好預設；閘道必須是最終權威。

---

Tags: 模型白名單, AI 閘道, ATP
