# Overview

> Source: https://atptoken.ai/docs/overview/

ATP is a unified API that gives you access to many AI models through a single endpoint, while handling provider fallbacks and billing in one place. Point any OpenAI-, Anthropic-, or Gemini-style client at the Gateway and pay for usage in credits.

#### What you get

- **One endpoint, many models.** Discover them with [GET /v1/models](https://atptoken.ai/docs/models/) and call any your project allows.
- **Three wire formats.** Use the OpenAI, Anthropic, or Google GenAI shape unchanged — only the base URL changes.
- **Automatic fallback.** Each model is served by a provider pool, so a single model id keeps working when one provider is degraded. See [Provider routing](https://atptoken.ai/docs/provider-routing/).
- **One bill.** Usage across every model and provider is metered in credits. See [How credits work](https://atptoken.ai/docs/credits/).

#### Three ways to integrate

| Approach | Best for |
|---|---|
| API | Full control, any language, no dependencies |
| SDKs | Type-safe calls with your existing OpenAI / Anthropic / Google SDK |
| Coding agents | Claude Code, Codex, and other agents that speak the wire format |

#### Start here

New to ATP? Run through the [Quickstart](https://atptoken.ai/docs/quickstart/), then read [How it works](https://atptoken.ai/docs/how-it-works/) to understand the request lifecycle. When you're ready to organize keys and budgets, see [Set up your organization](https://atptoken.ai/docs/console-setup/).

#### Related reading

- [Enterprise AI cost management guide](https://atptoken.ai/blog/enterprise-ai-cost-management-guide/)
- [AI gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026/)
- [Why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live/)

## Next steps

- [Quickstart](https://atptoken.ai/docs/quickstart/) — Create a project key and send your first request in four steps.
- [How it works](https://atptoken.ai/docs/how-it-works/) — Follow one request through auth, model access, routing, and metering.
- [Pricing](https://atptoken.ai/docs/pricing-model/) — See how input and output tokens turn into credits, with no monthly fee.
