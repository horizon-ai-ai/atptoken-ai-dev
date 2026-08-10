# Billing & top-ups

> Source: https://atptoken.ai/docs/console-api-billing/

`GET /api/billing/events`

#### GET /api/billing/events

Line-item billing activity (the 90-day ledger view shown in the console). Filter by time range, modality, model, billing status, key or request id; `cursor` paging.

| Param | Type | Description |
|---|---|---|
| org_id | string · required | Organization id. |
| from / to | string | Time range (ISO 8601). |
| modality / unified_model_name | string | Filter by modality or model. |
| billing_status | string | e.g. billed / pending / unbilled. |
| api_key_doc_id / request_id | string | Drill down to one key or one request. |
| limit / cursor | — | Paging. |

#### GET /api/billing/topups

Top-up records for the calling account (ledger entries enriched with live payment status).

#### GET /api/billing/topup-status

Poll the status of one checkout session (`session_id`) until the payment lands.

#### GET /api/billing/checkout-url

Returns a payment link URL for a given `sku` — the API equivalent of the console's top-up button.

#### GET /api/me/manual-credit-history

Manual credit adjustments applied to your account (grants, corrections), with `action`, time range and offset paging.
