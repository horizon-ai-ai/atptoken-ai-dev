# LLM token cost: how to calculate it and read your AI bill, with 5-model examples (2026)

> Source: https://atptoken.ai/blog/how-to-read-your-ai-bill/
> Published: 2026-07-21 · By: hung-chien (AI Growth & Brand Manager)

LLM token cost explained: the per-request formula, one request priced on 5 models, input vs output ratios, cached and reasoning tokens, and how to read a bill.

## TL;DR

- LLM token cost per request = input tokens × input rate + output tokens × output rate, with rates quoted per 1M tokens. On claude-sonnet-4-6 ($3 / $15), 1,284 input and 412 output tokens cost $0.010032, or 1.0032 ATP credits.
- The same request costs $0.01878 on gpt-5.5 and $0.00009208 on qwen-3-7-flash, a 204× spread. Model choice moves the bill more than any other single setting.
- Output tokens are priced 2× to 6× input on common models, and reasoning tokens bill as output. Read the bill by project and model first, then drill into single requests while the 7-day request logs still hold them.

LLM token cost is what you pay a model for the tokens it reads (input) and writes (output), each charged at its own rate per million tokens. This guide gives you the formula, prices one real-sized request on five models, explains why output, cached and reasoning tokens change the math, and shows which fields to read when the monthly AI bill does not add up.

All rates below are ATP list rates from each model page, as of October 2026. The vendor rates quoted for comparison link to the vendor's own pricing page.

## The token cost formula

Every per-request cost on a token-priced API comes from the same three steps:

1. Input cost = input tokens × input rate ÷ 1,000,000
2. Output cost = output tokens × output rate ÷ 1,000,000
3. Request cost = input cost + output cost

On ATP Token, the request is then charged in credits against the project's balance, at [1 credit = USD 0.01](https://atptoken.ai/docs/credits). Credits = USD cost × 100.

### Worked example: one support-bot reply

A support bot sends a 1,284-token prompt (system prompt, retrieved help-center snippet, customer message) to claude-sonnet-4-6 at $3 input / $15 output per 1M tokens, and gets a 412-token answer.

- Input: 1,284 × $3 ÷ 1,000,000 = $0.003852
- Output: 412 × $15 ÷ 1,000,000 = $0.00618
- Total: $0.010032 = 1.0032 credits

At 100,000 replies a month that is $1,003.20. Output is only 24% of the tokens in this request but 61.6% of its cost.

### A token cost calculator you can paste

The SDK response already carries the token counts. With the OpenAI format the fields are `usage.prompt_tokens` and `usage.completion_tokens`; with the Anthropic format they are `usage.input_tokens` and `usage.output_tokens`.

```python
RATES = {  # USD per 1M tokens: (input, output), ATP list rates
    "gpt-5.5": (5.00, 30.00),
    "claude-sonnet-4-6": (3.00, 15.00),
    "gemini-3-5-flash": (1.50, 9.00),
    "deepseek-v4-flash": (0.20, 0.40),
    "qwen-3-7-flash": (0.03, 0.13),
}

def token_cost(model, input_tokens, output_tokens):
    rate_in, rate_out = RATES[model]
    usd = (input_tokens * rate_in + output_tokens * rate_out) / 1_000_000
    return usd, usd * 100  # (USD, ATP credits)

print(token_cost("claude-sonnet-4-6", 1284, 412))  # about (0.010032, 1.0032)
```

## The same request on 5 models

Here is the 1,284-in / 412-out request priced on five models. The qwen-3-7-flash rate is its tier for prompts up to 32K tokens.

| Model | ATP list rate (input / output per 1M) | Cost per request | Credits per request | Per 100k requests |
|---|---|---|---|---|
| [gpt-5.5](https://atptoken.ai/models/gpt-5.5/) | $5 / $30 | $0.01878 | 1.878 | $1,878.00 |
| [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/) | $3 / $15 | $0.010032 | 1.0032 | $1,003.20 |
| [gemini-3-5-flash](https://atptoken.ai/models/gemini-3-5-flash/) | $1.50 / $9 | $0.005634 | 0.5634 | $563.40 |
| [deepseek-v4-flash](https://atptoken.ai/models/deepseek-v4-flash/) | $0.20 / $0.40 | $0.0004216 | 0.04216 | $42.16 |
| [qwen-3-7-flash](https://atptoken.ai/models/qwen-3-7-flash/) | $0.03 / $0.13 | $0.00009208 | 0.009208 | $9.21 |

The table holds token counts constant to isolate the rate. Real counts differ by model, because each vendor's tokenizer splits text differently. Anthropic says the tokenizer in Claude 4.7 and later models "produces approximately 30% more tokens for the same text" ([Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)), so the same 1,284-token prompt would come out near 1,670 tokens on a 4.7+ model. Test your own prompts before comparing models on rate alone, and check quality side by side, for example in the [DeepSeek vs Claude comparison](https://atptoken.ai/compare/deepseek-vs-claude/).

## Why output tokens dominate the bill

The ratio between output and input rates decides where your money goes.

| Model | Output rate ÷ input rate | Output share of the example request's cost |
|---|---|---|
| gpt-5.5 | 6× | 65.8% |
| claude-sonnet-4-6 | 5× | 61.6% |
| deepseek-v4-flash | 2× | 39.1% |

Two practical consequences. On a 5× or 6× model, trimming the answer is worth more per token than trimming the prompt: cutting 200 output tokens on claude-sonnet-4-6 saves $0.003, the same as cutting 1,000 input tokens. And workloads that generate long text (drafting, code generation, report writing) should be priced mainly from their expected output length.

## Cached input and reasoning tokens

Two token types appear on vendor price sheets and confuse first-time readers.

### Cached input is a vendor pricing feature

Some vendors price repeated prompt prefixes lower when they are served from cache. OpenAI lists GPT-5.5 cached input at $0.50 per 1M tokens against $5 for regular input ([OpenAI pricing](https://developers.openai.com/api/docs/pricing)). Anthropic prices cache reads at 0.1× the base input rate on most models, with cache writes at 1.25× (5-minute) or 2× (1-hour) ([Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)). These are vendor rates for calls made under those vendors' caching rules. ATP Token bills on input and output tokens per its [pricing model](https://atptoken.ai/docs/pricing-model), so plan ATP budgets on the input and output list rates.

### Reasoning tokens bill as output

Reasoning models think before they answer, and those hidden tokens count. OpenAI states reasoning tokens "are billed as output tokens" ([OpenAI reasoning guide](https://developers.openai.com/api/docs/guides/reasoning)), and Anthropic bills extended-thinking tokens as output ([Claude Code costs](https://code.claude.com/docs/en/costs)). If the support-bot request above used 1,500 thinking tokens on claude-sonnet-4-6, it would add 1,500 × $15 ÷ 1,000,000 = $0.0225, taking the request from $0.010032 to $0.032532, about 3.2×.

Reasoning budgets also explain a puzzling log line: a `200` with empty content. When `max_tokens` is too low, the model spends the whole budget thinking and returns no text. On ATP that request typically shows zero usage and deducts no credits; the fix is a higher `max_tokens` ([errors](https://atptoken.ai/docs/errors)).

## What a per-request record tells you

A monthly total says how much. A per-request record says which project, which model and how many tokens. The record below is illustrative; it shows the fields you need to price one call, not ATP's literal log format.

```json
{
  "request_id": "req_example_01",
  "project": "support-bot-prod",
  "model": "claude-sonnet-4-6",
  "input_tokens": 1284,
  "output_tokens": 412,
  "cost_usd": 0.010032,
  "cost_credits": 1.0032
}
```

In ATP Token the same information lives in three places:

- Request logs, one row per call: time, scope (workspace and project), model, endpoint, HTTP status, provider result, input and output tokens, billing status and request ID. Filter by time range, scope, model, status or request ID ([Usage & logs](https://atptoken.ai/docs/monitoring)). Retention is 7 days, so investigate a spike within the week.
- Billing events, the line-item ledger shown in the console as a 90-day view, filterable by model, key, billing status or request ID ([billing API](https://atptoken.ai/docs/console-api-billing)). Use this ledger as the billing source of truth.
- The Usage page, which totals credits and tokens by model and by API key for a period.

Every response also carries an `x-request-id` header, so an engineer can match one call in application logs to its row in the console.

## Three bill anomalies and where to look

### Spend jumps in one week

Sort Usage by API key. If keys map one-to-one to projects, the jump lands on one owner immediately. Then filter request logs on that project and compare tokens per request before and after the jump. A rise from about 1,300 to 13,000 input tokens per call usually means someone started sending a whole document on every turn.

### The rate looks right but the total does not

Check the model mix. Moving 20% of the 100,000 support replies from claude-sonnet-4-6 to gpt-5.5 raises that month from $1,003.20 to $1,178.16, with no change in traffic.

### Requests succeed with no text

Look for `200` rows with zero output tokens on a reasoning model. Raise `max_tokens` to cover thinking plus the answer.

## Setting this up in ATP Token

1. Create one project per service and environment, each with its own `atp-` key, so Usage by key reads as usage by owner.
2. Allocate credits to each project. The allocation is the project's ceiling; when its balance runs out, calls return `402` ([budget caps recipe](https://atptoken.ai/docs/cb-budget-caps)). Projects can also turn on auto top-up with a trigger threshold and a monthly cap.
3. Log `usage` from every response with the model id, and run the calculator above per project each week.
4. Reconcile month-end against billing events, and use request logs for drill-downs inside the 7-day window.

[Start with the quickstart](https://atptoken.ai/docs/quickstart)

## Related reading

- [Enterprise AI cost management and LLM cost optimization guide](https://atptoken.ai/blog/enterprise-ai-cost-management-guide)
- [Why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live)
- [What is the agent tax?](https://atptoken.ai/blog/what-is-the-agent-tax)

## FAQ

### How do you calculate LLM token cost?

Multiply input tokens by the model's input rate and output tokens by its output rate, then divide each by 1,000,000 because rates are quoted per million tokens. Add the two. For example, 1,284 input and 412 output tokens on claude-sonnet-4-6 at $3 / $15 cost $0.003852 + $0.00618 = $0.010032.

### Why are output tokens more expensive than input tokens?

Vendors price generation higher than reading. On ATP list rates, output costs 6× input on gpt-5.5, 5× on claude-sonnet-4-6 and 2× on deepseek-v4-flash, so a request with a short prompt and a long answer is mostly output cost.

### Are reasoning tokens billed?

Yes. OpenAI and Anthropic both bill reasoning (thinking) tokens as output tokens even though you do not see them in the answer. A request with 1,500 thinking tokens on claude-sonnet-4-6 adds $0.0225 to its cost.

### How many credits does a request use on ATP Token?

1 credit = USD 0.01, so credits = USD cost × 100. A $0.010032 request uses 1.0032 credits. Balances are shown to four decimal places.

### How long are ATP request logs kept?

Request logs are kept for 7 days and are a debugging view. Billing events are the billing source of truth and appear in the console as a 90-day ledger.

---

Tags: LLM token cost, AI billing, ATP
