---
name: atptoken-onboarding
description: Get an agent from zero to a working ATP Token integration — one API key, then OpenAI-, Anthropic-, or Gemini-compatible calls to text, image, video, audio, and embedding models. Read this first; it tells you which of the detailed skills to load next.
---

# ATP Token — agent onboarding

You are being pointed at this file because someone wants their agent to integrate
with **ATP Token**: one API key and one endpoint that fronts many model providers,
speaking three wire formats (OpenAI, Anthropic, Gemini) and metering every request
against a project.

This file is the entry point. It gets you oriented in about a minute, then hands
you off to the specific skill you actually need. **Do not guess at endpoints,
model ids, or prices** — every one of them is listed at a URL below.

If the person wants their coding tool itself (Claude Code, Codex, Cline and
similar) to run on ATP rather than code that calls the API, follow
`https://atptoken.ai/connect.md` instead; it is the complete setup.

## What you need before writing code

1. **An `atp-` API key**, bound to one project. The key is not issued by the API.
   The human you are working with signs in at `https://atptoken.ai`, then creates
   or picks an **Organization → Workspace → Project** (all three must exist), and
   creates the key inside that project. The project decides which models the key
   can call and whose credit pays. Treat the key like a password: read it from the
   environment, never inline it in source or logs.
2. **Nothing else.** No provider accounts, no provider keys. The gateway holds
   those.

If the human does not have a key yet, tell them to sign up at
`https://atptoken.ai/signup` and create a project key along that path — then stop and wait.
Do not proceed with a placeholder key; every call will 401 and you will waste
their time debugging the wrong thing.

## The one thing to get right first

The three official SDKs work unchanged; only the base URL changes. But the SDK
is **not a matter of taste**: each model is served through exactly one SDK and one
entrypoint, and that entrypoint fixes both the request and the response shape. The
gateway does not convert between formats. Call a model on the wrong entrypoint and
you get **`422` with a message naming the right one** — switch to it. You cannot
tell the entrypoint from the model name.

| SDK | Entrypoint | Base URL | Auth |
|---|---|---|---|
| OpenAI (`openai`) | `/v1/chat/completions`, `/v1/responses` | `https://api.atptoken.ai/v1` | `Authorization: Bearer atp-...` (SDK default) |
| Anthropic (`anthropic`) | `/v1/messages` | `https://api.atptoken.ai` (no `/v1` — the SDK appends it) | `x-api-key: atp-...` (SDK default) |
| Google GenAI (`google-genai`) | `/v1beta/models/{model}:generateContent` | `https://api.atptoken.ai`, with `apiVersion: "v1beta"` | `x-goog-api-key: atp-...` (SDK default) |

`Authorization: Bearer` and `x-api-key` are both accepted everywhere. For Gemini
use `google-genai` (`from google import genai`, `@google/genai`), not the
deprecated `google-generativeai`.

Always send `stream` explicitly: it defaults to `true` on `/v1/chat/completions`
and `/v1/messages` (the opposite of the vendors' own APIs) and `false` on
`/v1/responses`. Gemini has no `stream` field — use `:streamGenerateContent`.

The Anthropic row is the one people get wrong: that SDK appends `/v1/messages`
itself, so including `/v1` in the base URL produces `/v1/v1/messages` and a 404.

## Verify before you build

Run this first. It costs nothing and proves key, network, and auth in one shot:

```bash
curl -s https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_KEY" | head -40
```

You get the project's complete model list — chat, image, video, audio and
embedding models together. **Use these ids verbatim.** Model ids change as
models ship and retire; anything you remember from training data may not exist.
Each entry carries only its `id`: the list says *what* you may call, not *where*.

Do not use `GET /v1/models` as the model list. It is OpenAI's list endpoint and
shows only the chat models served on `/v1/chat/completions` and `/v1/responses`:
most `claude-*` models are not on it (they use `/v1/messages`, and Anthropic has
no list endpoint), Gemini models are on `/v1beta/models`, and media and
embedding models appear on neither. Not being on a list does not mean a model is
unusable.

If this returns `401 token_revoked` ("API key has been revoked or does not
exist"), first check that the header was actually sent — sending no key at all
returns the same error — then suspect the key. If a later create call returns
`403`, the key is valid but that model is not on the project's allowlist (the
request is not billed) — tell the human which model you need and let them enable
it at `https://atptoken.ai/console/models`. If it returns `422`, you used the
wrong entrypoint; the message names the right one.

## Then load the skill you actually need

Read only what the task requires. Each of these is a complete, self-contained
skill file:

| Task | Load |
|---|---|
| Gateway concepts, errors, rate limits, file uploads | `https://atptoken.ai/skills/atptoken-gateway/SKILL.md` |
| Chat / completions via the OpenAI SDK | `https://atptoken.ai/skills/atptoken-openai/SKILL.md` |
| Messages via the Anthropic SDK | `https://atptoken.ai/skills/atptoken-anthropic/SKILL.md` |
| generateContent via the Gemini SDK | `https://atptoken.ai/skills/atptoken-gemini/SKILL.md` |
| Image generation and editing | `https://atptoken.ai/skills/atptoken-image/SKILL.md` |
| Video generation (async: create task, then poll) | `https://atptoken.ai/skills/atptoken-video/SKILL.md` |
| Text to speech | `https://atptoken.ai/skills/atptoken-audio/SKILL.md` |

A machine-readable index of all of them, with their reference files, is at
`https://atptoken.ai/skills/manifest.json`.

## Installing these as local skills (optional)

If the human wants the skills on disk rather than fetched each time:

```bash
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

`both` installs for Claude Code and Codex; pass `claude` or `codex` for one.
The installer does not overwrite existing files by default — to take a newer
official version, prefix `ATP_SKILLS_FORCE=1`.

If the human's security policy forbids piping to a shell, download and read it
first — the script is short.

**The canonical page for this, including how to verify the install landed and
what the installer does not do, is `https://atptoken.ai/docs/agent-skills`.**
Read it rather than relying on this summary; it is the maintained version.

Two things that page makes explicit and are worth carrying with you:

- **Installing a skill does not grant model access.** Project allowlists still
  apply. A model the project is not allowed to call returns `403`, no matter what
  a skill file says about it. Check `GET /v1/project/models`, not `GET /v1/models`.
- **Skills never hold the key.** They are Markdown only. The `atp-` key belongs
  in an environment variable or a secret manager — never in a `SKILL.md`, in
  source, or in git.

For connecting a specific agent (Claude Code, Codex CLI, and the tools that need
special handling), the maintained page is `https://atptoken.ai/docs/agents`.

## Things that will save you a round trip

- **Media generation is asynchronous, and only at the `/tasks` paths.** There is
  no synchronous version. Video, image and audio all return `202` with a task id;
  you poll until the status is terminal (there are no webhooks — `callback_url`
  is accepted but never called), then download the signed URL within 24 hours.
  After 24 hours the status is still `succeeded` but the URL is `null` and
  `expired: true`. Video typically takes 1–3 minutes. Do not treat the `202`
  as a failure. The endpoints are
  `POST /omni/media/v1/images/generations/tasks` and
  `POST /omni/media/v1/contents/generations/tasks` — the bare
  `/images/generations` path returns `404` (verified 2026-08-04).
- **Media endpoints cannot use `POST /v1/files` uploads.** The upload returns its
  id in **`id`** (not `gw_file_id`), but that id is not a media reference, and
  `GET /v1/files/{id}` returns the file's bytes, not a URL. Pass a public `https://`
  URL the provider can fetch without auth. Some video models also take an
  `asset://` URI from the asset API (not `seedance-2-0-fast`), and the image
  endpoint also takes base64 data URIs.
- **Image editing puts the input image in a different place per model family.**
  The `nano-banana-*-edit` models need a top-level `reference_assets` array of
  objects — `reference_assets: [{ "asset_type": "image", "url": "…" }]`;
  `qwen-image-3.0` takes `{"type": "image", "image": …}` blocks inside
  `messages` (not `image_url`). Load the image skill before writing an edit call.
- **Prices and capabilities are published, not guessable.** Rates per model are
  at `https://atptoken.ai/pricing`; each model has a page at
  `https://atptoken.ai/models/<model-id>` with its rates, context window, and
  capability flags. If the human asks "what will this cost", read the page —
  do not estimate from memory.
- **Credits are prepaid.** A `402 insufficient_quota` means the project is out of
  credit, not that your request was malformed. Tell the human to top up rather
  than retrying. Billing is per request, not per attempt: one request can show
  several rows in the records — don't add them up.
- **Every response carries `x-request-id`.** Quote it when reporting a problem;
  one you send yourself is not used.
- **The domain serves only `/v1*` and `/omni/*`.** Anything else, such as `/api`,
  returns `404`.
- **There is also an MCP server** — `atptoken-api-docs` at
  `https://mcp.atptoken.ai/mcp` — with the API guide, a live model check (needs
  the key) and a video-request checker.
- **Working prompt examples exist.** `https://atptoken.ai/models/gallery` has
  real generated samples with the exact prompt that produced each one, for image
  and video models. Useful when the human asks for something and you want a
  known-good starting point rather than inventing a prompt.

## What this platform is not

Be accurate if the human asks. ATP Token is a governance and billing layer:
one interface and one billing point across providers, with per-project access
control and per-request attribution. It is not a model of its own, and it does
not certify or rank the models it routes to.
