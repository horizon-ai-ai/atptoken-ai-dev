# From one request to month-end reconciliation

> Source: https://atptoken.ai/docs/console-reconcile/

Follow one request through the Console — Request logs, Credit charges, Runway, and the month-end reconciliation CSV.

## Before you start

- A project API key that has already sent at least one request. The [Quickstart](https://atptoken.ai/docs/quickstart/) gets you there.
- The request ID of the call you want to trace. Every response carries it in the `x-request-id` header, and the `id` in the response body is the same value.
- All four views live under **Usage** in the Console sidebar, as tabs: Usage, Request logs, Credit charges, and Reconciliation. The workspace and project filters at the top of the Usage page set the scope for every tab.

## 1. Find the request in Request logs

Open **Usage → Request logs**. On the Console overview, **View all** next to **Recent requests** opens the same tab.

Filter by time range (the last 24 hours by default; logs are kept for 7 days), **Status**, **Model**, or **Request ID** — paste the full request ID. Filters apply as soon as you change them.

| Column | What it shows |
|---|---|
| Request ID | The request ID, with a copy button. Quote it when you contact support |
| Time | Shown in your local timezone |
| Model | The model id the request called |
| Caller | The key label for API calls, or the signed-in person for calls made from the Studio |
| Status | The HTTP status code. A code of 400 or above links to its entry in [Error codes](https://atptoken.ai/docs/errors/) |
| Credits | Credits charged for this request, or its charge status |
| Request usage | The usage this request reported |

Modality and Endpoint columns appear on wide screens. Polls for the same media task collapse into one row that you can expand.

> **Request logs are not the billing ledger**
>
> Request logs are for API troubleshooting and are kept for 7 days. Use Credit charges and Reconciliation for billing.

## 2. Check the charge in Credit charges

The **Credits** column in Request logs already shows the charge status. Open **Usage → Credit charges** for the charge detail of a billing month.

| Status | `billing_status` | In the Credits column |
|---|---|---|
| Charged | `billed` | The credits charged, to four decimal places |
| Settling | `pending` | Settling |
| Not charged | `unbilled` | Not charged |
| No charge | `not_billable` | No charge. Request logs also show No charge for a status of 400 or above with 0 credits |

Credit charges has the columns Request ID, Time, Model, Modality, Billed quantity, Status, and Credits, and filters for billing month, modality, and status. Match a row to Request logs by its Request ID.

The rows show your own activity (your keys and your console session); the period total at the top covers the whole scope. Billing months here follow UTC.

## 3. Read usage and runway

**Usage → Usage** shows usage and spend for the selected scope, and **Export CSV** downloads `usage-{period}.csv` for a UTC month.

The Console overview shows **Runway** in its Today row: how many days your available credits last at your recent burn rate.

- Runway = (available balance − in-flight credits) ÷ the daily average of your own keys, rounded down.
- The daily average covers up to 7 full UTC days before today; today is not counted.
- With fewer than 3 full days of data, the card shows that it needs 3 full days instead of a number.
- When runway drops below 7 days and auto top-up is not covering you, the overview raises an alert with the days left.

For a team organization, runway divides the organization balance by your own keys' daily average.

## 4. Export the month-end CSV

Open **Usage → Reconciliation** and choose a month. Months follow Taiwan time (UTC+8), and the list covers the last 15 months.

The table sums the billing ledger's hourly data by Taiwan day × model × modality, with the columns Date (TW), Model, Modality, Requests, and Credits. Days with several rows collapse into a day total, and the cards above show the month total by modality. Amounts are in credits.

**Export CSV** downloads `atp-reconcile-{YYYY-MM}.csv`; with a project selected the name ends in `-project`, with only a workspace selected in `-workspace`.

```text
date,model,modality,requests,credits_charged
YYYY-MM-DD,"<model>",<modality>,<requests>,<credits>
YYYY-MM TOTAL,,,<requests>,<credits>
```

Credits in the CSV have six decimal places. The file is UTF-8 with a BOM and CRLF line endings, so Excel opens it cleanly.

> **Re-check before you close the month**
>
> When media tasks are not yet posted to the ledger, Reconciliation shows how many are still pending — totals may still change.

## Check that it worked

- The Request ID from your response appears in both Request logs and Credit charges.
- The `TOTAL` row of the CSV matches **Month total** on the Reconciliation tab.
- Reconciliation covers your own keys and console session. For the whole organization's monthly total, use the period total in Credit charges.
- Credit charges and the Usage CSV use UTC months; Reconciliation uses Taiwan months. The first 8 hours of a Taiwan month fall in the previous UTC month, so the two totals can differ at the edges.

## Next steps

- [Usage & logs](https://atptoken.ai/docs/monitoring/) — The three places that show what happened and what it cost.
- [How credits work](https://atptoken.ai/docs/credits/) — Available, received, and used credits.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code in Request logs means.
