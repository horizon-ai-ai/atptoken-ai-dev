# How it works

> Source: https://atptoken.ai/docs/how-it-works/

The Gateway sits between your client and the upstream model providers. Every request flows through the same four stages, whichever SDK format you use.

## The request path

**One request through the Gateway**

1. Your client — `atp-…` key — OpenAI, Anthropic or Gemini format
2. Authenticate — key check — `401 token_revoked` if missing, disabled or expired
3. Authorize the model — project allowed list — `403` if the model isn't on it, `422` on the wrong entrypoint
4. Route to a provider — failover — on a provider error or timeout
5. Meter and bill — credits — `402` when the balance is exhausted
6. Upstream provider — never sees your ATP key

## 1. Authenticate

The project API key is validated and then stripped before anything is forwarded upstream — providers never see your ATP key. The key can go in `Authorization: Bearer` or `x-api-key`. Missing, disabled, or expired keys are rejected with `401 token_revoked` — sending no key at all returns it too, so check the header first. See [Authentication](https://atptoken.ai/docs/auth/).

## 2. Authorize the model

The requested model must be on the project's allowed list. If it isn't, the request is rejected with `403` before reaching any provider and is not billed — model access is enforced per project, not per key. Each model is also served on one entrypoint (`/v1/chat/completions` or `/v1/responses`, `/v1/messages`, or `/v1beta/models/{model}:generateContent`); call the wrong one and you get `422` naming the right one. See [Models](https://atptoken.ai/docs/models/).

## 3. Route to a provider

The Gateway picks a provider from the pool configured for that model and fails over to another on a provider error or timeout, so one model id stays stable across providers. See [Provider routing & fallbacks](https://atptoken.ai/docs/provider-routing/).

## 4. Meter and bill

Input and output tokens are metered and charged in credits against the project's balance. Billing is per request, not per attempt: one request may show several rows in your records, so don't add them up. If the balance is exhausted the request is rejected with `402`. See [How credits work](https://atptoken.ai/docs/credits/).

## What the Gateway changes and what it doesn't

The Gateway translates authentication and routing, but leaves your request and response bodies in the shape your SDK already expects.

| Handled for you | Left unchanged |
|---|---|
| Key validation and provider auth | Request body schema (per SDK format, never converted) |
| Model access checks | Response body schema |
| Provider selection and fallback | Streaming event sequence |
| Metering and credit deduction | Model behavior and outputs |

Because the wire formats pass through unchanged, migrating an existing OpenAI, Anthropic, or Gemini integration is usually just a base-URL and key change — as long as the model you call is served on that SDK's entrypoint. Two things that do differ: `stream` defaults to `true` on `/v1/chat/completions` and `/v1/messages`, so send it explicitly; and an HTTP `200` does not prove the model saw everything you sent, because bodies are forwarded as-is without checking each model's schema. Every response carries `x-request-id` — quote it when you report a problem.

## Go deeper on each stage

- [Authentication](https://atptoken.ai/docs/auth/)
  Where your key can go, and what a `401` actually means.
- [Model discovery](https://atptoken.ai/docs/models/)
  List what a project key may call before you hard-code a model id.
- [Provider routing](https://atptoken.ai/docs/provider-routing/)
  How a pool is ordered, and when the Gateway fails over to the next provider.
- [How credits work](https://atptoken.ai/docs/credits/)
  What gets metered, and what happens when a project balance runs out.

## Next steps

- [Quickstart](https://atptoken.ai/docs/quickstart/) — Send a first request through the Gateway.
- [OpenAI API vs enterprise AI gateway](https://atptoken.ai/blog/openai-api-vs-enterprise-ai-gateway/) — Calling a provider directly compared with going through a gateway.
- [AI gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026/) — How AI gateways compare.
