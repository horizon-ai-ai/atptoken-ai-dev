# Frequently asked questions

> Source: https://atptoken.ai/docs/faq/

Short answers to common questions about connecting to the Gateway, which models you can call, and how usage is billed.

## Connecting to the Gateway

### Is there an MCP server?

Yes: `atptoken-api-docs` at `https://mcp.atptoken.ai/mcp`. It gives Claude Code, Codex and other agents the API guide, a live model check and a video-request checker. Adding it needs no key; only the live model check asks for your key. Setup for each tool is in [Add the ATP MCP server](https://atptoken.ai/docs/mcp/).

### Do I need a special SDK?

No. The official OpenAI, Anthropic, and Google GenAI (`google-genai`) SDKs work unchanged — point them at the Gateway base URL and use a project API key. The older `google-generativeai` package is deprecated. Each model is served through one SDK and one entrypoint; call the wrong one and you get `422` naming the right one. See [Integrations](https://atptoken.ai/docs/agents/).

### What is the base URL?

`https://api.atptoken.ai` for the Anthropic and Gemini formats (Gemini also needs `apiVersion: "v1beta"`), and `https://api.atptoken.ai/v1` for the OpenAI format. Each SDK page shows the exact value. The domain serves only `/v1*` and `/omni/*`; any other path, such as `/api`, returns `404`.

### Can I stream responses?

Yes, and always set `stream` explicitly. On `/v1/chat/completions` and `/v1/messages` it defaults to `true` (the opposite of OpenAI's and Anthropic's own APIs); on `/v1/responses` it defaults to `false`. Gemini has no `stream` field — switch to the `:streamGenerateContent` endpoint. See [OpenAI SSE](https://atptoken.ai/docs/sse-openai/) and [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/).

## Models and availability

### Which models can my key call?

Only the models on its project's allowed list. `GET /v1/project/models` with the same key returns that full list — chat, media and embedding models together. `GET /v1/models` is only OpenAI's list: it shows the chat models served on `/v1/chat/completions` and `/v1/responses`, so most `claude-*` models (on `/v1/messages`), Gemini models (on `/v1beta/models`), and media and embedding models are not on it. A model missing from a list is not necessarily unusable; if the project really isn't allowed to call it, the create request returns `403` and nothing is billed. See [Model discovery](https://atptoken.ai/docs/models/).

### What happens if a provider is down?

Each model is served by a pool of providers and the Gateway fails over automatically. If every provider for a model is unavailable you get a `503` with `Retry-After`. See [Provider routing](https://atptoken.ai/docs/provider-routing/).

### Why did a reasoning model return 200 with an empty message?

`max_tokens` was too low. Reasoning (extended-thinking) models spend their thinking inside that budget; when it runs out before any visible output, you get an empty `200` — typically with zero usage and no credits deducted. Raise `max_tokens` to cover thinking plus your expected output. See [Common responses](https://atptoken.ai/docs/errors/).

### Does ATP Token only serve text models?

No. The catalog also includes image, video, audio (TTS) and embedding models. Media is asynchronous only: create a task, poll it, then download from a signed URL within 24 hours. See [Media models](https://atptoken.ai/docs/media/) for what each modality does and how it is billed.

## Billing and usage

### How am I billed, and are credits refundable?

Usage is metered on input + output tokens and paid in credits (1 credit = USD 0.01). Top-ups and credits are non-refundable. See [How credits work](https://atptoken.ai/docs/credits/) and [Top up & wallet](https://atptoken.ai/docs/topup/).

### How do I see what I spent?

The Usage page summarizes credits and tokens by model and by key; request logs give a per-request audit trail. Billing is per request, not per attempt: one request can show up as several rows in your records, so don't add them up. See [Usage & logs](https://atptoken.ai/docs/monitoring/) and [Tracking spend](https://atptoken.ai/docs/spend/).

## Next steps

- [Quickstart](https://atptoken.ai/docs/quickstart/) — Create a project key and send your first request.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means and what to check first.
- [How credits work](https://atptoken.ai/docs/credits/) — How usage turns into credits and where they are spent.
