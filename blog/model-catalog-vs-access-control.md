# Model catalog vs access control: GET /v1/models lists the menu, the project allowlist decides (2026)

> Source: https://atptoken.ai/blog/model-catalog-vs-access-control/
> Published: 2026-08-28 · By: hung-chien (AI Growth & Brand Manager)

GET /v1/models lists what an LLM platform offers; a model allowlist decides what a key may call. Request and response examples, the 403, and allowlist design.

## TL;DR

- On ATP Token, GET /v1/models returns the platform catalog. The project's allowed-model list decides what a key may call, and a model outside it gets 403 before any provider is contacted.
- OpenAI does the same job with a per-project Model usage setting; OpenRouter does it with a model allowlist inside a guardrail.
- Design allowlists per workload with named models and their list rates, for example a support bot limited to claude-haiku-4-5 and gemini-3-5-flash.

A model catalog is the list of model ids a platform can serve, and model access control is the rule that decides which of those ids a given key may call. On ATP Token, `GET /v1/models` returns the catalog, and the project's allowed-model list is checked on every request, with a 403 before any provider is contacted. This post shows the request and response, explains what the 403 means, compares OpenAI and OpenRouter, and gives four allowlists with their list rates.

## Two different questions

| Question | Where ATP Token answers it | When the answer is no |
|---|---|---|
| Is this key valid? | Authentication | 401 |
| Does this model exist on the platform? | [GET /v1/models](https://atptoken.ai/docs/models) | The id is missing from the list |
| May this key's project call it? | The project's allowed models | 403, before any provider |
| Can the project pay for it? | The project's credit balance | 402 |

The order matters. The gateway authenticates the key, checks the model against the project's allowed list, routes to a provider, then meters tokens against the project balance ([how it works](https://atptoken.ai/docs/how-it-works)). A model can pass the second row and still fail the third.

## What GET /v1/models returns

The request uses your project key and the OpenAI-format base URL:

```
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer atp-..."
```

The response is an OpenAI-style list. Each `id` is the exact string to put in the `model` field of a request:

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

The [model discovery docs](https://atptoken.ai/docs/models) state that this list is not scoped to your project. Use it to get current ids instead of copying names from a provider dashboard or a blog post. Do not read it as a list of permissions.

## What a 403 means

A 403 from ATP Token means the key is valid and the model id is real, but the model is not enabled for the key's project. The [common responses](https://atptoken.ai/docs/errors) page describes it in one line: the model is not enabled for this project. The request stops at the authorization step and never reaches a provider. Like every ATP error, the response carries a `request_id` and uses the error format of the SDK you called.

A typical case: a developer sees `claude-opus-4-8` in the catalog and switches the support bot to it in a feature branch. The support bot's project allows only claude-haiku-4-5 and gemini-3-5-flash, so staging returns 403 on the first request. That is the allowlist doing its job. At ATP list rates, a 2,000-token prompt with a 300-token reply costs 1.75 credits on [claude-opus-4-8](https://atptoken.ai/models/claude-opus-4-8/) (USD 5 input and USD 25 output per million tokens) against 0.35 credits on [claude-haiku-4-5](https://atptoken.ai/models/claude-haiku-4-5/) (USD 1 and USD 5), five times more per reply.

Two client rules follow. Do not retry a 403, because it will fail the same way every time. Log it with the request ID and route it to the project owner, who either changes the model in code or asks an Admin to widen the list.

## How OpenAI and OpenRouter do the same job

| Platform | Where the model rule lives | Granularity |
|---|---|---|
| OpenAI API | Project settings, Limits, Model usage ([Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)) | Per project |
| OpenRouter | Model allowlist inside a guardrail ([guardrails](https://openrouter.ai/docs/guides/features/guardrails)) | Per member or per API key; when several guardrails apply, only models allowed by all of them are available |
| ATP Token | Allowed models on the project ([workspaces and projects](https://atptoken.ai/docs/resources)) | Per project, never per key; at least one model per project |

In OpenAI's model, the Model usage setting sits next to the project's monthly spend limit and notification threshold. In OpenRouter's, the same guardrail can also hold a spending cap and a provider allowlist, and the strictest applicable rule wins. On ATP Token, the allowed list sits next to the project's credit allocation, and every key in the project inherits both.

## Designing allowlists: four project templates

| Project | Allowed models | ATP list rate per 1M tokens (input / output) | Allocation guidance |
|---|---|---|---|
| support-bot-prod | [claude-haiku-4-5](https://atptoken.ai/models/claude-haiku-4-5/), [gemini-3-5-flash](https://atptoken.ai/models/gemini-3-5-flash/) | USD 1 / 5; USD 1.5 / 9 | Sized from reply volume |
| coding-agent | [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/), [gpt-5.4](https://atptoken.ai/models/gpt-5.4/) | USD 3 / 15; USD 2.5 / 15 | Per team, reviewed weekly |
| batch-classification | [deepseek-v4-flash](https://atptoken.ai/models/deepseek-v4-flash/), qwen-3-7-flash | USD 0.2 / 0.4; USD 0.03 / 0.13 (prompts up to 32K) | Sized per job |
| research-sandbox | claude-opus-4-8, [gpt-5.5](https://atptoken.ai/models/gpt-5.5/) | USD 5 / 25; USD 5 / 30 | Small, fixed |

1. **Start with the cheapest model that passes your evaluation**, then add one alternative from a second vendor. The gateway already fails over between providers for the same model id ([provider routing](https://atptoken.ai/docs/provider-routing)); the second model is for when you want to switch models in code. For the Gemini or GPT choice, see [Gemini vs GPT](https://atptoken.ai/compare/gemini-vs-gpt/).
2. Give frontier models their own project with a small allocation. Research gets Opus and GPT-5.5 without the support bot being one config change away from them.
3. Treat widening a list as a change request. Managing resources is an Admin permission, and the Activity log records resource updates ([usage and logs](https://atptoken.ai/docs/monitoring)).
4. Pair every allowlist with a budget. An allowed model with an unlimited balance is still a surprise bill ([AI API spending limits compared](https://atptoken.ai/blog/ai-spending-caps-that-work)).

## Setting this up in ATP Token

1. On the Resources page, create the project and choose its allowed models ([workspaces and projects](https://atptoken.ai/docs/resources)).
2. Allocate credits to the project, then issue a key from it ([managing API keys](https://atptoken.ai/docs/console-keys)).
3. Call `GET /v1/models` to copy exact ids into your configuration.
4. Send one test request per configured model from staging. A 200 confirms access; a 403 means the model is missing from the project's list.
5. In request logs, filter by status to find any 403s after a deploy.

[Quickstart: list models and send a first request](https://atptoken.ai/docs/quickstart)

## Related reading

- [One project, one key](https://atptoken.ai/blog/one-project-one-key)
- [AI API spending limits compared](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [LLM gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026)

## FAQ

### Does GET /v1/models show only the models my key can use?

On ATP Token, no. GET /v1/models lists every model available on the platform and is not scoped to your project. Which models a key may call is set by the project's allowed list and checked on every request.

### Why does my API return 403 for a model that appears in /v1/models?

The model exists on the platform but is not enabled for your key's project. ATP Token checks the project's allowed list after authenticating the key and rejects the request with 403 before contacting a provider. Use an allowed model, or ask a project Admin to add it.

### What is a model allowlist?

A model allowlist is the list of model ids a project, key or member is permitted to call. Requests for any other model are rejected by the platform, whatever the application code asks for.

### Can I restrict which models an OpenAI project can use?

Yes. In the OpenAI API platform, a project's Limits settings include Model usage, where you choose which models the project can use, next to the monthly spend limit and notification threshold.

### Is model access set per key or per project on ATP Token?

Per project. Every key in a project inherits the same allowed models, and each project must allow at least one model.

---

Tags: Model allowlist, LLM access control, AI gateway, ATP
