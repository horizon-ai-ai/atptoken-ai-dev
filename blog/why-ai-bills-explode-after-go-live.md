# Why LLM costs explode after launch: 5 control gaps and a worked example (2026)

> Source: https://atptoken.ai/blog/why-ai-bills-explode-after-go-live/
> Published: 2026-07-29 · By: hung-chien (AI Growth & Brand Manager)

LLM cost often jumps after launch because prompts grow. A RAG bot going from 2k to 9k input tokens adds $25,200 a month. Five control gaps and a 5-day fix.

## TL;DR

- LLM costs rise after launch because real users change the token shape of each request, while keys and spending limits are still set up for a pilot.
- Worked example: a support bot at 40,000 requests a day whose average input grows from 2,000 to 9,000 tokens goes from $14,400 to $39,600 a month on claude-sonnet-4-6.
- Close the five gaps in five working days: inventory keys, split projects, allocate ceilings, narrow allowlists, then log request IDs and review weekly.

LLM costs explode after launch when production traffic changes how many tokens each request carries, and the keys, ceilings, and model limits that would contain it are still set up for a pilot. The rate card rarely moves. This guide prices one realistic post-launch spike, then walks through five control gaps with the symptom you will see, the fix, and a five-day plan to close them.

| Gap | Symptom after launch | Fix |
|---|---|---|
| 1. Shared keys | One key carries most of the spend; revoking it breaks several services | One project and key per system |
| 2. No ceilings | The first warning is the invoice | Project allocation as the cap |
| 3. No per-request records | Nobody can say why the bill nearly tripled | Log request IDs and tokens per call |
| 4. No model allowlist | An expensive model appears in production | Allowed-model list per project |
| 5. No review cadence | Problems surface at month-end | Weekly review inside log retention |

## A post-launch LLM cost spike, worked out

A support bot answers questions with retrieval-augmented generation on [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/), ATP list rate $3 input and $15 output per million tokens as of October 2026. It handles 40,000 requests a day and writes about 400 output tokens per answer.

In the pilot, the average request carries 2,000 input tokens. After launch, users paste contracts and email threads into the chat, and retrieval adds more chunks to answer longer questions. Average input rises to 9,000 tokens.

| | Before launch | After launch |
|---|---|---|
| Input tokens per day | 40,000 × 2,000 = 80M | 40,000 × 9,000 = 360M |
| Input cost per day | 80 × $3 = $240 | 360 × $3 = $1,080 |
| Output cost per day | 16M × $15/M = $240 | 16M × $15/M = $240 |
| Total per day | $480 | $1,320 |
| Per month (30 days) | $14,400 | $39,600 |
| ATP credits per month | 1,440,000 | 3,960,000 |

The monthly delta is $25,200, a 2.75× bill. The model, its price, and the request count did not change. Nothing in a pricing table would have warned you. The only signal is average input tokens per request, which you see only if you record tokens per call.

## Gap 1: shared keys leave spend without an owner

Symptom: The Usage page shows one key responsible for most of the month's tokens. Three services, a cron job, and a contractor's notebook all use it. When the contractor leaves, revoking the key would break production the same afternoon, so nobody does.

Why launch makes it worse: At pilot volume, sharing costs little. After launch, any one of those consumers can spike, and the only lever is turning the key off for everyone.

Fix: Make the project the unit of ownership, with one project per production system and its own key. A key belongs to exactly one project and inherits that project's allowed models and balance, and the API keys page lists every key across workspaces and projects ([managing API keys](https://atptoken.ai/docs/console-keys)). Revoking a key stops it immediately and keeps it in the roster for audit.

## Gap 2: no ceilings, so the invoice is the alert

Symptom: The staging job that ran all weekend. A retry loop sends 2 requests a second for 48 hours: 345,600 requests at 3,000 input and 300 output tokens on claude-sonnet-4-6. Each costs $0.009 + $0.0045 = $0.0135, so the weekend costs $4,665.60, found on Monday.

Why launch makes it worse: Batch jobs, agents, and retries run unattended. Without a ceiling per workload, one hot path draws on the whole organisation's balance.

Fix: Allocate credits down the tree (organisation, workspace, project) and treat each project's allocation as its cap. A project can only spend what it was given; when the balance runs out, requests return `402`. With a 50,000-credit ($500) allocation on staging, the same loop stops after about 37,000 requests, roughly 5 hours in. Steps: [team with budget caps](https://atptoken.ai/docs/cb-budget-caps). Allocated versus Consumed for every level is on the Usage page ([how credits work](https://atptoken.ai/docs/credits)).

## Gap 3: no per-request records, so the month cannot explain itself

Symptom: Finance sees the bot go from $14,400 to $39,600. Engineering says nothing changed: same model, same price. The meeting ends without a cause.

Why launch makes it worse: Launch brings many changes at once: longer prompts, new retrieval settings, retry policy, more users. A monthly total cannot separate them.

Fix: Record project, key, model, status, and input/output tokens for every call. ATP Request logs show exactly these per request, filterable by time range, scope, model, status, and request ID ([usage and logs](https://atptoken.ai/docs/monitoring)). In the example above, filtering Request logs to the bot's project shows rows carrying about 9,000 input tokens each. Set against the 2,000 recorded during the pilot, that answers the question in minutes, provided someone wrote the pilot number down. Track average input tokens per request per project as a weekly number.

## Gap 4: no model allowlist, so the expensive path becomes the default

Symptom: Policy says a mid-tier model by default. Then a developer switches the bot to a stronger model to fix a tone complaint, and it ships.

Why launch makes it worse: Volume multiplies the price gap between models. The same post-launch traffic (40,000 requests a day, 9,000 input and 400 output tokens) costs very different amounts:

| Model (ATP list rate) | Per day | Per month |
|---|---|---|
| [claude-haiku-4-5](https://atptoken.ai/models/claude-haiku-4-5/) ($1 / $5) | $360 + $80 = $440 | $13,200 |
| claude-sonnet-4-6 ($3 / $15) | $1,080 + $240 = $1,320 | $39,600 |
| claude-opus-4-8 ($5 / $25) | $1,800 + $400 = $2,200 | $66,000 |

Fix: Keep an allowed-model list on each project. A request for a model outside it is rejected with `403` before it reaches any provider ([how it works](https://atptoken.ai/docs/how-it-works)). `GET /v1/models` shows what a key may call. Changing the bot's model then becomes a change to the project, made by an admin, instead of a one-line code edit.

## Gap 5: no review cadence, so problems wait for the invoice

Symptom: Nobody opens the Usage page between invoices. A cap raised for a one-off migration stays raised, and an unused key from a finished pilot stays active.

Why launch makes it worse: Controls checked once before launch drift afterwards: new keys, wider allowlists, larger allocations.

Fix: A light, fixed cadence:

| Cadence | What to check | Owner |
|---|---|---|
| Weekly | Usage by project, model, and key; Request logs before they expire (7-day retention); average input tokens per request | Platform team |
| Monthly | Allocated versus Consumed per project; projects flagged In debt; keys with no traffic | Finance and platform |
| Quarterly | Roles and members per project; allowlists; projects with no owner | Security and platform |

The Activity log records sign-ins, invites, quota changes, and resource updates, which covers most of the quarterly check.

## Close the five gaps in five working days

### Day 1 (Monday): inventory

Open the API keys page, which lists every key across workspaces and projects. For each key, write down which systems use it and who owns it. Mark every key used by more than one system.

### Day 2 (Tuesday): split

Create one project per production system and issue new keys. Move the highest-spend service first. Set a revocation date for each shared key.

### Day 3 (Wednesday): allocate ceilings

Take each project's consumption for the last 30 days, add headroom for planned growth, and allocate that as the monthly ceiling. For the support bot after launch, that is at least 3,960,000 credits. Give staging and experiments small allocations.

### Day 4 (Thursday): narrow allowlists

Enable only the models each project needs. Call a disallowed model once from each project to confirm the `403`.

### Day 5 (Friday): instrument and schedule

Log the `x-request-id` header from every response next to your own feature or tenant ID. Put the weekly review on the calendar, and rehearse one key revocation end to end: revoke, check the logs, reissue.

For the per-step version of the same problem, see [what is the agent tax](https://atptoken.ai/blog/what-is-the-agent-tax). To set up the first project and key, follow the [quickstart](https://atptoken.ai/docs/quickstart).

## Related reading

- [Enterprise AI cost management guide](https://atptoken.ai/blog/enterprise-ai-cost-management-guide)
- [AI spending caps that work](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [How to read your AI bill](https://atptoken.ai/blog/how-to-read-your-ai-bill)

## FAQ

### Why do LLM API costs increase after launch?

Unit prices usually stay the same; the tokens per request change. Users paste documents, conversations get longer, retries and agent steps multiply calls, and more teams start using the same keys, so the same rate card is applied to far more tokens.

### How do I estimate monthly LLM cost?

Multiply requests per day by (average input tokens × input rate + average output tokens × output rate) per million tokens, then by 30. For 40,000 requests a day at 9,000 input and 400 output tokens on a $3/$15 model, that is $1,320 a day or $39,600 a month.

### Where should an enterprise set AI spending caps?

At the project or workload level, so each system has its own ceiling. A single organisation-wide limit tells you spend ran out, not which system to slow down or which key to revoke.

### Can we close these gaps without a gateway?

Partly. You can inventory keys in a spreadsheet, use each vendor's project limits, and ship request logs into existing monitoring. A gateway puts keys, allowlists, and ceilings for several vendors in one place, so they are on by default instead of maintained by hand.

---

Tags: LLM cost, AI billing, ATP
