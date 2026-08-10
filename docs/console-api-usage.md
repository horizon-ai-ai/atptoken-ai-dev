# Usage & balance

> Source: https://atptoken.ai/docs/console-api-usage/

`GET /api/quota/balance`

Credits flow down the hierarchy Account → Org → Workspace → Project. **Only the project (leaf) balance is consumed in real time** — the gateway decrements it on every request. Org and workspace balances are allocation pools that change only when you allocate or refund.

#### GET /api/quota/balance

The endpoint for automation. `proj_balance` is read from the live store the gateway decrements on each request, so it reflects usage instantly; `proj_inflight` is the amount reserved by requests still running.

| Param | Type | Description |
|---|---|---|
| org_id | string · required | Organization id. |
| workspace_id | string | Adds workspace scope. |
| project_id | string | Requires workspace_id; returns the real-time project balance. |

```
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"
```

#### GET /api/quota/status

Same three-level balances in a block-per-level shape. Returns remaining balance only — the credit model stores no "initial quota", so no usage-percentage field.

#### GET /api/billing/summary

Monthly usage and billing rollup: per-model token totals, request counts, metered quantities and credits for the chosen `period` (`YYYY-MM`, defaults to the current UTC month). Scope-wide — covers all keys in the org/workspace/project.

| Param | Type | Description |
|---|---|---|
| org_id | string · required | Organization id. |
| period | string | `YYYY-MM` (UTC). Defaults to current month. |
| workspace_id / project_id | string | Narrow the scope. |

#### GET /api/billing/usage-by-key

Monthly usage per API key. **Returns only keys created by the calling user** — it is a personal view, not an org-wide report (use `billing/summary` for that).

#### GET /api/billing/usage-series

Daily usage trend for one month (UTC buckets), with `interval` and `group_by` options. Personal view, same as usage-by-key.

#### GET /api/quota/monthly

Historical month-end snapshots (closed by the worker at month boundary), plus a synthetic `is_current: true` entry for the open month. `months` 1–24 (default 6) or a single `period`.

#### GET /api/quota/history

Raw token-usage ledger records with `since`/`until`/`cursor` paging.

#### GET /api/billing/wallet

Account-level plan and credit balance for the calling account.

> **Which endpoint should I poll?**
>
> For automatic model switching or budget alarms, poll **`/api/quota/balance`** with all three ids — it is the only value updated on every single request. `billing/summary` aggregates settle within minutes and are for reporting, not admission decisions.
