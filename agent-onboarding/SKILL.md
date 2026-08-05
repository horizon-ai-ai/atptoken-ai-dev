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

## What you need before writing code

1. **An `atp-` API key**, scoped to one project. The human you are working with
   creates it at `https://atptoken.ai/console/keys`. Treat it like a password:
   read it from the environment, never inline it in source or logs.
2. **Nothing else.** No provider accounts, no provider keys. The gateway holds
   those.

If the human does not have a key yet, tell them to sign up at
`https://atptoken.ai/signup` and create a project key — then stop and wait.
Do not proceed with a placeholder key; every call will 401 and you will waste
their time debugging the wrong thing.

## The one thing to get right first

Pick the wire format that matches the SDK already in the project, and point its
base URL at the gateway. You do **not** rewrite the project's SDK calls.

| SDK in the project | Base URL | Auth |
|---|---|---|
| OpenAI (`openai`) | `https://api.atptoken.ai/v1` | `Authorization: Bearer atp-...` |
| Anthropic (`anthropic`) | `https://api.atptoken.ai` (no `/v1` — the SDK appends it) | `Authorization: Bearer atp-...` |
| Google Gemini | `https://api.atptoken.ai` | `x-goog-api-key: atp-...` |

The Anthropic row is the one people get wrong: that SDK appends `/v1/messages`
itself, so including `/v1` in the base URL produces `/v1/v1/messages` and a 404.

## Verify before you build

Run this first. It costs nothing and proves key, network, and auth in one shot:

```bash
curl -s https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_KEY" | head -40
```

You get the live model list. **Use these ids verbatim** — they are the only
authoritative source. Model ids change as models ship and retire; anything you
remember from training data may not exist.

If this returns 401, the key is wrong or revoked. If it returns 200 but a later
generation call returns 403, the key is valid but that model is not on the
project's allowlist — tell the human which model you need and let them enable it
at `https://atptoken.ai/console/models`.

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
  apply. A model absent from `GET /v1/models` cannot be called, no matter what
  a skill file says about it.
- **Skills never hold the key.** They are Markdown only. The `atp-` key belongs
  in an environment variable or a secret manager — never in a `SKILL.md`, in
  source, or in git.

For connecting a specific agent (Claude Code, Codex CLI, and the tools that need
special handling), the maintained page is `https://atptoken.ai/docs/agents`.

## Things that will save you a round trip

- **Media generation is asynchronous, and only at the `/tasks` paths.** Image and
  video both return `202` with a task id; you poll until the status is terminal,
  then read a signed URL. Video typically takes 1–3 minutes. Do not treat the `202`
  as a failure. The endpoints are
  `POST /omni/media/v1/images/generations/tasks` and
  `POST /omni/media/v1/contents/generations/tasks` — the bare
  `/images/generations` path returns `404` (verified 2026-08-04).
- **Uploaded files cannot be referenced with `asset://` on media endpoints**
  (verified 2026-08-04). `POST /v1/files` returns the id in **`id`** (not
  `gw_file_id`); to use that file as a first frame or an edit reference, call
  `GET /v1/files/{id}` **without following the redirect** and pass the `Location`
  header — a no-auth presigned URL, ~15-minute TTL. Base64 data URIs work on
  **both** the image and the video endpoints (verified 2026-08-05), so an upload
  is only needed when the file is not already reachable by URL.
- **Image editing puts its input images in a top-level `reference_assets`
  array of objects** — `reference_assets: [{ "url": "…" }]`. Putting them in
  `content[]`, `image`, or `image_url` fails with `422`, and a bare array of URL
  strings fails too (verified 2026-08-04). Load the image skill before writing an
  edit call.
- **Prices and capabilities are published, not guessable.** Rates per model are
  at `https://atptoken.ai/pricing`; each model has a page at
  `https://atptoken.ai/models/<model-id>` with its rates, context window, and
  capability flags. If the human asks "what will this cost", read the page —
  do not estimate from memory.
- **Credits are prepaid.** A `402 insufficient_quota` means the project is out of
  credit, not that your request was malformed. Tell the human to top up rather
  than retrying.
- **Working prompt examples exist.** `https://atptoken.ai/models/gallery` has
  real generated samples with the exact prompt that produced each one, for image
  and video models. Useful when the human asks for something and you want a
  known-good starting point rather than inventing a prompt.

## What this platform is not

Be accurate if the human asks. ATP Token is a governance and billing layer:
one interface and one billing point across providers, with per-project access
control and per-request attribution. It is not a model of its own, and it does
not certify or rank the models it routes to.
