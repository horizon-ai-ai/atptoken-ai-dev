# Common responses

> Source: https://atptoken.ai/docs/errors/

All error responses include a `request_id` — quote it when contacting support. The error envelope follows whichever SDK format you called (OpenAI / Anthropic / Gemini).

- 400 — Bad request — missing field, malformed body, or unsupported feature (e.g. Anthropic system as array).
- 401 — Missing, disabled, expired, or unrecognized API key.
- 402 — Wallet or credit pool exhausted. Top up to resume.
- 403 — Model is not enabled for this project.
- 429 — Rate limit, quota, or provider cooldown. Honor Retry-After if present.
- 502 — Provider connection failed or timed out. Safe to retry.
- 503 — All providers for the model are circuit-open. Retry-After: 60.
- 5xx — Provider or Gateway error. Check request logs in the console.

### 200 with empty content

A request can return `200 OK` with an empty message — no error, just no text. This is almost always driven by request parameters, not a failure. The most common cause is a `max_tokens` that is too low for a reasoning (extended-thinking) model: the entire budget is consumed by internal reasoning before any visible output is produced, so the content comes back empty.

On this platform that request typically reports **zero token usage and deducts no credits** — an empty `200` with an empty `usage` object is the signature of this case, not a billing bug. Fix it by raising `max_tokens` so it covers the model's thinking budget plus your expected output, or turn extended thinking off. Always check `finish_reason` / `stop_reason` and `usage` before assuming text exists.
