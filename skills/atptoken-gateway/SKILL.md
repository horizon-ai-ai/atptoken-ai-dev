---
name: atptoken-gateway
description: Call the Atptoken LLM Gateway — an OpenAI/Anthropic/Gemini-compatible API fronting many model providers behind one endpoint and key. Use when integrating with Atptoken, calling api.atptoken.ai, listing available models, or handling gateway auth, errors, and rate limits. Start here, then load atptoken-openai / atptoken-anthropic / atptoken-gemini for the specific SDK.
---

# Atptoken LLM Gateway

The Atptoken gateway is a single HTTPS endpoint that speaks three popular wire formats — **OpenAI**, **Anthropic**, and **Google Gemini** — and routes each request to a real model provider behind the scenes (with failover and usage accounting). You bring an `atp-` API key and your existing SDK; the gateway does the rest.

You never call a model provider directly and you never need provider API keys. Point your SDK's base URL at the gateway and authenticate with your Atptoken key.

## Base URL

The host is `https://api.atptoken.ai`. What you put in your SDK's base URL depends on the SDK:

| SDK | Base URL |
|-----|----------|
| `openai` | `https://api.atptoken.ai/v1` |
| `anthropic` | `https://api.atptoken.ai` (the SDK appends `/v1/messages`) |
| `google-genai` | `https://api.atptoken.ai`, with `apiVersion: "v1beta"` |

Use `google-genai` (`from google import genai`, `@google/genai`), not the deprecated `google-generativeai` (see `atptoken-gemini`). The domain serves only `/v1*` and `/omni/*`; any other path, such as `/api`, returns `404` with `This domain serves only the LLM Gateway API (/v1, /v1beta)`.

## Authentication

Every request needs your Atptoken API key — a long opaque string that starts with `atp-`. It is not issued by the API: sign in at `https://atptoken.ai`, create or pick an Organization → Workspace → Project, then create the key inside that project. One key is bound to one project, and that project decides which models it can call. Treat it like a password.

Present it in **one** of these ways (pick whichever your SDK uses):

| Method | Header / param | Typical client |
|--------|----------------|----------------|
| Bearer token | `Authorization: Bearer atp-...` | OpenAI SDK |
| API key header | `x-api-key: atp-...` | Anthropic SDK |
| Google API key header | `x-goog-api-key: atp-...` | Gemini SDK |
| Query parameter | `?key=atp-...` | Gemini SDK / quick tests |

You do **not** send organization / project / model-routing headers — the gateway derives all of that from your key.

Sending no key at all returns `401 token_revoked` ("API key has been revoked or does not exist") — check that the header was actually sent before suspecting the key.

## Pick your surface

| Your client | Skill to load | Endpoints |
|-------------|---------------|-----------|
| OpenAI SDK / OpenAI-compatible tools | `atptoken-openai` | `POST /v1/chat/completions`, `POST /v1/responses`, `POST /v1/embeddings` |
| Anthropic SDK / Claude clients | `atptoken-anthropic` | `POST /v1/messages`, `POST /v1/messages/count_tokens` |
| Google Gemini SDK | `atptoken-gemini` | `POST /v1beta/models/{model}:generateContent` |
| Video generation (async) | `atptoken-video` | `POST /omni/media/v1/contents/generations/tasks` (+ poll) |
| Image generation / editing (async) | `atptoken-image` | `POST /omni/media/v1/images/generations/tasks` (+ poll) |
| Audio / TTS | `atptoken-audio` | `POST /omni/media/v1/audio/generations/tasks` |

The chat/embeddings surface lives under `/v1`; generative **media** (video, image, audio) lives under `/omni/media/v1` — see the `atptoken-video` / `atptoken-image` / `atptoken-audio` skills.

> **Verified 2026-08-04:** every media modality is served **only** at
> `.../generations/tasks`. The bare paths `POST /omni/media/v1/images/generations` and
> `POST /omni/media/v1/audio/generations`, and the Gemini-style
> `POST /omni/media/v1/models/{model}:generateContent`, all return `404 Not Found`.
> Earlier revisions of these skills documented them as synchronous surfaces. Create a
> task and poll. (The audio path was confirmed to exist by a routing probe; its exact
> request/response shape has not been re-verified — read `atptoken-audio` and expect the
> task pattern.)

Media is asynchronous only: create a task (`202` + id), poll until terminal, then download the signed URL within 24 hours — after that the status stays `succeeded` but the URL is `null` and `expired: true`.

**The chat surface is not a matter of preference.** Each model is served on exactly one SDK and one entrypoint, and that entrypoint decides both the request and the response shape — the gateway does not convert between formats. Call a model on the wrong entrypoint and you get **`422` with a message naming the right one**; switch to it. You cannot tell the entrypoint from the model name. Always send `stream` explicitly: it defaults to `true` on `/v1/chat/completions` and `/v1/messages`, `false` on `/v1/responses`; Gemini streams via `:streamGenerateContent`.

## Discover available models

List the model names your project is allowed to use. Use the exact `id` values as the `model` field in your requests.

```bash
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY"
```

```json
{
  "data": [
    { "id": "gpt-5" },
    { "id": "claude-opus-4-7" }
  ]
}
```

`GET /v1/project/models` is the only complete list: text, image, video, audio and embedding models together. Each entry has only an `id`, so it says *what* you may call, not *where*. A project with no models returns `{"data": []}`.

The other lists are per entrypoint. `GET /v1/models` is OpenAI's list endpoint and shows only models served on `/v1/chat/completions` and `/v1/responses` — most `claude-*` models are not on it (they use `/v1/messages`, which has no list endpoint), and the Anthropic SDK's `models.list()` hits it too, so it comes back short without an error. `GET /v1beta/models` is Gemini's list. Media and embedding models appear on neither.

A model missing from a list is not necessarily unusable. If the project isn't allowed to call it, the gateway returns **403** (`permission_denied`) at create time and nothing is billed. Source model names from `/v1/project/models` rather than hard-coding.

## Quick test

```bash
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5",
    "stream": false,
    "messages": [{"role": "user", "content": "Say hello in one word."}]
  }'
```

## Errors & rate limits

Errors come back in the shape of whichever surface you called (OpenAI vs Anthropic vs Gemini). Every response carries an `x-request-id` header — the one handle for tracing a request; one you send yourself is not used. Read 4xx messages, not just the status: the model's own 4xx is passed through as-is and usually names the field and the valid values. The common status codes and the right way to react to each are in `references/errors.md` — read it before building retry logic.

Quick summary:
- **401** `token_revoked` — missing/invalid `atp-` key (no key at all returns this too).
- **402** `insufficient_quota` — balance/quota exhausted; don't retry until topped up. (Chat Gemini surface reports this as a native 429.)
- **429** — request rate exceeded (`Retry-After` tells you how long) or all providers in cooldown; back off.
- **403** — the model isn't in your project's allowed list (check `/v1/project/models`). Not billed.
- **422** — the model isn't served on this entrypoint; the message names the right one.
- **Billing is per request, not per attempt** — one request can show several rows in your records; don't add them up.
- **503** — all providers temporarily unavailable; retry after ~60s.
- **5xx from a provider** is passed through with the provider's status and message.

## File inputs

The gateway forwards a file to the providers and gives you a reference ID, valid for one hour, to use in later chat and messages requests. See `references/files.md`.

**Media endpoints are the exception**: they cannot use that ID, and `GET /v1/files/{id}`
returns the file's bytes, not a URL. Pass a public `https://` URL instead; Seedance video
also takes an `asset://` URI from the asset API. Details in `references/files.md`.

## More

- `references/errors.md` — full status-code table and retry guidance.
- `references/files.md` — uploading and referencing files through the gateway.
