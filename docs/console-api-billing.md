# Billing & top-ups

> Source: https://atptoken.ai/docs/console-api-billing/

`GET /api/billing/events`

Read billing events and top-up records, poll a checkout session, get a payment link, and list manual credit adjustments.

## Billing events

### GET /api/billing/events

Line-item billing activity (the 90-day ledger view shown in the console). Filter by time range, modality, model, billing status, key or request id; `cursor` paging.

| Param | Type | Description |
|---|---|---|
| org_id | string · required | Organization id. |
| from / to | string | Time range (ISO 8601). |
| modality / unified_model_name | string | Filter by modality or model. |
| billing_status | string | e.g. billed / pending / unbilled. |
| api_key_doc_id / request_id | string | Drill down to one key or one request. |
| limit / cursor | — | Paging. |

## Top-ups and checkout

### GET /api/billing/topups

Top-up records for the calling account (ledger entries enriched with live payment status).

### GET /api/billing/topup-status

Poll the status of one checkout session (`session_id`) until the payment lands.

### GET /api/billing/checkout-url

Returns a payment link URL for a given `sku` — the API equivalent of the console's top-up button.

## Manual credit adjustments

### GET /api/me/manual-credit-history

Manual credit adjustments applied to your account (grants, corrections), with `action`, time range and offset paging.

## Next steps

- [Usage & balance](https://atptoken.ai/docs/console-api-usage/) — Real-time balance and monthly usage.
- [Top up & wallet](https://atptoken.ai/docs/topup/) — Fund the pay-as-you-go wallet from the Billing page.
- [How credits work](https://atptoken.ai/docs/credits/) — What a credit is worth and how credits flow down to projects.
