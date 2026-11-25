# Console API — programmatic usage, billing and resources

> Source: https://atptoken.ai/docs/console-api/

Everything you can see in the ATP Token web console is also available as a REST API at `https://admin.atptoken.ai/api` — real-time balances, monthly usage per model, billing events, the model catalog, and your org/workspace/project tree. Use it to drive dashboards, budget alarms, or automatic model switching.

The full, always-in-sync specification is served as a live Swagger UI at [admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs) — every endpoint on the pages that follow can be tried there directly. A static, agent-readable mirror of the same surface — with operation IDs and typed parameters for function-calling tools — is published at [/openapi.json](https://atptoken.ai/openapi.json).

## Authentication

> **Two different credentials — do not mix them**
>
> Your **`atp-` API key** authenticates the data plane only (`api.atptoken.ai` — chat, media, embeddings). The Console API uses a **session token that belongs to a signed-in person**. Sending an `atp-` key to Console API endpoints returns `401` — it will never work, no matter the endpoint.

### A person has to sign in

`POST /api/users/login` requires a human-verification answer in its body, and only a browser can produce one. There is no API key, no service account and no machine sign-in for the Console API: every call on these pages is made with the session token of a person who signed in at [atptoken.ai](https://atptoken.ai).

That is a decision, not a gap waiting to be filled. Sign-in is the surface password-guessing scripts attack, and the per-account attempt limit that used to be the only brake punished the wrong party — the script moved on to the next account while the real holder sat locked out of their own. A human check stops that run at its first request, so it applies to every sign-in, with no threshold to cross and no exemption to earn.

Sign in in your browser, and the console holds that session token in `localStorage` under `atp_token` — it is the `$TOKEN` in the examples below. The token is a Bearer token valid for roughly **2 hours**, and `POST /api/users/logout` ends it early.

### What that rules out

A script cannot sign itself in, so it cannot keep itself authenticated: once the token expires, a person signs in again. Use the Console API for work you run with a session in hand — a report, a reconciliation, chasing down a failed request — not as an unattended service.

For a spending limit that needs no session at all, allocate credits instead of watching them: a project can only spend what was allocated to it, and the Gateway enforces that on every request. See [Set up a team with budget caps](https://atptoken.ai/docs/cb-budget-caps/).

## Poll the balance and switch models

The most common integration: watch the real-time project balance and switch to a cheaper model when it crosses a threshold. It runs for as long as the session token lasts: once that expires, a person has to sign in again.

```
# $TOKEN is one signed-in person's session token (see Authentication)

# 1) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 2) Current-month usage per model
curl -sS "https://admin.atptoken.ai/api/billing/summary?org_id=<org>" \
  -H "Authorization: Bearer $TOKEN"
```

## Find your IDs

Most endpoints take `org_id` / `workspace_id` / `project_id` query parameters. List them with:

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

## Endpoint groups

- [Usage & balance](https://atptoken.ai/docs/console-api-usage/) — real-time balance, monthly usage, per-key usage, trends, wallet
- [Billing & top-ups](https://atptoken.ai/docs/console-api-billing/) — billing events, top-up records, checkout, credit adjustments
- [Model catalog](https://atptoken.ai/docs/console-api-models/) — platform-wide model lists per modality (chat / image / video / audio / embedding)
- [Resources & members](https://atptoken.ai/docs/console-api-resources/) — orgs, workspaces, projects, members, your account
- [Request logs](https://atptoken.ai/docs/console-api-logs/) — per-request observability records (7-day retention)

## Errors

- 400 — Missing or malformed parameter (most endpoints require `org_id`).
- 400 — `captcha_required` or `captcha_invalid` on `POST /api/users/login`: the human check was not passed. A script cannot pass it — sign in in the browser.
- 401 — Missing/expired session token, or an `atp-` API key was sent instead.
- 403 — Authenticated, but no access to the requested scope.
- 404 — Resource not found within your visible scope.

## Next steps

- [Usage & balance](https://atptoken.ai/docs/console-api-usage/) — Read the real-time project balance and monthly usage.
- [Resources & members](https://atptoken.ai/docs/console-api-resources/) — Look up the org, workspace and project IDs most endpoints need.
- [Request logs](https://atptoken.ai/docs/console-api-logs/) — Find a failed request by status code or request ID.
