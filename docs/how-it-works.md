# How it works

> Source: https://atptoken.ai/docs/how-it-works/

The Gateway sits between your client and the upstream model providers. Every request flows through the same four stages, whichever SDK format you use.

## 1. Authenticate

The project API key is validated and then stripped before anything is forwarded upstream — providers never see your ATP key. Missing, disabled, or expired keys are rejected with `401`. See [Authentication](https://atptoken.ai/docs/auth/).

## 2. Authorize the model

The requested model must be on the project's allowed list. If it isn't, the request is rejected with `403` before reaching any provider — model access is enforced per project, not per key. See [Models](https://atptoken.ai/docs/models/).

## 3. Route to a provider

The Gateway picks a provider from the pool configured for that model and fails over to another on a provider error or timeout, so one model id stays stable across providers. See [Provider routing & fallbacks](https://atptoken.ai/docs/provider-routing/).

## 4. Meter and bill

Input and output tokens are metered and charged in credits against the project's balance. If the balance is exhausted the request is rejected with `402`. See [How credits work](https://atptoken.ai/docs/credits/).

### What the Gateway changes — and what it doesn't

The Gateway translates authentication and routing, but leaves your request and response bodies in the shape your SDK already expects.

| Handled for you | Left unchanged |
|---|---|
| Key validation and provider auth | Request body schema (per SDK format) |
| Model access checks | Response body schema |
| Provider selection and fallback | Streaming event sequence |
| Metering and credit deduction | Model behavior and outputs |

Because the wire formats pass through unchanged, migrating an existing OpenAI, Anthropic, or Gemini integration is usually just a base-URL and key change.

### Go deeper on each stage

- [Authentication](https://atptoken.ai/docs/auth/)
  The three accepted key locations, and what a `401` actually means.
- [Model discovery](https://atptoken.ai/docs/models/)
  List what a project key may call before you hard-code a model id.
- [Provider routing](https://atptoken.ai/docs/provider-routing/)
  How a pool is ordered, and when the Gateway fails over to the next provider.
- [How credits work](https://atptoken.ai/docs/credits/)
  What gets metered, and what happens when a project balance runs out.

#### Related reading

- [OpenAI API vs enterprise AI gateway](https://atptoken.ai/blog/openai-api-vs-enterprise-ai-gateway/)
- [AI gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026/)
