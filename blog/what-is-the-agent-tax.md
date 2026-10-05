# What is the agent tax? AI agent cost, worked out step by step (2026)

> Source: https://atptoken.ai/blog/what-is-the-agent-tax/
> Published: 2026-07-31 · By: hung-chien (AI Growth & Brand Manager)

AI agent cost grows with every step because the whole context is resent. A 20-step agent priced at list rates, and five levers that cut the agent tax.

## TL;DR

- The agent tax is the extra token cost of finishing one job in many model calls, because each call resends the growing context.
- A 20-step agent with an 8,000-token base and 2,000 tokens of growth per step reads 540,000 input tokens: about $1.77 per task on claude-sonnet-4-6 versus $0.03 for a single chat turn.
- Summarising tool output cuts that cost roughly in half, and per-project allocations cap it. Measure cost per completed task by joining your own task IDs to request IDs.

The agent tax is the extra token cost an AI agent pays because it resends its whole, growing context on every step it takes to finish one job. A single chat turn pays for the context once; a 20-step agent pays for it 20 times, each time a little larger. Below, one agent task is priced line by line at list rates, followed by the five levers that change the result most.

| Run shape | Input tokens | Output tokens | Cost on claude-sonnet-4-6 |
|---|---|---|---|
| Single chat turn | 8,000 | 500 | $0.03 |
| 20-step agent | 540,000 | 10,000 | $1.77 |
| 20-step agent, tool output summarised | 255,000 | 10,000 | $0.92 |

## How AI agent cost adds up: a 20-step example

Assume an agent that starts each task with an 8,000-token base (system prompt, tool definitions, task). Every step appends about 2,000 tokens of tool results and model output, and every step writes 500 output tokens. Step *i* therefore reads 8,000 + 2,000 × (i − 1) input tokens.

Input tokens over 20 steps:

Σ = 20 × 8,000 + 2,000 × (0 + 1 + … + 19) = 160,000 + 2,000 × 190 = **540,000 tokens**

Output tokens: 20 × 500 = 10,000.

The base is only 30% of that input (160,000 of 540,000). The other 70% is the same tool results being read again on later steps. The last 8 steps alone read 312,000 tokens, more than the first 12 combined (228,000).

Priced at ATP list rates per million tokens, as of October 2026:

| Model (input / output) | Input cost | Output cost | Per task | 10,000 tasks a month |
|---|---|---|---|---|
| [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/) ($3 / $15) | 0.54 × $3 = $1.62 | 0.01 × $15 = $0.15 | $1.77 | $17,700 |
| [gemini-3-5-flash](https://atptoken.ai/models/gemini-3-5-flash/) ($1.5 / $9) | 0.54 × $1.5 = $0.81 | 0.01 × $9 = $0.09 | $0.90 | $9,000 |
| [deepseek-v4-flash](https://atptoken.ai/models/deepseek-v4-flash/) ($0.2 / $0.4) | 0.54 × $0.2 = $0.108 | 0.01 × $0.4 = $0.004 | $0.112 | $1,120 |

The same base context answered in one turn costs 8,000 × $3/M + 500 × $15/M = $0.024 + $0.0075 = $0.0315 on claude-sonnet-4-6. The agent task costs about 56 times as much. That multiple is the agent tax: the rate card did not change, the number of tokens did.

Anthropic publishes one real-world data point: in Claude Code, agent teams use "approximately 7x more tokens than standard sessions" when teammates run in plan mode, because each teammate keeps its own context window ([Claude Code costs](https://code.claude.com/docs/en/costs)).

## Five levers that cut the agent tax

### 1. Cap steps

Input grows roughly with the square of the step count, so the late steps are the expensive ones. Set a hard maximum and return a clear failure when it is reached. If the same task fits in 12 steps, input drops to 12 × 8,000 + 2,000 × 66 = 228,000 tokens and the task costs $0.77 instead of $1.77.

### 2. Summarise tool output before it enters the context

Replace raw file contents and full API responses with a short summary or the lines that matter. If growth per step falls from 2,000 to 500 tokens, input becomes 160,000 + 500 × 190 = 255,000 tokens: $0.765 + $0.15 = $0.92 per task, 48% less.

### 3. Run sub-steps on a cheaper model

Many steps only read a tool result and decide what to call next. Keep the decisions on claude-sonnet-4-6 and route the rest to deepseek-v4-flash. With 6 decision steps and 14 sub-steps, each averaging 27,000 input tokens:

- Sonnet: 162,000 × $3/M + 3,000 × $15/M = $0.486 + $0.045 = $0.531
- Flash: 378,000 × $0.2/M + 7,000 × $0.4/M = $0.0756 + $0.0028 = $0.078
- Total: about $0.61 per task, 66% less than all-Sonnet

Test quality on your own tasks before switching; the [DeepSeek vs Claude comparison](https://atptoken.ai/compare/deepseek-vs-claude/) is a starting point.

### 4. Use prompt caching where your provider supports it

Most of an agent's input is a prefix it already sent one step earlier. On Anthropic's own API, a cache read costs 0.1× the base input rate and a 5-minute cache write costs 1.25× ([Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)). In the 20-step example, 494,000 of the 540,000 input tokens are repeats. At Anthropic's Sonnet 4.6 rates that is 494,000 × $0.30/M + 46,000 × $3.75/M + $0.15 output = $0.148 + $0.173 + $0.15, about $0.47 per task. The cache expires after its lifetime, so a step that waits on a slow tool can miss it. Check how your provider meters cached tokens before counting on this lever.

### 5. Give each agent its own budget

Put each agent in its own project and allocate credits to it. A project can only spend what it was allocated, and requests return `402` once the balance is used up, so a stuck loop stops at the ceiling instead of at month-end. At 10,000 Sonnet tasks a month, the allocation is 1,770,000 credits (1 credit = USD 0.01). Setup: [team with budget caps](https://atptoken.ai/docs/cb-budget-caps).

## How to measure cost per completed task

The gateway sees requests; only your application knows which requests belong to one task. Every ATP response carries an `x-request-id` header. Log it next to your own task or session ID, the step number, and whether the task ultimately succeeded.

Then:

1. Pull the rows for those request IDs from Request logs, which show model, status, and input/output tokens per request ([usage and logs](https://atptoken.ai/docs/monitoring)). Retention is 7 days, so export weekly with the [request logs endpoint](https://atptoken.ai/docs/console-api-logs).
2. Multiply tokens by the model's list rate and sum per task.
3. Divide total cost, including failed and abandoned tasks, by the number of completed tasks.

Failed tasks belong in the numerator. An agent that succeeds 80% of the time at $1.77 per attempt costs $1.77 / 0.8 = $2.21 per completed task.

Watch for one pattern in the logs: a `200` with empty content. On reasoning models this usually means `max_tokens` was too low for the thinking budget. ATP typically reports zero usage and deducts no credits for it, but an agent that retries without raising `max_tokens` will repeat the empty call ([errors](https://atptoken.ai/docs/errors)).

[See how pricing works](https://atptoken.ai/pricing)

## Related reading

- [Claude Code cost for teams: what a developer costs per day and 10 controls](https://atptoken.ai/blog/coding-agents-cost-control-checklist)
- [Why LLM costs explode after launch](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live)
- [How to read your AI bill](https://atptoken.ai/blog/how-to-read-your-ai-bill)

## FAQ

### How much does an AI agent cost to run?

It depends on steps and context growth more than on the per-token rate. A 20-step agent that starts at 8,000 tokens and adds 2,000 per step reads 540,000 input tokens and writes 10,000 output tokens, which is about $1.77 per task at $3/$15 per million tokens.

### Why do AI agents cost more than chat completions?

A chat completion sends the context once. An agent sends it again on every step, with each tool result appended, so input tokens grow roughly with the square of the step count.

### How do I calculate AI agent cost per task?

Sum input tokens across steps as base × steps + growth × (0 + 1 + … + steps − 1), add output tokens, and multiply each by the model's rate. To measure it in production, log your own task ID with every request ID and divide total cost by completed tasks.

### How can I reduce AI agent token costs?

Cap the number of steps, summarise tool output before it enters the context, run sub-steps on a cheaper model, use prompt caching where your provider bills cache reads at a lower rate, and give each agent project its own credit allocation.

---

Tags: Agent tax, AI agent cost, ATP
