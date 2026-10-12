# 帳務與儲值

> Source: https://atptoken.ai/zh-tw/docs/console-api-billing/

`GET /api/billing/events`

讀取計費活動與儲值紀錄、輪詢結帳狀態、取得付款連結，以及查詢人工點數調整歷史。

## 計費活動

### GET /api/billing/events

逐筆計費活動（主控台裡 90 天 ledger 視圖的 API 版）。可依時間區間、模態、模型、計費狀態、金鑰或 request id 過濾；`cursor` 分頁。

| Param | Type | Description |
|---|---|---|
| org_id | string · 必填 | 組織 id。 |
| from / to | string | 時間區間（ISO 8601）。 |
| modality / unified_model_name | string | 依模態或模型過濾。 |
| billing_status | string | 例：billed／pending／unbilled。 |
| api_key_doc_id / request_id | string | 下鑽到單一金鑰或單一請求。 |
| limit / cursor | — | 分頁。 |

## 儲值與結帳

### GET /api/billing/topups

呼叫者 account 的儲值紀錄（ledger 併上即時付款狀態）。

### GET /api/billing/topup-status

以 `session_id` 輪詢單筆結帳的入帳狀態。

### GET /api/billing/checkout-url

依 `sku` 回傳付款連結 URL——主控台儲值按鈕的 API 版。

## 人工點數調整

### GET /api/me/manual-credit-history

自己帳號的人工點數調整歷史（撥補、更正），支援 `action`、時間區間與 offset 分頁。

## 下一步

- [用量與餘額](https://atptoken.ai/zh-tw/docs/console-api-usage/) — 即時餘額與每月用量。
- [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/) — 從帳單頁替隨用隨付（PAYG）錢包儲值。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 一點點數值多少，以及點數如何下放到專案。
