# How to read your AI bill: a 3-layer guide to tokens, credits, and per-request attribution (2026)

> Source: https://atptoken.ai/blog/how-to-read-your-ai-bill/
> Published: 2026-07-21 · By: hung-chien (AI Growth & Brand Manager)

AI cost management guide: how to read an AI bill in three layers — token pricing, credits, and per-request records that tie every dollar to a project.

## TL;DR

- An AI bill has exactly three layers: tokens are the pricing unit, credits are the settlement unit, per-request records are the audit unit. When all three line up, the bill reads itself.
- The most useful internal metric is not the price sheet but average cost per thousand requests — it captures model choice, prompt length, and caching strategy in one number.
- Attribution quality is set by the key: one project, one key gives every request an owner; several systems sharing one key means the bill can only ever say 'everyone.'

An AI bill is the usage statement a company receives for large language model and other AI services: models price in tokens, billing settles in credits or cash, and every line of spend should trace back to a project. This guide is for the engineers, finance partners, and managers accountable for that number for the first time.

The answer up front: an AI bill has exactly three layers — tokens are the pricing unit, credits are the settlement unit, and per-request records are the audit unit. When a bill feels unreadable, one layer is missing: only a monthly total (no third layer), inconsistent units across vendors (no second layer), or no idea whether the money went to input or output (no first layer). The rest of this guide takes the layers one at a time, then maps them to roles and to the three most common anomalies.

## Layer one: the token is the unit of pricing

Think of a token as a fragment of a word. Three pricing facts at this layer determine the shape of your bill.

### Input and output are priced separately — output costs several times more

For the same request, longer answers cost more. Constraining output length (for example, fixing a response format) is the most direct cost lever you have.

### Longer context costs more — every pasted paragraph is metered

Every document and every turn of chat history you put in the prompt counts as input tokens. Unusually heavy input almost always means the context is carrying content it doesn't need.

### Cache hits bill at a different rate — repeated prefixes cost a fraction

System prompts and document prefixes that repeat can be far cheaper on a cache hit than as fresh input. Vendor rate pages list all three facts as tables — see [OpenAI's pricing page](https://openai.com/api/pricing/) for one example — and the same sentence can differ in cost by an order of magnitude across models; compare pricing modes in the [model catalog](https://atptoken.ai/docs/models).

So rather than staring at price sheets, track **average cost per thousand requests**: one number that reflects model choice, prompt length, and caching strategy together. For multi-step agents, pair it with cost per completed task — see [what is the agent tax](https://atptoken.ai/blog/what-is-the-agent-tax).

## Layer two: credits turn many rate cards into one unit

Run several model vendors at once and finance receives invoices written in several languages: different currencies, rate tables, and metering rules. This is what a credit system is for: top up once, let each model draw down at its own rate, and every model's consumption lands in the same unit.

### Why you need a single settlement unit

Credits are not a pricing trick — they are a translation layer that turns each vendor's billing logic into something finance can reconcile, so budgets, month-end closes, and trend lines share one baseline. Mechanics are in the [credits docs](https://atptoken.ai/docs/credits).

### Low-balance alerts keep workloads from stopping mid-run

With balance alerts and auto top-up, "ran out of credits halfway" becomes a notification instead of an incident.

[See pricing →](https://atptoken.ai/pricing)

## Layer three: per-request attribution is the smallest auditable unit

> A bill you can actually read has "one request" as its smallest unit — not "one month."

### What a per-request record looks like

A monthly total says how much; it cannot say who or why. A per-request record writes down the project, key, model, and token counts of every call:

```
{
  "request_id": "req_01HZXK3T9",
  "project": "support-bot",
  "model": "claude-sonnet-5",
  "input_tokens": 1284,
  "output_tokens": 412,
  "cost_credits": 0.0087
}
```

### The key determines attribution quality

If several applications share one key, the record above can tell you the model and the cost, but never the team. Project keys and per-request attribution are really one feature: the key stamps each request with an owner, and the log makes the stamp auditable later. This is why [the enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist) puts "one project, one key" at number 1. Fields and reports are covered in the [spend docs](https://atptoken.ai/docs/spend).

## By role: what engineering, finance, and management each read

### Engineering reads layer one: token structure

Input-to-output ratio, cache hit rate, model mix — three numbers that decide whether unit cost can drop further.

### Finance reads layer two: credits and top-up cadence

One unit, one bill, a predictable top-up cycle; anomalies get escalated to layer three.

### Management reads layer three, rolled up: trends by project

Month-over-month spend summed by project is the only defensible basis for renewing next year's AI budget.

## By scenario: three common billing anomalies

### Spend jumps suddenly — sort by project, then drill into models

Nine times out of ten the jump concentrates in a single project — the same pattern as [why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live); per-request records narrow it to one model, and often one deployment window, in minutes.

### Input tokens balloon — inspect the context assembly logic

The usual culprit is "paste the whole document into every turn"; the usual fix is summarization or retrieval.

### A balance runs dry mid-run — set alert thresholds and auto top-up

Make "credits remaining" a number on a dashboard you glance at daily, not the first line of an incident report.

## The more modern approach: make attribution the default with ATP Token

You can build each of the three layers yourself; the more modern approach is a platform where they are simply the defaults. Project keys set ownership, every request writes its own record, and all models settle in credits — engineering keeps its existing call patterns (compatible with the OpenAI, Anthropic, and Gemini formats; integration is a base_url swap), and finance reads one bill a month.

[Start with the quickstart →](https://atptoken.ai/docs/quickstart)

## Further reading

- [Enterprise AI cost management: the complete guide to tokens, credits, keys, and caps](https://atptoken.ai/blog/enterprise-ai-cost-management-guide)
- [Why AI bills explode after go-live: 5 control gaps and how to close them](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live)
- [What is the agent tax? Why multi-step AI agents inflate token bills](https://atptoken.ai/blog/what-is-the-agent-tax)

A bill should be a dashboard you glance at daily, not a month-end surprise. Once the three layers line up, "how much is AI costing us" stops being a puzzle and becomes a query.

[Apply for the enterprise plan →](https://atptoken.ai/enterprise-plan)

## FAQ

### What is a token in AI services?

A token is the smallest unit a large language model uses to price and process text — roughly a fragment of a word. Input and output tokens are priced separately, and output usually costs several times more than input.

### What is the difference between credits and tokens?

Tokens are the model's pricing unit; credits are the billing settlement unit. Each model converts its token consumption into credits at its own rate, so usage across different models lands in one unit that finance can reconcile.

### How do I attribute AI costs to a department or project?

First enforce one key per project, then keep per-request records. Each request logs its project, model, and token counts, and summing them gives each department's true spend; a shared key makes this impossible.

### Why does my AI bill swing so much month to month?

The usual causes, in order: context length changed (someone started pasting whole documents into prompts), a switch to a differently priced model, a drop in cache hit rate, and plain traffic change. With per-request records, all four can be confirmed or ruled out in minutes.

---

Tags: AI billing, AI cost management, ATP
