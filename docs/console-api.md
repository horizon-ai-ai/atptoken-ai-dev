# Console API — programmatic usage, billing and resources

> Source: https://atptoken.ai/docs/console-api/

Everything you can see in the web console is also available as a REST API at `https://admin.atptoken.ai/api` — real-time balances, monthly usage per model, billing events, the model catalog, and your org/workspace/project tree. Use it to drive dashboards, budget alarms, or automatic model switching.

The full, always-in-sync specification is served as a live Swagger UI at [admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs) — every endpoint on the pages that follow can be tried there directly.

> **Two different credentials — do not mix them**
>
> Your **`atp-` API key** authenticates the data plane only (`api.atptoken.ai` — chat, media, embeddings). The Console API uses a **session token from `POST /api/users/login`** (your console email + password). Sending an `atp-` key to Console API endpoints returns `401` — it will never work, no matter the endpoint.

#### Authentication

```
curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}'
# → { "token": "<JWT>", "exp": ..., "user": { ... } }
```

The returned `token` is a Bearer token valid for roughly **2 hours**. Long-running scripts should re-login on `401` rather than caching the token forever. `POST /api/users/logout` revokes the current session.

#### Quickstart — poll balance, switch models

The most common integration: watch the real-time project balance and switch to a cheaper model when it crosses a threshold.

```
# 1) Login (console credentials, NOT the atp- API key)
TOKEN=$(curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}' | jq -r .token)

# 2) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 3) Current-month usage per model
curl -sS "https://admin.atptoken.ai/api/billing/summary?org_id=<org>" \
  -H "Authorization: Bearer $TOKEN"
```

#### Finding your IDs

Most endpoints take `org_id` / `workspace_id` / `project_id` query parameters. List them with:

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

#### Sections

- [Usage & balance](https://atptoken.ai/docs/console-api-usage/) — real-time balance, monthly usage, per-key usage, trends, wallet
- [Billing & top-ups](https://atptoken.ai/docs/console-api-billing/) — billing events, top-up records, checkout, credit adjustments
- [Model catalog](https://atptoken.ai/docs/console-api-models/) — platform-wide model lists per modality (chat / image / video / audio / embedding)
- [Resources & members](https://atptoken.ai/docs/console-api-resources/) — orgs, workspaces, projects, members, your account
- [Request logs](https://atptoken.ai/docs/console-api-logs/) — per-request observability records (7-day retention)

- 400 — Missing or malformed parameter (most endpoints require `org_id`).
- 401 — Missing/expired session token, or an `atp-` API key was sent instead.
- 403 — Authenticated, but no access to the requested scope.
- 404 — Resource not found within your visible scope.
