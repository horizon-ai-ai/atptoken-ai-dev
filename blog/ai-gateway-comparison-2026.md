# LLM gateway comparison 2026: OpenRouter, Vercel AI Gateway, LiteLLM, Portkey, Helicone and ATP Token

> Source: https://atptoken.ai/blog/ai-gateway-comparison-2026/
> Published: 2026-08-21 · By: hung-chien (AI Growth & Brand Manager)

What an LLM gateway does, and how six gateways compare on hosting, pricing model, spend limits, model allowlists and API formats as of October 2026.

## TL;DR

- An LLM gateway gives your applications one API for many models and handles keys, provider routing and failover, request logs and spend limits.
- By 2026 most gateways have budgets and logs. The useful differences are where the gateway runs, how you pay, what a budget is attached to, and whether it is a hard or soft limit.
- Pick by constraint: self-hosting (LiteLLM, Portkey or Helicone open source), largest catalog (OpenRouter), Vercel-native (Vercel AI Gateway), prepaid per-project budgets with per-project model allowlists (ATP Token).

An LLM gateway is a service that sits between your application and model providers, giving your code one API for many models while it handles keys, routing and failover, request logs and spend limits. This comparison covers six gateways teams shortlist in 2026, using the same checklist for each, with every pricing and feature claim linked to the vendor's own documentation as of October 2026.

## What an LLM gateway does

Five jobs, in the order a request meets them:

1. One API for many models. Your code calls one base URL in a familiar format (usually OpenAI's) and switches models by changing the `model` field.
2. Authentication and keys. The gateway issues its own keys and keeps provider credentials out of your apps.
3. Access rules. It decides whether this key may call this model.
4. Routing and failover. It picks a provider for the model and retries elsewhere if one fails.
5. Metering, logs and limits. It records tokens and cost per request and stops traffic when a budget is reached.

On ATP Token those stages map to status codes you can test: 401 for a bad key, 403 when the model isn't allowed for the project, 502 or 503 when providers fail, and 402 when the project's credits run out ([how it works](https://atptoken.ai/docs/how-it-works), [errors](https://atptoken.ai/docs/errors)).

## The six gateways at a glance

| | Runs where | You pay | Budgets attach to | At the limit | Model allowlist | API formats |
|---|---|---|---|---|---|---|
| [OpenRouter](https://openrouter.ai/pricing) | Hosted | Provider prices + 5.5% card fee on credit purchases (Standard) | API key, member; workspace on Enterprise | Rejected | Guardrails per member or key | OpenAI-compatible, Anthropic Messages |
| [Vercel AI Gateway](https://vercel.com/docs/ai-gateway/pricing) | Hosted | Provider list price, no token markup; payment fees may apply | Team, project, key, member | 402, soft cap | Provider allowlist (paid add-on) | AI SDK, OpenAI Chat and Responses, Anthropic Messages |
| [LiteLLM](https://docs.litellm.ai/docs/proxy/users) | Self-hosted (open source) | Your provider bills + hosting; Enterprise license optional | Key, user, team, customer | Rejected | Access groups per key or team | OpenAI-compatible |
| [Portkey](https://portkey.ai/pricing) | Hosted; open-source or VPC options | Free tier, $49/month Production, custom Enterprise | Provider or virtual key (Enterprise, select Pro) | Key expires at the limit | Not compared here | OpenAI-compatible |
| [Helicone](https://docs.helicone.ai/gateway/overview) | Open source (Apache) or hosted | See vendor | Not compared here | — | Not compared here | OpenAI-compatible |
| [ATP Token](https://atptoken.ai/docs/how-it-works) | Hosted | Prepaid credits at each model's list rate; from USD 5 | Project, funded from workspace and organization | 402 when the balance is used up | Per project, checked before any provider (403) | OpenAI, Anthropic, Gemini |

"Not compared here" means we did not find the detail in the vendor's public docs; check with the vendor before you rely on it.

## How to choose: six questions

### 1. Where must the gateway run?

If traffic cannot pass through a third party, the shortlist is self-hosted: the LiteLLM proxy, Helicone's open-source gateway, or Portkey's open-source and VPC options. Everything else on this page is hosted.

### 2. How do you want to pay?

Three models exist:

- Provider price plus a fee on top-ups. OpenRouter: 5.5% on card purchases on Standard ($0.80 minimum), 8% on Business ([FAQ](https://openrouter.ai/docs/faq)).
- Provider list price, no token markup. Vercel AI Gateway; payment processing fees may apply ([pricing](https://vercel.com/docs/ai-gateway/pricing)).
- Prepaid credits at per-model list rates. ATP Token: 1 credit = USD 0.01, pay-as-you-go credits don't expire, top-ups from USD 5 ([credits](https://atptoken.ai/docs/credits)). Rates per model are on the [pricing page](https://atptoken.ai/pricing).

Self-hosted gateways add no fee, but your provider bills and engineering time are the cost.

### 3. What is a budget attached to, and is it hard?

This is where gateways differ most.

- OpenRouter: budgets in guardrails per member or key, resetting daily, weekly or monthly; workspace budgets on Enterprise ([guardrails](https://openrouter.ai/docs/guides/features/guardrails)).
- Vercel: team, project, key and member budgets. Vercel calls them a soft cap: the request that crosses the limit still completes, then requests get 402 ([budgets](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)).
- LiteLLM: budgets per key, user, team or customer with reset durations like `30d`.
- ATP Token: credits are allocated down organization → workspace → project, and a project can only spend its allocation. There is no reset period; the project runs until its balance is used, then gets 402 until someone allocates more ([budget caps recipe](https://atptoken.ai/docs/cb-budget-caps)).

A reset-period budget suits "no more than $500 a month on this key". A prepaid allocation suits "this product line has $5,000 for the quarter".

### 4. Which SDK formats do your apps already use?

Most gateways speak the OpenAI format. If some services use the Anthropic SDK (Claude Code does) or the Google GenAI SDK, check native support: OpenRouter and Vercel document Anthropic Messages; ATP Token accepts the OpenAI, Anthropic and Google GenAI SDKs unchanged ([OpenAI SDK](https://atptoken.ai/docs/sdk-openai), [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic), [Google GenAI SDK](https://atptoken.ai/docs/sdk-google)).

### 5. Which models and modalities?

OpenRouter lists 500+ models from 80+ providers. ATP Token has 70+ models from 11 vendors, including video models such as [Seedance 2.0](https://atptoken.ai/models/seedance-2-0/) and [Kling v3 Pro](https://atptoken.ai/models/kling-v3-pro/) and image models such as [Nano Banana Pro](https://atptoken.ai/models/nano-banana-pro/) ([media models](https://atptoken.ai/docs/media)). If you only need a handful of frontier LLMs, catalog size matters less than the other questions.

### 6. What does the log keep, and for how long?

Portkey publishes retention per plan: 3 days of logs on the free tier, 30 days on Production. ATP Token keeps request logs for 7 days as a debugging view, with billing events as the billing record ([request logs API](https://atptoken.ai/docs/console-api-logs)). If you review spend monthly, export or summarise weekly.

## Each gateway in more detail

### OpenRouter

- Fits: the widest hosted catalog and fast model evaluation.
- Controls: organizations, workspaces, guardrails with budgets, model and provider allowlists, ZDR rules; per-key credit limits on all plans.
- Watch out for: the fee on credit purchases, possible credit expiry after one year, invoicing only on Enterprise. Full breakdown in [OpenRouter alternatives for teams](https://atptoken.ai/blog/openrouter-vs-enterprise-governance).

### Vercel AI Gateway

- Fits: teams on Vercel, or anyone wanting a hosted gateway priced at provider list price.
- Controls: four budget scopes, spend alerts at 50/75/100%, request logs, provider and model fallbacks.
- Watch out for: soft-cap budgets; spend on your own provider keys isn't counted against budgets; some controls are paid add-ons.

### LiteLLM

- Fits: platform teams who want full control and already run infrastructure.
- Controls: virtual keys, budgets at several levels, access groups for models.
- Watch out for: you operate it. Per-model budgets at user and key level need an Enterprise license.

### Portkey

- Fits: teams that want a gateway with observability and guardrails in one product.
- Controls: budget limits on providers or virtual keys with alert thresholds and weekly or monthly reset, on Enterprise and select Pro plans ([budget limits](https://portkey.ai/docs/product/ai-gateway/virtual-keys/budget-limits)). RBAC from the $49 Production plan.
- Watch out for: log quotas per plan (10k logs a month free, 100k on Production).

### Helicone

- Fits: observability-first teams; the gateway is open source and written in Rust.
- Controls: request logging with tokens and cost, routing, fallbacks, caching across 100+ models.
- Watch out for: check budget and access-control features against your requirements; we did not find them in the gateway overview.

### ATP Token

- Fits: companies where several teams share one AI budget and each project should have a funded allocation and a reviewed model list.
- Controls: organization → workspace → project hierarchy, project-scoped keys, per-project allowed models, credit allocation as the ceiling, per-request logs, owner/admin/member roles ([team and roles](https://atptoken.ai/docs/team)).
- Watch out for: a smaller catalog than OpenRouter; credits are non-refundable; request logs are kept 7 days.

## Running two gateways

Many teams end up with two: a large-catalog gateway for research and evaluation, and a governed one for production. The rule that keeps this sane is that production keys never live in the research account, and each production service has its own key and budget. See [one project, one key](https://atptoken.ai/blog/one-project-one-key).

## Trying the comparison on ATP Token

1. Create a project and enable two or three models you want to compare, for example [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/), [gemini-3-5-flash](https://atptoken.ai/models/gemini-3-5-flash/) and [deepseek-v4-flash](https://atptoken.ai/models/deepseek-v4-flash/).
2. Allocate a small amount of credits, say 500 (USD 5), as the ceiling for the test.
3. Point your existing OpenAI, Anthropic or Google GenAI client at the gateway and run the same prompts against each model.
4. Compare tokens and credits per request in Request logs ([usage and logs](https://atptoken.ai/docs/monitoring)). Side-by-side model pages are at [/compare](https://atptoken.ai/compare/gemini-vs-gpt/).

[Start with the quickstart](https://atptoken.ai/docs/quickstart)

## Related reading

- [OpenRouter alternatives for teams](https://atptoken.ai/blog/openrouter-vs-enterprise-governance)
- [OpenAI API vs an OpenAI-compatible gateway](https://atptoken.ai/blog/openai-api-vs-enterprise-ai-gateway)
- [AI API spending limits compared](https://atptoken.ai/blog/ai-spending-caps-that-work)

## FAQ

### What is an LLM gateway?

An LLM gateway is a service between your application and model providers that exposes one API for many models. Depending on the product it also handles authentication, provider routing and failover, request logging, spend limits and model access rules.

### What is the best LLM gateway?

There is no single best one; it depends on your constraint. LiteLLM suits teams that must self-host, OpenRouter offers the largest hosted catalog, Vercel AI Gateway suits apps on Vercel, and ATP Token suits companies that want prepaid budgets and model allowlists per project.

### Is an LLM gateway the same as an LLM proxy?

Mostly. A proxy forwards requests to providers with a stable API; gateway is the broader term for a proxy that also enforces keys, budgets, model access and logging.

### Is LiteLLM free?

The LiteLLM proxy is open source and free to self-host; you pay your providers and your hosting costs. Some features, such as per-model budgets at the user and key level, require an Enterprise license.

### Do I still need provider accounts if I use a gateway?

With a self-hosted gateway, yes, because it calls providers with your keys. Hosted gateways such as OpenRouter, Vercel AI Gateway and ATP Token can bill model usage themselves, and some also accept your own provider keys.

---

Tags: LLM gateway, AI gateway, ATP
