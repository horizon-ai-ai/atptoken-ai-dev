# Errors & rate limits

The gateway returns errors in the format of the surface you called. Every error is traceable by a request id.

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

## Status codes

| Situation | HTTP | OpenAI `type` / `code` | Anthropic `type` | Extra headers | What to do |
|-----------|------|------------------------|------------------|---------------|------------|
| Missing / invalid API key | 401 | `authentication_error` / `invalid_api_key` | `authentication_error` | — | Check the `atp-` key is present and current. |
| Quota / balance exhausted | 402 | `insufficient_quota` / `insufficient_quota` | `invalid_request_error` | — | Out of allotted balance/quota (org/ws/proj any layer ≤ 0). Retrying won't help — top up or raise quota. **Exception:** the chat **Gemini** surface passes through Google's native **429** for this, not 402. |
| Request rate exceeded | 429 | `rate_limit_exceeded` / `rate_limit_exceeded` | `rate_limit_error` | `Retry-After: <secs>` | Wait `Retry-After` seconds, then retry. |
| All providers in cooldown | 429 | `rate_limit_exceeded` / `no_provider_available` | `rate_limit_error` | — | Transient upstream throttling — back off and retry. |
| Model not allowed | 403 | `invalid_request_error` / `permission_denied` | `invalid_request_error` | — | Use a model from `/v1/models`. |
| Missing/invalid request | 400 | `invalid_request_error` / `invalid_request_error` | `invalid_request_error` | — | Fix the request body. |
| All providers unavailable | 503 | `server_error` / `no_provider_available` | `overloaded_error` | `Retry-After: 60` | Retry after ≥60s with backoff. |
| Provider returned an error | provider's code | provider message, reshaped | provider message, reshaped | — | Inspect message; treat like the upstream model's own error. |
| Provider unreachable | 502 | `server_error` / `provider_error` | `api_error` | — | Transient; retry with backoff. |
| Gateway internal error | 500 | `server_error` / `internal_error` | `api_error` | — | Transient; retry with backoff. |

## Suggested retry policy

- **429 with `Retry-After`** → honor the header exactly. Without it (all-cooldown), back off (1s, 2s, 4s) a few attempts.
- **402 quota / balance exhausted** → do **not** retry; retrying won't help until the balance/quota is topped up or raised. Surface to the user. (On the chat Gemini surface this arrives as a native 429 instead — if a 429 has no `Retry-After` and doesn't clear on backoff, treat it as quota.)
- **502 / 503 / 500** → exponential backoff (e.g. 1s, 2s, 4s), a few attempts max. For 503 start at the `Retry-After` value.
- **401 / 400 / 403** → do not retry; fix the key (401) or the request (400/403).

Authentication failures (missing or invalid `atp-` key, **401**) are rejected before the request reaches a model — check that the key is present and current.
