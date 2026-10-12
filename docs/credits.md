# How credits work

> Source: https://atptoken.ai/docs/credits/

Usage is paid for in credits. **1 credit = USD 0.01** (100 credits = USD 1).

## Expiry and balance display

Pay-as-you-go credits don't expire (committed contract credits may carry an expiry date — see Top up & wallet). Balances are shown to four decimal places; a non-zero amount below that shows as `<0.0001`.

## How credits flow down the hierarchy

Credits flow down the hierarchy — organization → workspace → project — and a key spends from its project's balance. Each level reports the same four figures:

| Term | Meaning |
|---|---|
| Available | Credits you can spend or allocate at this level. |
| Received | Total credits received from the parent level. |
| Allocated | Credits pushed down to child workspaces or projects. |
| Consumed | Credits actually spent on API calls (project level). |

If a project spends more than it was allocated it is flagged **In debt** until topped up.

## Next steps

- [Top up & wallet](https://atptoken.ai/docs/topup/) — Buy credits and see where top-ups land.
- [Workspaces & projects](https://atptoken.ai/docs/resources/) — Allocate credits from a workspace to a project.
- [Tracking spend](https://atptoken.ai/docs/spend/) — Compare Allocated and Consumed at each level.
