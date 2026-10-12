# Provider routing & fallbacks

> Source: https://atptoken.ai/docs/provider-routing/

Each model on the platform is served by a pool of one or more upstream providers. You call a single model id; the Gateway chooses a provider for the request and can fail over to another one, so the model keeps working even when a provider is degraded.

## One model id, a pool behind it

The provider set for each model — and its order — is configured on the platform side, not per request. Your client only ever names the model (from [GET /v1/models](https://atptoken.ai/docs/models/)); which provider actually serves it is handled for you and can change between requests without any code change on your side.

## Fallback behavior

When a provider fails or times out, the Gateway moves on to the next available provider in the model's pool. This maps to the status codes you may see:

| Code | Meaning |
|---|---|
| `502` | A provider connection failed or timed out. Safe to retry. |
| `503` | Every provider for the model is circuit-open. Honor `Retry-After` (60s). |
| `429` | Upstream rate limit, quota, or provider cooldown. Honor `Retry-After` if present. |

See [Error codes](https://atptoken.ai/docs/errors/) for the full list. All responses carry a `request_id` you can quote to support when a route behaves unexpectedly.

> **Settings that are not public**
>
> Pool selection order, health-check intervals and circuit-open thresholds are not public. You can rely on one pool per model, automatic fallback, and the status codes above.

## Next steps

- [Error codes](https://atptoken.ai/docs/errors/) — The full list of status codes, including `502`, `503`, and `429`.
- [Model discovery](https://atptoken.ai/docs/models/) — List the model ids you can name in a request.
- [How it works](https://atptoken.ai/docs/how-it-works/) — Follow one request through auth, model access, routing, and metering.
