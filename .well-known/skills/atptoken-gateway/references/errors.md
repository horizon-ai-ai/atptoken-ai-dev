# Errors & rate limits

The gateway returns errors in the format of the surface you called. **For a 4xx, read the message, not just the status** — the gateway passes a model's own 4xx through unchanged, and those messages usually name the field and the allowed values.

Every response carries an **`x-request-id`** header. It is the one handle for reporting a problem; a request id you send yourself is not used.

## OpenAI surface error shape (`/v1/chat/completions`, `/v1/responses`)

```json
{
  "error": {
    "type": "<type>",
    "code": "<code>",
    "message": "<human-readable>",
    "request_id": "<id>"
  }
}
```

## Anthropic surface error shape (`/v1/messages`)

```json
{
  "type": "error",
  "error": { "type": "<type>", "message": "<human-readable>" }
}
```

## 401 shape (any surface)

```json
{ "message": "API key has been revoked or does not exist.", "error": "token_revoked" }
```

There is no `error` object here, so handle both shapes.

## Status codes

| Situation | HTTP | Code / type | Extra headers | What to do |
|-----------|------|-------------|---------------|------------|
| Missing, invalid, revoked or expired API key | 401 | `token_revoked` — "API key has been revoked or does not exist" | — | **Sending no key at all also returns this.** First check the header (`Authorization: Bearer` or `x-api-key`) actually went out, then the key. |
| Balance exhausted (`credit − inflight ≤ 0`, any of org/workspace/project) | 402 | `insufficient_quota` | — | Not a temporary limit — **do not retry**. Top up or raise the quota, then send again. **Exception:** the chat **Gemini** surface passes through Google's native **429** for this, not 402. |
| Model not on the project's allowed list | 403 | `permission_denied` (OpenAI: `{"error":{"type":"permission_denied","code":"permission_denied"}}`; Anthropic: `{"type":"error","error":{"type":"permission_denied",…}}`) | — | Not a key or balance problem. Use another model or ask an admin to allow it. Refused at create time — not billed. Check `GET /v1/project/models`. |
| Missing/invalid request | 400 | `invalid_request_error` | — | Read the message; fix the request body. |
| Wrong domain or path | 404 | message: `This domain serves only the LLM Gateway API (/v1, /v1beta)` | — | The domain serves only `/v1*` and `/omni/*`. Fix the base URL / path prefix. |
| `Idempotency-Key` already used on a **different** media endpoint | 409 | — | — | Use a new key; keep one key per endpoint (video / image / audio). |
| Model not served on this entry point | 422 | message: `this model is not served on this endpoint; it is available on /v1/messages` (names the right one) | — | Switch to the entry point the message names. Also returned when an asset cannot be used with the requested model — use a direct URL instead. |
| Rate limit (RPM) exceeded, or no capacity for the model right now | 429 | `rate_limit_exceeded` (OpenAI) / `rate_limit_error` (Anthropic) | `Retry-After: <secs>` | Back off: wait `Retry-After`, then retry. |
| Model's service returned an error / unreachable | 502 | `server_error` / `provider_error` | — | Transient; retry with backoff. |
| No capacity right now, or enqueue failed | 503 | `server_error` / `no_provider_available` (OpenAI), `overloaded_error` (Anthropic) | `Retry-After` | Retry after `Retry-After`, with backoff. |
| Balance could not be **read** (not a low balance) | 503 | `balance_check_unavailable` | `Retry-After` | The request never started and nothing was charged. Retry after `Retry-After`. For an actually empty balance see 402. |
| Gateway internal error | 500 | `server_error` / `internal_error` | — | Transient; retry with backoff. |

## Order of checks before a chat request starts

Model not on the project's allowed list → **403**; balance used up → **402**; no capacity right now → **429**. Only after all three pass does output (or the stream) start. Errors found before streaming come back as a normal JSON response, not an event stream.

## Billing

- Billing is **per request, not per attempt**. One request can appear as several rows in your logs — do not add them up.
- Credits are reserved before a request starts and charged after it completes.
- HTTP **200 does not prove the model saw everything** you sent: a request missing a message is still valid and still 200, and a message in the wrong format for the entry point can be forwarded and silently ignored. To verify, put a value the model cannot guess in the message and ask for it back.

## Suggested retry policy

- **429** → honor `Retry-After` exactly; without it, back off (1s, 2s, 4s) a few attempts.
- **402** → do **not** retry; it won't clear until the balance/quota is topped up or raised. Surface it to the user.
- **503** (including `balance_check_unavailable`) / **502** / **500** → exponential backoff (e.g. 1s, 2s, 4s), a few attempts max. For 503 start at the `Retry-After` value.
- **401 / 400 / 403 / 404 / 409 / 422** → do not retry unchanged; fix the key (401), the request (400), the model or project access (403), the URL (404), the idempotency key (409) or the entry point (422).

Include the `x-request-id` response header when you report a problem.
