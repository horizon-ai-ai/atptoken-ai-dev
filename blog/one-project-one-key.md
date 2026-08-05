# One project, one key: why shared API keys are the most expensive AI debt (2026)

> Source: https://atptoken.ai/blog/one-project-one-key/
> Published: 2026-08-07 · By: hung-chien (AI Growth & Brand Manager)

Shared AI API keys destroy attribution and make revokes dangerous. One project, one key ties every request to an owner, budget, and audit trail.

## TL;DR

- One project, one key means each workload owns a scoped credential that inherits that project's models and budget—not a company-wide skeleton key.
- Shared keys fail two jobs at once: you cannot attribute spend, and you cannot revoke without breaking everyone.
- Migrate by inventorying keys, splitting production from experiments, and retiring shared secrets on a dated plan.

One project, one key is the rule that each AI workload uses a project-scoped API key that inherits that project's model allowlist and budget—so spend, access, and revocation all have a single owner. This guide is for platform and security teams still running production traffic on a shared vendor key.

The conclusion first: **shared keys optimize for speed on day one and maximize blast radius on day one hundred.** Attribution, caps, and incident response all require project-scoped credentials. This is item one of the [enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist) and the root of several [post-go-live control gaps](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live).

## Why shared keys feel fine until they do not

| Shared key “win” | Hidden cost after scale |
|---|---|
| One secret in CI | Every pipeline owns the same blast radius |
| Fast onboarding | Offboarding becomes “who still uses this?” |
| Simple docs | Finance cannot map spend to a product |
| One rate limit pool | Noisy neighbors starve critical paths |

When the bill jumps, [request logs](https://atptoken.ai/docs/monitoring) that only know one key can say which model was hot—not which team.

## What “one project, one key” requires

From [set up your organization](https://atptoken.ai/docs/console-setup) and [managing API keys](https://atptoken.ai/docs/console-keys):

1. **Organization** — billing and team boundary  
2. **Workspace** — credit container for related work  
3. **Project** — allowed models + credit balance  
4. **API key** — scoped to exactly one project  

The secret is shown once (`atp-` prefix on ATP), stored outside git, revocable immediately, retained in the roster for audit.

## By environment

### Production

One key per deployable service. Never share with local laptops.

### Staging

Separate project and low cap. Staging bugs should not drain production allocation ([budget caps](https://atptoken.ai/docs/cb-budget-caps)).

### Experiments and coding agents

Disposable projects, cheap models on the allowlist, caps low enough to burn. See [agent tax](https://atptoken.ai/blog/what-is-the-agent-tax) and [Claude Code on ATP](https://atptoken.ai/docs/cb-claude-code).

## By team size

Small teams: three projects—prod, staging, sandbox—are enough.  
Mid-size: one project per product surface.  
Enterprise: align projects to cost centers; roles at workspace/project ([team](https://atptoken.ai/docs/team)).

## Migration plan off a skeleton key

1. Inventory every caller of the shared secret.  
2. Create projects and issue keys ([console keys](https://atptoken.ai/docs/console-keys)).  
3. Dual-run with tight [allocations](https://atptoken.ai/docs/credits).  
4. Cut over service by service.  
5. Revoke the shared key; confirm zero traffic in [logs](https://atptoken.ai/docs/monitoring).  
6. Document the incident path: revoke → trace → reissue.

## A more modern approach

Policy PDFs that say “do not share keys” lose to convenience. Platforms that **cannot issue non-project keys** make the right path the easy path. ATP Token binds every key to a project’s models and credits; revoked keys stay visible for audit. Wire formats stay OpenAI / Anthropic / Gemini-compatible—migration is usually base_url and key ([migrate from OpenAI](https://atptoken.ai/docs/cb-migrate-openai)).

[Quickstart →](https://atptoken.ai/docs/quickstart)

## FAQs

### What does one project, one key mean?

It means every production workload gets its own project-scoped API key that inherits that project's allowed models and credit balance, so every request has a clear owner for spend and access.

### Why are shared API keys risky for AI usage?

Shared keys hide which system spent tokens, block safe revocation on offboarding, and turn any leak into an organization-wide incident instead of a project-scoped blast radius.

### How should enterprises issue LLM API keys?

Create a project per system or product surface, enable only needed models, allocate a budget, issue a key shown once, store it in a secret manager, and revoke from the console when the project ends.

### What happens when someone leaves if keys follow projects?

You remove their membership or project access; you do not rotate a single key that half the company depends on. Project keys stay with the workload, not the person.

### How do I migrate off a shared AI key?

Inventory callers, create project keys per system, dual-run with low caps, cut traffic system by system, then revoke the shared key and keep it in the audit roster.

## Further reading

- [Why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live)
- [How to read your AI bill](https://atptoken.ai/blog/how-to-read-your-ai-bill)
- [Managing API keys](https://atptoken.ai/docs/console-keys)

If every request has a project owner, the bill becomes a map instead of a mystery.

[Enterprise plan →](https://atptoken.ai/enterprise-plan)

## FAQ

### What does one project, one key mean?

It means every production workload gets its own project-scoped API key that inherits that project's allowed models and credit balance, so every request has a clear owner for spend and access.

### Why are shared API keys risky for AI usage?

Shared keys hide which system spent tokens, block safe revocation on offboarding, and turn any leak into an organization-wide incident instead of a project-scoped blast radius.

### How should enterprises issue LLM API keys?

Create a project per system or product surface, enable only needed models, allocate a budget, issue a key shown once, store it in a secret manager, and revoke from the console when the project ends.

### What happens when someone leaves if keys follow projects?

You remove their membership or project access; you do not rotate a single key that half the company depends on. Project keys stay with the workload, not the person.

### How do I migrate off a shared AI key?

Inventory callers, create project keys per system, dual-run with low caps, cut traffic system by system, then revoke the shared key and keep it in the audit roster.

---

Tags: API keys, Enterprise AI governance, ATP
