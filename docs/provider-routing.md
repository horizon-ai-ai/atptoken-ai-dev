# Provider routing & fallbacks

> Source: https://atptoken.ai/docs/provider-routing/

Each model on the platform is served by a pool of one or more upstream providers. You call a single model id; the Gateway chooses a provider for the request and can fail over to another one, so the model keeps working even when a provider is degraded.

### One model id, a pool behind it

The provider set for each model — and its order — is configured on the platform side, not per request. Your client only ever names the model (from [GET /v1/models](https://atptoken.ai/docs/models/)); which provider actually serves it is handled for you and can change between requests without any code change on your side.

### Fallback behavior

When a provider fails or times out, the Gateway moves on to the next available provider in the model's pool. This maps to the status codes you may see:

| Code | Meaning |
|---|---|
| `502` | A provider connection failed or timed out. Safe to retry. |
| `503` | Every provider for the model is currently circuit-open. Honor `Retry-After` (60s). |
| `429` | Upstream rate limit, quota, or provider cooldown. Honor `Retry-After` if present. |

See [Errors](https://atptoken.ai/docs/errors/) for the full list. All responses carry a `request_id` you can quote to support when a route behaves unexpectedly.

> **Backend-confirmed details pending**
>
> Selection order within a pool, health-check timing, and circuit-open thresholds are set on the platform and will be documented here once confirmed. The behavior above (pool per model, automatic fallback, and the status-code mapping) is stable to rely on today.
