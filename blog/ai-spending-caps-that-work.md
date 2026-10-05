# AI API spending limits compared: OpenAI, Anthropic, OpenRouter, Vercel and ATP Token (2026)

> Source: https://atptoken.ai/blog/ai-spending-caps-that-work/
> Published: 2026-08-12 · By: hung-chien (AI Growth & Brand Manager)

AI API spending limits compared: how OpenAI usage limits, Claude workspace caps, OpenRouter, Vercel and ATP Token behave at the limit, with a worked budget.

## TL;DR

- The same word, spend limit, means different things: OpenAI's hard limit returns 429, Anthropic's workspace limit returns 400, Vercel and OpenRouter key limits return 402, and an OpenRouter guardrail returns 403.
- Reset periods differ too: OpenAI and Anthropic reset monthly, OpenRouter and Vercel let you pick daily, weekly or monthly, and an ATP Token project allocation does not reset until you add credits.
- Split a budget by workload: a USD 2,000 month becomes 200,000 credits across a production bot, a staging project, a coding-agent sandbox and an unallocated reserve.

An AI API spending limit is a cap on how much model usage a key, project, workspace or organization can spend before the platform stops serving its requests. Where you set the limit matters as much as the amount: the five places compared below differ in scope, in reset period and in the HTTP status your code receives when the limit is reached. This guide compares them as of October 2026 and finishes with a USD 2,000 monthly budget split into ATP Token credits, with the arithmetic shown.

## AI API spending limits at a glance

| Where you set it | Scope | Reset | At the limit | Status code |
|---|---|---|---|---|
| [OpenAI API](https://developers.openai.com/api/docs/guides/rate-limits) | Organization or project | Monthly | Spend alert: notification only, traffic continues. Hard limit: affected requests fail | 429 |
| [Anthropic Console](https://platform.claude.com/docs/en/api/rate-limits) | Organization or workspace (workspace limit cannot exceed the org limit) | Monthly | Requests rejected until the limit is raised or the month ends | 400 for a limit you set; 429 for the tier cap |
| [OpenRouter guardrails](https://openrouter.ai/docs/guides/features/guardrails) | Per member or per API key | Daily, weekly or monthly | Requests rejected | 403 |
| [OpenRouter key credit limit](https://openrouter.ai/docs/api-reference/limits) | Per API key | Daily, weekly, monthly or never | Requests rejected | 402 |
| [Vercel AI Gateway budgets](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets) | Team, project, API key or team member | Daily, weekly, monthly or none | Soft cap: the request that crosses the limit completes, later ones are rejected | 402 |
| [ATP Token](https://atptoken.ai/docs/credits) | Project, funded organization to workspace to project | No reset; the allocation stays until spent or moved | Requests rejected once the project balance is exhausted | 402 |

The status code column is the one engineers tend to skip, and it decides what your client does next. A 429 looks like an ordinary rate limit, so most SDKs retry it automatically. Anthropic's documentation notes that its spend-cap 429 carries no `retry-after` header and retries fail until access resumes. A 402 or 400 will not succeed on retry either. Your client should read the error body and stop.

## How each platform enforces a spend limit

### OpenAI: project spend limits

OpenAI recommends separate projects for staging and production and lets you [set custom rate and spend limits per project](https://developers.openai.com/api/docs/guides/production-best-practices). In the project's Limits settings you set a monthly spend limit, a notification threshold and which models the project may use ([OpenAI Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)).

A spend alert sends a notification and lets traffic continue. A hard spend limit makes affected requests return 429. Above both sits the usage tier: Tier 1 allows USD 100 a month and Tier 5 allows USD 200,000. The watch-out is the shared status code. A retry loop that handles rate limits will keep hammering a project that is out of budget unless you check the error body.

### Anthropic Console: workspace spend limits

Claude Console [workspaces](https://platform.claude.com/docs/en/manage-claude/workspaces) each get a monthly spend limit and per-model rate limits, set lower than (never higher than) the organization's. API keys can be scoped to a single workspace. You cannot set limits on the Default Workspace, so keys you want capped belong in a named workspace.

When a limit you set is reached, requests return HTTP 400 with `invalid_request_error`, and the message says when access resumes. The tier cap (USD 500 a month on Start, USD 1,000 on Build, USD 200,000 on Scale) returns 429 and pauses usage until 00:00 UTC on the first of the next month. The Claude Code workspace that the Console creates automatically is the only workspace with per-user monthly spend limits.

### OpenRouter: guardrails and per-key credit limits

OpenRouter has two separate mechanisms. Guardrails are set by organization admins per member or per API key and can carry a USD spending cap that resets daily, weekly or monthly; requests over the cap get 403. A guardrail can also hold a model allowlist and a provider allowlist, and when several guardrails apply, the strictest rule wins.

Per-key credit limits work on every plan. Each key has a `limit` and a `limit_reset` of daily, weekly, monthly or none, with resets at midnight UTC. An exhausted key returns 402. Workspace-level budgets are an Enterprise feature ([OpenRouter blog](https://openrouter.ai/blog/insights/governing-team-ai-spend/)).

### Vercel AI Gateway: stacked budgets

Vercel budgets apply at four scopes (team, project, API key and team member) and stack, so a request must pass every budget in scope. Refresh periods are daily, weekly, monthly or none, all in UTC. An exceeded budget returns 402 with `quota_for_entity_exceeded`, and the message names the scope that ran out.

Vercel calls its budget a soft cap: the check runs at the start of each request, so the request that crosses the limit still completes. Optional email alerts fire at 50, 75 and 100 percent. Two details catch teams out. API key spend never counts toward a project budget (project budgets only see that project's deployment OIDC tokens), and BYOK spend is not counted in any budget.

### ATP Token: prepaid allocation per project

In ATP Token the cap is the money itself. Credits (1 credit = USD 0.01) flow from organization to workspace to project, and every key spends from its own project's balance. A project can only spend what it was allocated. When the balance is exhausted, the gateway rejects the request with 402 at the metering step ([how it works](https://atptoken.ai/docs/how-it-works)). A project that spends more than it was allocated is flagged In debt until topped up.

There is no reset period. Pay-as-you-go credits do not expire, so an allocation you do not use carries over to the next month. A monthly budget therefore needs a monthly allocation step, or project auto top-up: a pay-as-you-go project can refill itself when its balance drops below a threshold, limited by a per-charge cap and a monthly charge cap. With auto top-up on, that monthly charge cap is the ceiling that matters.

## Design rules for limits teams will keep

1. **Cap each workload separately.** One project per production service, one for staging, one per sandbox. An organization-wide limit stops every product at once, healthy ones included. [One project, one key](https://atptoken.ai/blog/one-project-one-key) covers the key side.
2. Treat budget errors as final in client code. Map 402, the Anthropic 400 limit error and a spend-limit 429 to "stop and notify the owner", never to exponential backoff.
3. Size each cap from unit cost. Tokens per request times the model's rate times expected volume gives a number you can explain to finance and adjust when traffic changes.
4. Keep an unallocated reserve at the top. If production runs dry on the 27th, an admin can move credits in minutes without touching staging.
5. Review Allocated against Consumed weekly. On ATP Token the [Usage page](https://atptoken.ai/docs/spend) shows both at every level of the tree. If you want an automated alarm, poll the real-time project balance from the [Console API](https://atptoken.ai/docs/console-api-usage) and post to your own channel.

## Worked example: a USD 2,000 monthly AI budget in credits

USD 2,000 is 200,000 credits. Here is one way to split it across three workloads and a reserve.

| Project | Workspace | Allowed models | Allocation | What it covers |
|---|---|---|---|---|
| support-bot-prod | Production | [claude-haiku-4-5](https://atptoken.ai/models/claude-haiku-4-5/) | 140,000 credits (USD 1,400) | About 400,000 replies |
| support-bot-staging | Pre-production | claude-haiku-4-5 | 10,000 credits (USD 100) | About 28,500 test calls |
| coding-agent-sandbox | Engineering | [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/) | 30,000 credits (USD 300) | About 23 developer-days |
| Unallocated reserve | Organization | none | 20,000 credits (USD 200) | Emergency top-ups |

The support bot. claude-haiku-4-5 has an ATP list rate of USD 1 per million input tokens and USD 5 per million output tokens. A typical reply with 2,000 input tokens and 300 output tokens costs 2,000 × 1 / 1,000,000 + 300 × 5 / 1,000,000 = USD 0.0035, or 0.35 credits. 140,000 credits ÷ 0.35 = 400,000 replies a month, about 13,300 a day.

The staging job that ran all weekend. Suppose a retry bug fires 5 requests a second at the same 0.35 credits each. That burns 1.75 credits a second, so the 10,000-credit staging allocation lasts 10,000 ÷ 1.75 ≈ 5,700 seconds, about 95 minutes. Staging then gets 402 and production keeps answering customers. Without the split, the same loop running from Friday 18:00 to Monday 09:00 (63 hours, 226,800 seconds) would spend 226,800 × 1.75 = 396,900 credits, almost twice the whole monthly budget.

The coding agent. Anthropic puts the average Claude Code cost at [around USD 13 per developer per active day](https://code.claude.com/docs/en/costs). At that rate, USD 300 covers about 23 developer-days, roughly one developer for a working month. When the sandbox hits 402 mid-afternoon, that is the signal to look at the session before adding credits. The [agent tax](https://atptoken.ai/blog/what-is-the-agent-tax) explains why agent sessions cost more per task than single calls.

On the first of the next month nothing resets. If the support bot used 120,000 credits, it still holds 20,000; allocate another 120,000 to bring it back to 140,000.

## Setting this up in ATP Token

1. Create a Team organization, then the workspaces (Production, Pre-production, Engineering) on the Resources page ([set up your organization](https://atptoken.ai/docs/console-setup)).
2. Create each project and pick its allowed models. Every project needs at least one ([workspaces and projects](https://atptoken.ai/docs/resources)).
3. Allocate credits down the tree: organization, then workspace, then project. Leave the reserve unallocated at the organization level.
4. Issue one key per project. The key inherits the project's models and balance ([managing API keys](https://atptoken.ai/docs/console-keys)).
5. Handle 402 in your client as "budget exhausted" and alert the project owner ([common responses](https://atptoken.ai/docs/errors)).

[Set up a team with budget caps](https://atptoken.ai/docs/cb-budget-caps)

## Related reading

- [Why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live)
- [One project, one key](https://atptoken.ai/blog/one-project-one-key)
- [Coding agents cost control checklist](https://atptoken.ai/blog/coding-agents-cost-control-checklist)

## FAQ

### What are OpenAI usage limits?

OpenAI has two kinds. Usage tiers set a monthly ceiling for the organization (Tier 1 is USD 100 a month, Tier 5 is USD 200,000), and you can set your own spend limit per organization or per project. A spend alert only notifies you; a hard spend limit makes affected requests return 429.

### Can I set a spending limit on the Claude API?

Yes. In the Claude Console you can set a monthly spend limit for the organization and for each workspace, as long as the workspace limit is not higher than the organization's. You cannot set limits on the Default Workspace. When a limit you set is reached, requests return HTTP 400 with an invalid_request_error until the limit is raised or the next month starts.

### What happens when an AI API key hits its spending limit?

It depends on the platform. OpenAI hard limits return 429, Anthropic user-set limits return 400, Vercel AI Gateway budgets and OpenRouter per-key credit limits return 402, OpenRouter guardrail budgets return 403, and ATP Token returns 402 when the project balance is exhausted. Treat all of these as stop signals in your retry logic.

### Do ATP Token spending limits reset every month?

No. An ATP Token project can spend only the credits allocated to it, and pay-as-you-go credits do not expire, so unspent allocation carries over. To run a monthly budget you allocate again each month, or enable project auto top-up with a monthly charge cap.

### Should staging and experiments share the production AI budget?

No. Give staging and sandboxes their own project or workspace with a small cap. A staging retry loop then stops on its own limit and production keeps serving.

---

Tags: AI API spending limits, OpenAI usage limits, AI budget, ATP
