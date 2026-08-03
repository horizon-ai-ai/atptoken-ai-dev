# Frequently asked questions

> Source: https://atptoken.ai/docs/faq/

### Do I need a special SDK?

No. The Gateway is compatible with the OpenAI, Anthropic, and Google GenAI SDKs — point them at the Gateway base URL and use a project API key. See [Integrations](https://atptoken.ai/docs/agents/).

### What is the base URL?

`https://api.atptoken.ai` for the Anthropic and Gemini formats, and `https://api.atptoken.ai/v1` for the OpenAI format. Each SDK page shows the exact value.

### Which models can my key call?

Only the models on its project's allowed list. [GET /v1/models](https://atptoken.ai/docs/models/) lists what the platform offers; access is enforced per project at request time, so the list is the menu — not your key's permissions.

### Can I stream responses?

Yes. Set `stream: true` and the Gateway streams SSE in the format matching your SDK. See [OpenAI SSE](https://atptoken.ai/docs/sse-openai/) and [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/).

### What happens if a provider is down?

Each model is served by a pool of providers and the Gateway fails over automatically. If every provider for a model is unavailable you get a `503` with `Retry-After`. See [Provider routing](https://atptoken.ai/docs/provider-routing/).

### How am I billed, and are credits refundable?

Usage is metered on input + output tokens and paid in credits (1 credit = USD 0.01). Top-ups and credits are non-refundable. See [How credits work](https://atptoken.ai/docs/credits/) and [Top up & wallet](https://atptoken.ai/docs/topup/).

### How do I see what I spent?

The Usage page summarizes credits and tokens by model and by key; request logs give a per-request audit trail. See [Usage & logs](https://atptoken.ai/docs/monitoring/) and [Tracking spend](https://atptoken.ai/docs/spend/).

### Why did a reasoning model return 200 with an empty message?

`max_tokens` was too low. Reasoning (extended-thinking) models spend their thinking inside that budget; when it runs out before any visible output, you get an empty `200` — typically with zero usage and no credits deducted. Raise `max_tokens` to cover thinking plus your expected output. See [Common responses](https://atptoken.ai/docs/errors/).

### Does ATP Token only serve text models?

No. The catalog also includes image, video, audio (TTS) and embedding models. See [Media models](https://atptoken.ai/docs/media/) for what each modality does and how it is billed.
