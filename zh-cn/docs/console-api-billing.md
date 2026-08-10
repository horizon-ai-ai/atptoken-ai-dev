# 帐务与储值

> Source: https://atptoken.ai/zh-cn/docs/console-api-billing/

`GET /api/billing/events`

#### GET /api/billing/events

逐笔计费活动（Console 里 90 天 ledger 视图的 API 版）。可依时间区间、模态、模型、计费状态、key 或 request id 过滤；`cursor` 分页。

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 组织 id。 |
| from / to | string | 时间区间（ISO 8601）。 |
| modality / unified_model_name | string | 依模态或模型过滤。 |
| billing_status | string | 例：billed／pending／unbilled。 |
| api_key_doc_id / request_id | string | 下钻到单一 key 或单一请求。 |
| limit / cursor | — | 分页。 |

#### GET /api/billing/topups

呼叫者 account 的储值纪录（ledger 并上即时付款状态）。

#### GET /api/billing/topup-status

以 `session_id` 轮询单笔结帐的入帐状态。

#### GET /api/billing/checkout-url

依 `sku` 回传付款连结 URL —— Console 储值按钮的 API 版。

#### GET /api/me/manual-credit-history

自己帐号的人工 credit 调整历史（拨补、更正），支援 `action`、时间区间与 offset 分页。
