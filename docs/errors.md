# Error codes and next steps

> Source: https://atptoken.ai/docs/errors/

Look up a status code the Gateway returned to see what it means, what to check first, and what to do next. **For a 4xx, read the message, not just the status.** The Gateway passes a model's own 4xx through unchanged, and those messages usually name the field and the allowed values.

## Status codes

Jump to: [400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [404](#status-404) · [409](#status-409) · [422](#status-422) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **Include the x-request-id when you contact support**
>
> Every response carries an `x-request-id` header. It is the one handle for reporting a problem — include it when you contact support. A request id you send yourself is not used.

| Status | What it means | Check first | What to do |
|---|---|---|---|
| `400` | Malformed request. For media: missing `model` or prompt, mixed asset sources, `asset_not_ready`, `asset_failed` | The message — it usually names the field | Fix the request against the endpoint's parameter table and send it again |
| `401` | `token_revoked` — "API key has been revoked or does not exist". **Sending no key at all also returns this** | Whether the header actually went out, then whether the key starts with `atp-` and is still active | Check or recreate it under "API Keys"; for header placement, see [Authentication](https://atptoken.ai/docs/auth/) |
| `402` | `insufficient_quota` — credits are used up | Available credits under "Usage" in the Console | Not a temporary limit — do not retry. Add credits under "Billing"; for a team organization, also allocate credits under "Resources" |
| `403` | `permission_denied` — the model is controlled and your project is not on its allowed list. Not a key or balance problem | The model ids returned by `GET /v1/project/models` | Use another model, or ask an admin to add the model to the project under "Resources". Not billed |
| `404` | Wrong domain or path. The message says `This domain serves only the LLM Gateway API (/v1, /v1beta)` | The base URL and path prefix — this domain serves only `/v1*` and `/omni/*` | Fix the base URL or path |
| `409` | This `Idempotency-Key` already points to a task on a **different** media endpoint | Whether you reused one key across video, image and audio | Use a new key; keep a separate key per endpoint |
| `422` | The model is not served on this endpoint (the message **names the right one**), or this asset cannot be used with the model you asked for | The endpoint named in the message | Switch to that endpoint, or use a direct URL instead of the asset |
| `429` | Rate limit (RPM), or no capacity for this model right now | The `Retry-After` response header | Back off: wait for `Retry-After`, then retry |
| `502` | The model's service returned an error, or the connection failed or timed out | — | Safe to retry |
| `503` | Two causes: no capacity right now; or `balance_check_unavailable` — the balance could not be read (**not** a low balance), so the request never started and nothing was charged | `Retry-After` | Retry after `Retry-After` |
| `5xx` | Provider or Gateway error | The `x-request-id` response header | Look up the request ID under "Request logs" in the Console; include it when you contact support |

## How requests are billed

Billing is per request, not per attempt. One request can appear as several rows in your logs — do not add them up.

Credits are reserved before a request starts and charged after it completes. A `403` is refused at create time and is not billed. A `503 balance_check_unavailable` request never started and was not charged.

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

A `200` also does not prove the model saw everything you sent. A request missing a message is still valid and still `200`, and a message in a format that does not belong to the endpoint (for example OpenAI's `role: "tool"` sent to `/v1/messages`) is forwarded as is — some models read it, others return `200` and ignore it. To confirm content arrived, put a value the model cannot guess in the message and ask for it back.

## Next steps

- [Authentication](https://atptoken.ai/docs/auth/) — Where your key goes, and what a `401` means.
- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — Set `max_tokens` so reasoning models return visible output.
- [Request logs](https://atptoken.ai/docs/console-api-logs/) — Look up a failed request by its request ID.
