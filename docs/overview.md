# Overview

> Source: https://atptoken.ai/docs/overview/

ATP is a unified API that gives you access to many AI models through a single endpoint, with provider fallbacks and billing in one place.

- [Quickstart](https://atptoken.ai/docs/quickstart/)
  Six steps from adding credits to finding your first request in the Console.
- [API reference](https://atptoken.ai/docs/chat/)
  Endpoints, parameters, responses, and error codes.
- [SDKs and coding agents](https://atptoken.ai/docs/agents/)
  Point the OpenAI, Anthropic, or Google SDK — or Claude Code and Codex — at the Gateway, or add the ATP MCP server (https://mcp.atptoken.ai/mcp).
- [Use the Console](https://atptoken.ai/docs/console-setup/)
  Set up organizations, projects, and keys, then track usage and billing.

## Send your first request

Replace `MODEL_ID` with a model id from [GET /v1/models](https://atptoken.ai/docs/models/) — that list is exactly what `/v1/chat/completions` accepts — or pick one from the model menu above the example. You need a project API key in `$ATP_API_KEY` first; the [Quickstart](https://atptoken.ai/docs/quickstart/) walks through it. Send `stream` explicitly: on this endpoint it defaults to `true`.

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

## What you get

- **One endpoint, many models.** `GET /v1/project/models` lists every model your project allows — chat, media and embeddings. See [Model discovery](https://atptoken.ai/docs/models/).
- **Three wire formats.** Use the official OpenAI, Anthropic, or Google GenAI SDK unchanged — only the base URL changes. Each model is served on one of them; call it on the wrong one and you get `422` naming the right one.
- **Automatic fallback.** Each model is served by a provider pool, so a single model id keeps working when one provider is degraded. See [Provider routing](https://atptoken.ai/docs/provider-routing/).
- **One bill.** Usage across every model and provider is metered in credits. See [How credits work](https://atptoken.ai/docs/credits/).

## Three ways to integrate

| Approach | Best for |
|---|---|
| API | Full control, any language, no dependencies |
| SDKs | Type-safe calls with your existing OpenAI / Anthropic / Google SDK |
| Coding agents | Claude Code, Codex, and other agents that speak the wire format |

## Articles on AI cost and gateways

- [Enterprise AI cost management guide](https://atptoken.ai/blog/enterprise-ai-cost-management-guide/)
- [AI gateway comparison 2026](https://atptoken.ai/blog/ai-gateway-comparison-2026/)
- [Why AI bills explode after go-live](https://atptoken.ai/blog/why-ai-bills-explode-after-go-live/)

## Next steps

- [Quickstart](https://atptoken.ai/docs/quickstart/) — Create a project key and send your first request in six steps.
- [How it works](https://atptoken.ai/docs/how-it-works/) — Follow one request through auth, model access, routing, and metering.
- [Pricing](https://atptoken.ai/docs/pricing-model/) — See how input and output tokens turn into credits, with no monthly fee.
