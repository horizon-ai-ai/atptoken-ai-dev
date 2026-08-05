---
name: atptoken-image
description: Generate and edit images through the Atptoken LLM Gateway media surface at /omni/media/v1. Asynchronous — POST /omni/media/v1/images/generations/tasks returns 202 + a task id; poll until terminal, then download the signed URL. Edit-style models take their input images in a top-level reference_assets array. Use for nano-banana / gpt-image-2 and other image models via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken image generation

Image generation is **asynchronous**: create a task (`202` + task id), poll until the
status is terminal, then download the signed URL. The gateway routes your unified
`model` to a real image provider from the `image` pool.

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` + `Content-Type: application/json`
- **Model:** a unified image model name — confirm with `GET /v1/models`. Examples:
  `gpt-image-2`, `nano-banana-pro`, `nano-banana-pro-edit`.

**Output delivery:** a succeeded task carries `data[].url` — a signed edge URL
`https://media-<env>.atptoken.ai/v/...?exp=&sig=` with a **30-minute TTL**, never
inline base64. Fetch it promptly.

**Balance gate:** refused with `402 insufficient_quota` when the project balance is ≤ 0.
The balance check happens **before** body validation, so a 402 tells you nothing about
whether your payload was correct.

> **Verified 2026-08-04 against production `api.atptoken.ai`.** Everything marked
> "verified" below was confirmed by direct calls. Do not "try anyway" — you will only
> spend calls reproducing a known failure.

## There is only the async task surface

| Method | Path | Action |
|---|---|---|
| `POST` | `/omni/media/v1/images/generations/tasks` | create → `202 { "id": "img_..." }` |
| `GET` | `/omni/media/v1/images/generations/tasks/{id}` | poll status/result |
| `GET` | `/omni/media/v1/images/generations/tasks` | list your tasks |
| `DELETE` | `/omni/media/v1/images/generations/tasks/{id}` | cancel |

**Do not call these — they return `404 Not Found` (verified 2026-08-04):**

- `POST /omni/media/v1/images/generations` (no synchronous image surface exists)
- `POST /omni/media/v1/models/{model}:generateContent` (no Gemini-native surface on
  the media base URL)

An earlier revision of this skill documented both. They are gone; use the task
endpoints above.

## Text to image

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "n": 1 }'
# → 202 { "id": "img_..." }
```

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `model` | string | ✅ | unified image model (`image` pool) |
| `prompt` | string | ✅ | required on **every** call, edit-style models included |
| `reference_assets` | array | | input images for edit-style models — see below |
| `size` | string | | e.g. `1024x1024`; some models ignore it |
| `quality` | string | | forwarded to OpenAI-dialect upstreams |
| `n` | int | | number of images, 1–4 (default `1`) |

**Idempotency:** reuse the same `Idempotency-Key` when retrying a create after a
network failure; use a fresh key for a genuinely new task.

## Image editing — input images go in top-level `reference_assets`

**This is the single most common way to fail an edit call.** The input images are a
**top-level array of objects**:

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-edit-001" \
  -d '{
    "model": "nano-banana-pro-edit",
    "prompt": "Background: a sunlit marble kitchen counter. Preserve the product exactly — same shape, label text, colors and proportions as the reference.",
    "n": 1,
    "reference_assets": [
      { "url": "https://example.com/product.png" }
    ]
  }'
```

Rejected shapes (all verified 2026-08-04):

| You send | Result |
|---|---|
| `content: [{ type: "image_url", ... }]` | `422 Invalid input.reference_assets: required.` |
| `image: "https://…"` | `422 Invalid input.reference_assets: required.` |
| `image_url: { url: "…" }` | `422 Invalid input.reference_assets: required.` |
| `reference_assets: ["https://…"]` (strings) | `422 Invalid input.reference_assets` |
| `reference_assets: [{ url: "https://…" }]` | **accepted** |

### What `url` accepts

| Form | Image endpoint | Notes |
|---|---|---|
| public `https://…` URL | **works** | the upstream must be able to fetch it **without auth** |
| `data:image/png;base64,…` | **works** | whole payload travels in the request body |
| `asset://<id>` or `asset://<pid>.<id>` | **NOT SUPPORTED** | fails at generation with `provider_error / generation_failed` |

`asset://` was previously documented as valid. It is not, on either the image or the
video endpoint. Eight calls across both spellings and both endpoints all failed.
**Do not attempt it.**

To use a file you uploaded to `POST /v1/files`, resolve it to a no-auth URL — read the
`Location` header of `GET /v1/files/{id}` **without following the redirect**:

```bash
FILE_ID=$(curl -s https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATP_KEY" -F "file=@./product.png" | jq -r .id)
# NOTE: the response key is `id`, not `gw_file_id`.

REF_URL=$(curl -sD - -o /dev/null "https://api.atptoken.ai/v1/files/$FILE_ID" \
  -H "Authorization: Bearer $ATP_KEY" | grep -i '^location:' | cut -d' ' -f2 | tr -d '\r')
# presigned object-store URL, no auth needed, ~15-minute TTL — resolve it right
# before creating the task; do not cache it.
```

## Poll until terminal

Poll every 3–8 seconds:

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
```

```json
{ "status": "succeeded",
  "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ],
  "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

- `status` ∈ `queued | running | succeeded | failed | cancelled | expired`
- `data[].url` is signed with a 30-minute TTL; after expiry the task still reports
  `succeeded` but with `expired: true` and a null `url`
- `status: "failed"` → a structured `error` object explains the upstream failure

**The extension in `data[].url` is not a format signal** (verified 2026-08-04): a URL
ending `.png` can carry JPEG bytes. If you re-upload or convert the result, sniff the
magic number instead of trusting the filename.

### Multi-image edits

Some edit models accept several `reference_assets` entries and let the prompt refer to
them as "Image 1", "Image 2", …. Treat that as **unverified**: in a single production
test (2026-08-04) a two-reference cross-composition instruction was accepted, rendered
and billed, but the instruction was not carried out — the output kept the first
reference's own background. Generate one cheap sample and look at it before running a
batch.

An earlier revision of this skill documented `qwen-image-edit-max` with an `images: [...]`
array of URL strings. That was written against the synchronous endpoint that does not
exist, and the model is not in the current `GET /v1/models` catalogue. If a Qwen edit
model is enabled for your project, send `reference_assets: [{ url }]` like every other
edit model.

## Billing by size tier

Per-image models are billed by the **longest side of the image actually delivered**:
≤ 1024 px → `1K`, ≤ 2048 px → `2K`, larger → `4K`. A model's default output can be
wider than you asked for (a 1408×768 result bills at `2K`), and some models ignore
`size` entirely — read the returned dimensions if cost matters. Only delivered images
are billed.

## Errors

| Status | Meaning |
|---|---|
| `400` | missing `model` or `prompt` |
| `402` `insufficient_quota` | project balance ≤ 0 — top up and retry (don't hammer). Checked **before** validation |
| `404` | task not found / not yours — **or you called a non-existent endpoint (see above)** |
| `422` | the model has no image provider, or the body failed validation (e.g. `reference_assets`) |
| `502` | upstream generation failed |

Model names are configuration — confirm the live catalogue with `GET /v1/models`. For
video or audio see the **atptoken-video** / **atptoken-audio** skills; for auth and the
cross-surface error table see **atptoken-gateway**.
