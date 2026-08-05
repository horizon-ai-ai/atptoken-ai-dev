# Model catalog vs access control: why GET /v1/models is not your key’s permission (2026)

> Source: https://atptoken.ai/blog/model-catalog-vs-access-control/
> Published: 2026-08-28 · By: hung-chien (AI Growth & Brand Manager)

A model catalog lists what a platform offers. Access control decides what a project key may call. Confusing the two causes 403s, shadow spend, and false security.

## TL;DR

- The model catalog is the menu; the project allowlist is the permission slip. GET /v1/models answers availability, not authorization.
- Enforce allowlists before traffic reaches a provider so policy is not a code-review hope.
- Pair allowlists with budgets—authorized and unlimited is still a bill event.

A model catalog is the list of model ids a platform can serve; model access control is the policy that decides which of those ids a given project key may call. This guide is for engineers who treat “it appears in `/v1/models`” as “we are allowed to use it.”

**Menu ≠ permission.** On ATP, list endpoints describe the platform; project allowlists enforce access and return 403 when violated ([models](https://atptoken.ai/docs/models), [how it works](https://atptoken.ai/docs/how-it-works)). Confusing the two is a quiet driver of [post-go-live bill spikes](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live).

## Two questions every request must answer

| Question | System | Bad shortcut |
|---|---|---|
| Does the platform know this model? | Catalog / routing | Assume docs = prod rights |
| May *this project* call it? | Allowlist | Trust client config only |
| Can *this project* afford it? | Credits / caps | Ignore until invoice |

## Why catalogs look like permission

SDKs print friendly model lists. Marketplaces celebrate breadth. Without a gateway check, any string in `model=` is a purchase order. Governance platforms separate discovery from authorization so finance and security can answer “who may use Opus-class models.”

## Designing allowlists

1. **Default deny** for frontier ids.  
2. **Per project**, not per human ([one project, one key](https://atptoken.ai/blog/one-project-one-key)).  
3. **Change control** — widening allowlist is a logged admin event ([monitoring](https://atptoken.ai/docs/monitoring)).  
4. **Pair with caps** ([spending caps](https://atptoken.ai/blog/ai-spending-caps-that-work)).  
5. **Document for app teams** — 403 means policy, not outage ([errors](https://atptoken.ai/docs/errors)).

## By use case

**Customer-facing bots:** small stable set.  
**Internal agents:** mid-tier + optional frontier project.  
**Eval sandboxes:** wider list, tiny allocation.

## A more modern approach

Spreadsheets of “approved models” rot. Runtime allowlists on the project do not. ATP Token sets allowed models per project; every key inherits them; unauthorized calls never reach providers.

[Resources / projects →](https://atptoken.ai/docs/resources) · [Quickstart →](https://atptoken.ai/docs/quickstart)

## FAQs

### What is the difference between a model catalog and model access control?

A catalog lists models a platform can route. Access control is the per-project (or per-key) policy that allows or denies those models at request time.

### Why does my API return 403 for a model I see in the docs?

Documentation and list endpoints often show the platform menu. If the model is not on your project allowlist, a governance gateway rejects the call before upstream.

### Should every project allow frontier models?

No. Default mid-tier models for high-volume paths; enable frontier models only for projects with budget and a written reason.

### How do model allowlists reduce AI cost?

They prevent silent upgrades to expensive models in application code. Cost control still needs spending caps; allowlists remove accidental premium routing.

### Where should model policy live—code or platform?

Platform enforcement survives client bugs and forks. Code can default wisely; the gateway must be the final authority.

## Further reading

- [Enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist)
- [AI gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026)
- [Models docs](https://atptoken.ai/docs/models)

Discovery inspires; permission protects.

[Enterprise plan →](https://atptoken.ai/enterprise-plan)

## FAQ

### What is the difference between a model catalog and model access control?

A catalog lists models a platform can route. Access control is the per-project (or per-key) policy that allows or denies those models at request time.

### Why does my API return 403 for a model I see in the docs?

Documentation and list endpoints often show the platform menu. If the model is not on your project allowlist, a governance gateway rejects the call before upstream.

### Should every project allow frontier models?

No. Default mid-tier models for high-volume paths; enable frontier models only for projects with budget and a written reason.

### How do model allowlists reduce AI cost?

They prevent silent upgrades to expensive models in application code. Cost control still needs spending caps; allowlists remove accidental premium routing.

### Where should model policy live—code or platform?

Platform enforcement survives client bugs and forks. Code can default wisely; the gateway must be the final authority.

---

Tags: Model allowlist, AI gateway, ATP
