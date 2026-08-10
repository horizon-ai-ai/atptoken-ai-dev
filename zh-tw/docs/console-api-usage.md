# 用量與餘額

> Source: https://atptoken.ai/zh-tw/docs/console-api-usage/

`GET /api/quota/balance`

Credit 沿 Account → Org → Workspace → Project 階層下放。**只有專案（葉節點）的餘額是即時消耗的** —— gateway 每一筆請求都會即時扣減。Org 與 workspace 的餘額是轉撥池，只在撥款／退回時變動。

#### GET /api/quota/balance

自動化要用的端點。`proj_balance` 讀的是 gateway 每筆請求即時扣減的儲存，因此即時反映用量；`proj_inflight` 是進行中請求的預留額。

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 組織 id。 |
| workspace_id | string | 加上工作區範圍。 |
| project_id | string | 須同時帶 workspace_id；回傳專案即時餘額。 |

```
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"
```

#### GET /api/quota/status

同樣的三層餘額，以逐層區塊呈現。只回「剩餘餘額」—— credit 模型不儲存「期初配額」，因此沒有使用率欄位。

#### GET /api/billing/summary

每月用量與計費彙總：指定 `period`（`YYYY-MM`，預設當前 UTC 月份）內各模型的 token 總量、請求數、計量與 credits。**範圍級視角** —— 涵蓋該 org／workspace／project 下所有 key。

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 組織 id。 |
| period | string | `YYYY-MM`（UTC），預設當月。 |
| workspace_id / project_id | string | 縮小範圍。 |

#### GET /api/billing/usage-by-key

每月各 API key 用量。**只回呼叫者本人建立的 key** —— 這是個人視角，不是組織全量報表（全量請用 `billing/summary`）。

#### GET /api/billing/usage-series

單月每日用量趨勢（UTC 分桶），支援 `interval` 與 `group_by`。與 usage-by-key 相同為個人視角。

#### GET /api/quota/monthly

歷史每月關帳快照（worker 於月底寫入），並為未關帳的當月附加一筆 `is_current: true` 合成項。`months` 1–24（預設 6），或以 `period` 查單月。

#### GET /api/quota/history

原始 token 使用紀錄（ledger），支援 `since`／`until`／`cursor` 分頁。

#### GET /api/billing/wallet

呼叫者 account 層的 plan 與 credit 餘額。

> **要輪詢哪一個？**
>
> 做自動切換模型或預算告警，請輪詢 **`/api/quota/balance`**（三個 id 都帶）——它是唯一每筆請求都會更新的值。`billing/summary` 的彙總在數分鐘內落帳，適合報表，不適合即時決策。
