# Token-based pricing vs per-seat AI: a budgeting guide for finance leads (2026)

> Source: https://atptoken.ai/blog/from-seats-to-tokens-ai-budgeting/
> Published: 2026-09-04 · By: hung-chien (AI Growth & Brand Manager)

Token based pricing for finance leads: a 40-person seat vs token cost comparison, break-even math, a credits chargeback model and a monthly AI budget worksheet.

## TL;DR

- Token-based pricing charges per input and output token at a per-model rate, so cost follows usage rather than headcount. Per-seat pricing charges a flat fee per named user whether they use it daily or twice a month.
- In a worked 40-person example, Claude Team standard seats cost $1,000 a month on monthly billing, while the same team's chat usage priced at claude-sonnet-4-6 list rates comes to $586.15, with 8 heavy users above the seat price and 32 users far below it.
- Budget tokens per project: estimate requests × tokens × rate, add a buffer, allocate credits per project, and charge back on consumed credits at month-end.

Token-based pricing is a billing model where you pay for the tokens an AI model reads and writes, at a per-million-token rate set per model, instead of a fixed fee per user. This guide puts per-seat and token pricing side by side for a 40-person team, works out the break-even point, and gives a finance lead a chargeback model and a monthly budgeting worksheet to copy.

| | Per-seat subscription | Token-based (API) |
|---|---|---|
| You pay for | Named users per month | Input and output tokens per request |
| Cost driver | Headcount | Requests × tokens × model rate |
| Light or idle users | Full seat price each | Close to zero |
| Heavy users | Same seat price | Can exceed a seat |
| How you cap it | Number of seats | Budget per project or key |

## Three AI pricing models finance will meet

As of October 2026, the [Claude pricing page](https://claude.com/pricing) shows all three models from a single vendor:

- Per seat: Claude Team standard seats are $25 per seat per month billed monthly, or $20 billed annually. Premium seats are $125 monthly or $100 annually.
- Seat plus usage: Claude Enterprise lists "Seat price + usage at API rates", at $20 per seat per month billed annually, with usage cost that scales with model and task.
- Token-based: API access charged per token. Claude Sonnet 4.6 is $3 per 1M input tokens and $15 per 1M output tokens ([Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)), the same as the ATP list rate for [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/).

Most companies end up with a mix: seats for people who chat with a model all day, and token billing for the applications, automations and agents that call models from code.

## Worked comparison: a 40-person team

Assumptions for one month with 21 working days, all requests on claude-sonnet-4-6 at $3 / $15:

- A standard request is 3,000 input and 600 output tokens: 3,000 × $3 ÷ 1M + 600 × $15 ÷ 1M = $0.009 + $0.009 = $0.018.
- A long-document request is 20,000 input and 600 output tokens: $0.06 + $0.009 = $0.069.

| User group | People | Requests per working day | Cost per request | Token cost per person per month | Group total |
|---|---|---|---|---|---|
| Heavy, long documents | 8 | 40 | $0.069 | $57.96 | $463.68 |
| Regular | 20 | 15 | $0.018 | $5.67 | $113.40 |
| Light | 12 | 2 | $0.018 | $0.756 | $9.07 |
| Total | 40 | | | | $586.15 |

The same 40 people on Claude Team standard seats cost 40 × $25 = $1,000 a month on monthly billing, or 40 × $20 = $800 on annual billing.

Three things finance should take from this table:

1. Break-even is per person. At $0.018 per request, a user matches a $25 seat at $25 ÷ $0.018 = 1,389 requests a month, about 66 per working day. At $0.069 per request it is about 362 a month, or 17 per working day.
2. The heavy group costs $57.96 per person on tokens, more than twice a $25 seat. The light group costs under $1 per person.
3. The comparison prices model usage only. A seat includes the vendor's chat apps and features; token usage needs an internal tool or integration to call the API, which has its own cost.

Agentic work changes the scale. Anthropic reports Claude Code averages around $13 per developer per active day and $150 to $250 per developer per month ([Claude Code costs](https://code.claude.com/docs/en/costs)), several times the chat usage above. Budget coding agents as their own line.

## A chargeback model with credits per project

Seat chargeback is simple: seats × price per department. Token chargeback needs one more step, because spend lands on workloads rather than on people. The model that holds up at month-end close:

- Each workload is a project with its own key, grouped into a workspace per department.
- Finance funds the organization, and each project gets a monthly allocation in credits (1 credit = USD 0.01).
- Each cost center is charged for credits consumed, not credits allocated.

Example month, using the allocations from the worksheet in the next section:

| Workspace | Project | Allocated credits | Consumed credits | Used | Chargeback |
|---|---|---|---|---|---|
| Support | support-bot-prod | 145,000 | 118,240 | 81.5% | $1,182.40 |
| Support | ticket-triage | 1,500 | 1,105 | 73.7% | $11.05 |
| Sales | proposal-drafts | 27,000 | 26,880 | 99.6% | $268.80 |
| Engineering | code-review-bot | 49,000 | 37,615 | 76.8% | $376.15 |
| All staff | team-assistant | 70,500 | 61,020 | 86.6% | $610.20 |
| Total | | 293,000 | 244,860 | 83.6% | $2,448.60 |

By department: Support $1,193.45, Sales $268.80, Engineering $376.15, All staff $610.20. The 48,140 unspent credits stay on the project balances, since pay-as-you-go credits do not expire, so next month's allocation can be smaller. Proposal-drafts used 99.6% of its allocation, which is the signal to ask its owner whether volume grew before raising the number.

## Monthly AI budgeting worksheet

Fill one row per workload. Take requests and average tokens from one full week of request logs and multiply by 4.33 weeks.

| Project | Model | Requests / month | Avg input / output tokens | Cost per request | Monthly cost | With 20% buffer | Credits |
|---|---|---|---|---|---|---|---|
| support-bot-prod | claude-sonnet-4-6 | 120,000 | 1,284 / 412 | $0.010032 | $1,203.84 | $1,444.61 | 144,461 |
| ticket-triage | [qwen-3-7-flash](https://atptoken.ai/models/qwen-3-7-flash/) | 400,000 | 800 / 50 | $0.0000305 | $12.20 | $14.64 | 1,464 |
| proposal-drafts | [gpt-5.5](https://atptoken.ai/models/gpt-5.5/) | 3,000 | 6,000 / 1,500 | $0.075 | $225.00 | $270.00 | 27,000 |
| code-review-bot | claude-sonnet-4-6 | 8,000 | 12,000 / 1,000 | $0.051 | $408.00 | $489.60 | 48,960 |
| team-assistant (long docs) | claude-sonnet-4-6 | 6,720 | 20,000 / 600 | $0.069 | $463.68 | $556.42 | 55,642 |
| team-assistant (standard) | claude-sonnet-4-6 | 6,804 | 3,000 / 600 | $0.018 | $122.47 | $146.97 | 14,697 |
| Total | | | | | $2,435.19 | $2,922.23 | 292,224 |

Rounded up per project, the allocations are 145,000, 1,500, 27,000, 49,000 and 70,500 credits, 293,000 in total. Three Scale top-ups of USD 1,000 (100,000 credits each) fund 300,000 credits and leave 7,000 unallocated at the organization level as a reserve. Rates come from each model's page; qwen-3-7-flash uses its rate for prompts up to 32K tokens.

## What makes a token budget miss

- A model switch. Moving proposal-drafts from gpt-5.5 to claude-sonnet-4-6 changes its cost per request from $0.075 to $0.0405, with no change in volume. Check the [model compare pages](https://atptoken.ai/models/compare/) before and after.
- Context growth. If support-bot prompts grow from 1,284 to 4,000 input tokens, cost per reply rises from $0.010032 to $0.01818.
- Reasoning tokens. OpenAI and Anthropic bill reasoning tokens as output, so turning on extended thinking can multiply output cost without a visible change in answers.
- Agents. Each step resends context; Anthropic reports agent teams use approximately 7× more tokens than standard sessions in plan mode.

A weekly look at consumed against allocated catches all four before month-end. The detail on reading the numbers is in [LLM token cost: how to calculate it](https://atptoken.ai/blog/how-to-read-your-ai-bill).

## Setting this up in ATP Token

1. Create a Team organization with one workspace per department and one project per workload ([console setup](https://atptoken.ai/docs/console-setup)).
2. Top up through the Billing page (minimum USD 5; packages of USD 5, 50, 200 and 1,000) and allocate credits from the organization to workspaces and projects ([top up & wallet](https://atptoken.ai/docs/topup)). Top-ups are non-refundable.
3. Set each project's allowed models and create its `atp-` key, so spend by key equals spend by project.
4. Each week, compare Allocated and Consumed in the allocation tree on the Usage page ([tracking spend](https://atptoken.ai/docs/spend)).
5. At month-end, close from billing events and charge each cost center for consumed credits ([how credits work](https://atptoken.ai/docs/credits)).

[See pricing](https://atptoken.ai/pricing)

## Related reading

- [Enterprise AI cost management and LLM cost optimization guide](https://atptoken.ai/blog/enterprise-ai-cost-management-guide)
- [AI spending caps that work](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [What is the agent tax?](https://atptoken.ai/blog/what-is-the-agent-tax)

## FAQ

### What is token-based pricing?

Token-based pricing charges for the tokens a model reads (input) and writes (output), each at a rate per million tokens that differs by model. A request with 1,284 input and 412 output tokens on claude-sonnet-4-6 at $3 / $15 costs $0.010032.

### Does token-based pricing cost less than per-seat pricing?

It depends on how much each person uses. In a worked example at $0.018 per request, a user breaks even with a $25 seat at about 1,389 requests a month, roughly 66 per working day. With long documents in every prompt, break-even drops to about 17 requests per working day.

### What AI pricing models will finance teams see?

Three: per-seat subscriptions (for example Claude Team), seat plus usage (Claude Enterprise lists a seat price plus usage at API rates), and pure token-based API billing. Many companies run more than one at the same time.

### How do you charge back AI costs to departments?

Give each department's workloads their own projects, allocate credits per project, and charge each cost center for the credits it consumed, not the credits it was allocated. On ATP Token, 1 credit = USD 0.01.

### How do you budget for token-based AI usage?

For each workload, multiply requests per month by average tokens per request and the model's rates, add a buffer such as 20%, and convert to credits. Review consumed against allocated weekly and adjust next month's allocation.

---

Tags: Token based pricing, AI budgeting, ATP
