# API key management for LLM APIs: one project, one key, and a 30-day migration runbook (2026)

> Source: https://atptoken.ai/blog/one-project-one-key/
> Published: 2026-08-07 · By: hung-chien (AI Growth & Brand Manager)

API key management for LLM APIs: what breaks with a shared key, how to issue one key per project, where each key lives, and a 30-day migration runbook.

## TL;DR

- Give every workload its own project and its own key, so revoking, rotating and attributing spend touch one service at a time.
- OpenAI recommends a unique API key per team member and never shipping keys in client code; production services need a workload key so an employee leaving does not break them.
- Moving off a shared key takes about 30 days: inventory callers, create projects, cut over non-production, cut over production one service at a time, then revoke.

API key management for LLM APIs is the set of rules for who gets a key, what each key can reach, where it is stored, and how it is rotated and revoked. The pattern that holds up in production is one project, one key: each workload gets its own project, and that project's key carries its own model list and budget. Below are three ways a shared key fails, an issuance pattern, a table of where the key lives in each environment, and a 30-day migration runbook.

## Three ways a shared key goes wrong

### The offboarded contractor

A contractor builds the retrieval prototype with the company's only API key in a local `.env` file, then leaves on a Friday. The same key also runs the support bot, the nightly summarization job and an internal Slack assistant. Revoking it that afternoon breaks all three. Leaving it means a former contractor still holds a working key. Most teams choose "rotate next sprint", and the sprint fills up.

With one key per project, the contractor only ever had the key for their sandbox project. You revoke it and nothing else changes.

### The key in a public repo

Someone commits a config file with the key to a public repository. Whoever finds it can send traffic that lands on your bill, and because every service sends the same credential, their requests look exactly like yours in the usage data. The fix is the same as the contractor case, with the same outage attached.

### The spike nobody can attribute

The monthly bill doubles. The provider dashboard shows which model grew, but every request carries the same key, so nobody can say which product caused it. Finance asks for a breakdown by product; engineering spends two days matching timestamps across service logs.

## What the vendors recommend

OpenAI's [best practices for API key safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) ask for a unique API key per team member, rotation and expiry, and never putting keys in client-side code. OpenAI also recommends separate projects for staging and production, each with its own limits ([production best practices](https://developers.openai.com/api/docs/guides/production-best-practices)). Anthropic lets you scope an API key to a single Console [workspace](https://platform.claude.com/docs/en/manage-claude/workspaces). Vercel AI Gateway keys can carry a budget and an expiry, which suits a contractor key with a fixed end date ([Vercel budgets](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)).

Per-person keys solve offboarding for humans. A production service should not run on a person's key, because removing that person then stops the service. The working split is personal keys for personal sandboxes and a project key for each deployed workload.

## The issuance pattern

1. **One project per workload and environment.** `support-bot-prod` and `support-bot-staging` are separate projects with separate keys.
2. One key per project for services. People who experiment get their own sandbox project.
3. Name keys after service, environment and month of issue, for example `support-bot-prod-2026-10`, so a key found in a log or a repo points to its owner.
4. Move the secret straight from the console into the secret manager. Never paste it into chat, tickets or docs.
5. Rotate by overlap: issue a new key in the same project, deploy it, confirm traffic has moved, then revoke the old one.

## Where the key lives in each environment

| Environment | Project | Where the key lives | Who can read it |
|---|---|---|---|
| Production service | `support-bot-prod` | Cloud secret manager, injected as an environment variable at deploy | The service's runtime identity |
| Staging | `support-bot-staging` | Same secret manager, separate secret path | The staging deploy role |
| CI evaluations | `ci-evals` | CI secret store (for example GitHub Actions secrets) | The pipeline only |
| Local development | `dev-<name>` sandbox | `.env` file listed in `.gitignore` | That developer |
| Coding agent | `agent-<name>` sandbox | `ANTHROPIC_AUTH_TOKEN` in the shell or the `env` block of `~/.claude/settings.json` ([Claude Code on ATP](https://atptoken.ai/docs/cb-claude-code)) | That developer |
| Browser or mobile app | none | Nowhere. The app calls your backend, which holds the key | Nobody outside the backend |

## How ATP Token keys work

ATP Token has a four-level tree: organization, workspace, project and key ([set up your organization](https://atptoken.ai/docs/console-setup)). A key belongs to exactly one project and inherits that project's allowed models and credit balance. Model access is set per project, never per key, so two keys in the same project can always call the same models.

The Create key wizard asks for a name, the workspace and project, and optionally some starting credits. Keys start with `atp-`, are 92 characters long, and the full secret is displayed once; afterwards only the prefix is visible ([managing API keys](https://atptoken.ai/docs/console-keys)). The API keys page lists every key in the organization across all workspaces and projects, searchable by name or prefix. A revoked key stops working immediately and stays in the roster for audit.

For attribution, the Usage page shows credits and tokens by model and by key, and request logs record each call with its model, status, token counts and request ID ([usage and logs](https://atptoken.ai/docs/monitoring)). Request logs are kept for 7 days, so review a suspect key soon after an incident. The gateway strips your `atp-` key before forwarding a request, so upstream providers never see it ([how it works](https://atptoken.ai/docs/how-it-works)).

Who can do what is set by role: an Admin manages members, resources, keys and credit allocation, and a Member uses what they have access to ([team and roles](https://atptoken.ai/docs/team)).

## Migration runbook: from one shared key to project keys

| Day | Step | Done when |
|---|---|---|
| Day 1 | Search repositories, CI secrets and secret managers for the shared key's prefix. List every caller with an owner. | Every caller has a name next to it |
| Days 2–3 | Create one project per caller, choose its allowed models, allocate a small budget, issue its key. | Each project has a key in the secret manager |
| Days 4–10 | Move non-production callers first: staging, CI, sandboxes. On ATP this is a base URL, an `atp-` key and a model id ([migrate from OpenAI](https://atptoken.ai/docs/cb-migrate-openai)). | Non-production traffic shows under the new keys |
| Days 11–20 | Move production services one at a time, at low-traffic hours, checking per-key usage after each. | Each service shows usage under its own key |
| Days 21–27 | Watch the shared key. Any remaining traffic is a caller you missed; find it and move it. | Seven days with no traffic on the shared key |
| Day 28 | Revoke the shared key. | Revoked, with a note on why and when |
| Day 30 | Write the leak procedure: revoke, issue a new key in the same project, redeploy, review that key's usage. | The procedure is in the on-call runbook |

The runbook pairs well with a budget per project, so a leaked or looping key also hits a cap. See [AI API spending limits compared](https://atptoken.ai/blog/ai-spending-caps-that-work).

[Quickstart: create a project key](https://atptoken.ai/docs/quickstart)

## Related reading

- [Model catalog vs access control](https://atptoken.ai/blog/model-catalog-vs-access-control)
- [AI API spending limits compared](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [Enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist)

## FAQ

### What is API key management for LLM APIs?

It is the set of rules for who gets an API key, what each key can reach, where it is stored, and how it is rotated and revoked. For LLM APIs it also decides whether you can tell which service spent the money.

### Should every developer have their own OpenAI API key?

OpenAI's Help Center recommends a unique API key for each team member. Use personal keys for personal sandboxes, and give production services their own project key so a developer leaving does not take a live service down.

### What should I do if an LLM API key leaks?

Revoke it first, then issue a new key in the same project, redeploy the service that used it, and review that key's usage for traffic you did not send. With one key per project, only that one service is affected.

### Can one ATP Token key access more than one project?

No. An ATP Token key belongs to exactly one project and inherits that project's allowed models and credit balance. To use another project, issue a key in that project.

---

Tags: API key management, API keys, LLM security, ATP
