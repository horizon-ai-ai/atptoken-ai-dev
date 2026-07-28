---
name: atptoken-gateway
description: Call the Atptoken LLM Gateway — an OpenAI/Anthropic/Gemini-compatible API fronting many model providers behind one endpoint and key. Use when integrating with Atptoken, calling api.atptoken.ai, listing available models, or handling gateway auth, errors, and rate limits. Start here, then load atptoken-openai / atptoken-anthropic / atptoken-gemini for the specific SDK.
---

# Atptoken LLM Gateway

The Atptoken gateway is a single HTTPS endpoint that speaks three popular wire formats — **OpenAI**, **Anthropic**, and **Google Gemini** — and routes each request to a real model provider behind the scenes (with failover and usage accounting). You bring an `atp-` API key and your existing SDK; the gateway does the rest.

You never call a model provider directly and you never need provider API keys. Point your SDK's base URL at the gateway and authenticate with your Atptoken key.

## Base URL

```
https://api.atptoken.ai/v1
```

The Gemini surface also accepts the `/v1beta` prefix that the Google SDK uses (see `atptoken-gemini`).

## Authentication

Every request needs your Atptoken API key — a long opaque string that starts with `atp-`. Obtain one from your Atptoken account/administrator; treat it like a password.

Present it in **one** of these ways (pick whichever your SDK uses):

| Method | Header / param | Typical client |
|--------|----------------|----------------|
| Bearer token | `Authorization: Bearer atp-...` | OpenAI & Anthropic SDKs |
| Google API key header | `x-goog-api-key: atp-...` | Gemini SDK |
| Query parameter | `?key=atp-...` | Gemini SDK / quick tests |

You do **not** send organization / project / model-routing headers — the gateway derives all of that from your key.

## Pick your surface

| Your client | Skill to load | Endpoints |
|-------------|---------------|-----------|
| OpenAI SDK / OpenAI-compatible tools | `atptoken-openai` | `POST /v1/chat/completions`, `POST /v1/responses`, `POST /v1/embeddings` |
| Anthropic SDK / Claude clients | `atptoken-anthropic` | `POST /v1/messages`, `POST /v1/messages/count_tokens` |
| Google Gemini SDK | `atptoken-gemini` | `POST /v1beta/models/{model}:generateContent` |
| Video generation (async) | `atptoken-video` | `POST /omni/media/v1/contents/generations/tasks` (+ poll) |
| Image generation | `atptoken-image` | `POST /omni/media/v1/images/generations` |
| Audio / TTS | `atptoken-audio` | `POST /omni/media/v1/audio/generations` |

The chat/embeddings surface lives under `/v1`; generative **media** (video, image, audio) lives under `/omni/media/v1` — see the `atptoken-video` / `atptoken-image` / `atptoken-audio` skills. The surface is just the **wire format you prefer** — any chat surface can reach any available model. An OpenAI-format request can be served by a model that is natively Anthropic or Gemini, transparently.

## Discover available models

List the model names you're allowed to use. Use the exact `id` values as the `model` field in your requests.

```bash
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY"
```

```json
{
  "object": "list",
  "data": [
    { "id": "gpt-5", "object": "model" },
    { "id": "claude-opus-4-7", "object": "model" }
  ]
}
```

If a model you request isn't in this list, the gateway returns **403** (`permission_denied`). Always source model names from `/v1/models` rather than hard-coding.

## Quick test

```bash
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5",
    "messages": [{"role": "user", "content": "Say hello in one word."}]
  }'
```

## Errors & rate limits

Errors come back in the shape of whichever surface you called (OpenAI vs Anthropic vs Gemini) and always carry enough context to trace the request. The common status codes and the right way to react to each are in `references/errors.md` — read it before building retry logic.

Quick summary:
- **401** — missing/invalid `atp-` key.
- **402** `insufficient_quota` — balance/quota exhausted; don't retry until topped up. (Chat Gemini surface reports this as a native 429.)
- **429** — request rate exceeded (`Retry-After` tells you how long) or all providers in cooldown; back off.
- **403** — the model isn't in your allowed list (check `/v1/models`).
- **503** — all providers temporarily unavailable; retry after ~60s.
- **5xx from a provider** is passed through with the provider's status and message.

## File inputs

The gateway can store a file and give you a reference ID to use in later requests. See `references/files.md`.

## More

- `references/errors.md` — full status-code table and retry guidance.
- `references/files.md` — uploading and referencing files through the gateway.
