# 帐务与充值

> Source: https://atptoken.ai/zh-cn/docs/console-api-billing/

`GET /api/billing/events`

读取计费活动与充值记录、轮询结帐状态、取得付款连结，以及查询人工点数调整历史。

## 计费活动

### GET /api/billing/events

逐笔计费活动（控制台里 90 天 ledger 视图的 API 版）。可依时间区间、模态、模型、计费状态、密钥或 request id 过滤；`cursor` 分页。

| Param | Type | Description |
|---|---|---|
| org_id | string · 必填 | 组织 id。 |
| from / to | string | 时间区间（ISO 8601）。 |
| modality / unified_model_name | string | 依模态或模型过滤。 |
| billing_status | string | 例：billed／pending／unbilled。 |
| api_key_doc_id / request_id | string | 下钻到单一密钥或单一请求。 |
| limit / cursor | — | 分页。 |

## 充值与结帐

### GET /api/billing/topups

呼叫者 account 的充值记录（ledger 并上即时付款状态）。

### GET /api/billing/topup-status

以 `session_id` 轮询单笔结帐的入帐状态。

### GET /api/billing/checkout-url

依 `sku` 回传付款连结 URL——控制台充值按钮的 API 版。

## 人工点数调整

### GET /api/me/manual-credit-history

自己账号的人工点数调整历史（拨补、更正），支持 `action`、时间区间与 offset 分页。

## 下一步

- [用量与余额](https://atptoken.ai/zh-cn/docs/console-api-usage/) — 即时余额与每月用量。
- [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/) — 从账单页替随用随付（PAYG）钱包充值。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 一点点数值多少，以及点数如何下放到项目。
