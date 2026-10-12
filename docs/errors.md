# Error codes and next steps

> Source: https://atptoken.ai/docs/errors/

Look up a status code the Gateway returned to see what it means, what to check first, and what to do next.

## Status codes

Jump to: [400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **Include the request_id when you contact support**
>
> Every error response carries a `request_id`. Include it when you contact support so we can find the request.

| Status | What it means | Check first | What to do |
|---|---|---|---|
| `400` | Malformed request | A missing field, invalid JSON, or something the format does not support | Fix the request against the endpoint's parameter table and send it again |
| `401` | Invalid key | Whether a key was sent, whether it starts with `atp-`, and whether it is disabled or expired | Check or recreate it under "API Keys"; for header placement, see [Authentication](https://atptoken.ai/docs/auth/) |
| `402` | Credits are used up | Available credits under "Usage" in the Console | Add credits under "Billing"; for a team organization, also allocate credits under "Resources" |
| `403` | The model is not enabled for this project | The model IDs returned by `GET /v1/models` | Use a model from that list, or add the model to the project under "Resources" |
| `429` | Rate limit, quota, or provider cooldown | The `Retry-After` response header | Wait for `Retry-After`, then retry |
| `502` | Provider connection failed or timed out | — | Safe to retry right away |
| `503` | Every provider for this model is temporarily unavailable | `Retry-After: 60` | Retry after 60 seconds |
| `5xx` | Provider or Gateway error | The `request_id` in the response | Look up the request ID under "Request logs" in the Console; include it when you contact support |

## See where a request stops

Choose a scenario to see where the request stops and what the response looks like.

**Request path through ATP**

| Step | Check | Stops with |
| --- | --- | --- |
| 1. Client | Sends a project key | — |
| 2. Key check | Valid, active key | 401 |
| 3. Model allowlist | Model enabled for the project | 403 |
| 4. Credits | Project balance left | 402 |
| 5. Rate limit | Within limits | 429 |
| 6. Provider | Routed with failover | — |
| 7. Log & billing | Metered in credits | — |

| Scenario | Stops at | Status | Response |
| --- | --- | --- | --- |
| OK | Log & billing | 200 OK | headers: `x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests` — The body is the provider's response in your SDK's format. Rate-limit headers tell you how much room is left. |
| Bad key | Key check | 401 Unauthorized | `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}` |
| Model not allowed | Model allowlist | 403 Forbidden | `{"error":{"message":"model not available for this project","type":"permission_denied","request_id":"..."}}` |
| Out of credits | Credits | 402 Payment Required | An error body in your SDK's error format: the wallet or credit pool is exhausted. Top up to resume; retrying won't help. |
| Rate limited | Rate limit | 429 Too Many Requests | An error body in your SDK's error format: a rate limit, quota or provider cooldown. Back off and retry; honor Retry-After if present. |

## 200 with empty content

A request can return `200 OK` with an empty message — no error, just no text. This is almost always driven by request parameters, not a failure. The most common cause is a `max_tokens` that is too low for a reasoning (extended-thinking) model: the entire budget is consumed by internal reasoning before any visible output is produced, so the content comes back empty.

On this platform that request typically reports **zero token usage and deducts no credits** — an empty `200` with an empty `usage` object is the signature of this case, not a billing bug. Fix it by raising `max_tokens` so it covers the model's thinking budget plus your expected output, or turn extended thinking off. Always check `finish_reason` / `stop_reason` and `usage` before assuming text exists.

## Next steps

- [Authentication](https://atptoken.ai/docs/auth/) — The three accepted key locations, and what a `401` means.
- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — Set `max_tokens` so reasoning models return visible output.
- [Request logs](https://atptoken.ai/docs/console-api-logs/) — Look up a failed request by its request ID.
