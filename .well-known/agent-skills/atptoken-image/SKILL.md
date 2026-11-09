---
name: atptoken-image
description: Generate and edit images through the Atptoken LLM Gateway media surface at /omni/media/v1. Asynchronous — POST /omni/media/v1/images/generations/tasks returns 202 + a task id; poll until terminal, then download data[].url within 24 hours. Every field except model is forwarded as-is, so each model family has its own parameter names (nano-banana image_size/num_images, qwen-image nested parameters with 1024*1024 sizes, gpt-image-2 size/quality/n) and its own place for edit input images (nano-banana -edit reference_assets, qwen-image messages). Use for nano-banana / qwen-image / gpt-image-2 and other image models via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken image generation

Image generation is **asynchronous** and has no synchronous version: create a task
(`202` + an `img_…` id), poll until the status is terminal, then download
`data[].url` before it expires.

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` (or `x-api-key: atp-...`) + `Content-Type: application/json`
- **Model:** an image model name, e.g. `nano-banana-pro` (a safe default),
  `nano-banana-pro-edit`, `qwen-image-3.0`, `gpt-image-2`.

**Which models can this key use?** `GET /v1/project/models` is the complete list for
the key's project — every model, any modality, each entry just an `id`.
`GET /v1/models` is OpenAI's list endpoint and shows only openai-dialect chat models;
**image models are never on it**. Not being on a list does not mean unusable: send the
request — an unauthorized model is refused at create with `403 permission_denied`, and
you are not billed.

**Output delivery:** a succeeded task carries `data[].url` — a signed URL
`https://media-<env>.atptoken.ai/v/...?exp=&sig=` valid for **24 hours**, never inline
base64. Download it to keep it; don't store the URL as a permanent link.

**No webhooks:** `callback_url` is accepted but never called. You must poll.

**Balance gate:** refused with `402 insufficient_quota` when the project balance is ≤ 0.
The balance check happens **before** body validation, so a 402 tells you nothing about
whether your payload was correct.

## There is only the async task surface

| Method | Path | Action |
|---|---|---|
| `POST` | `/omni/media/v1/images/generations/tasks` | create → `202 { "id": "img_..." }` |
| `GET` | `/omni/media/v1/images/generations/tasks/{id}` | poll status/result (`404` if not found or not yours) |
| `GET` | `/omni/media/v1/images/generations/tasks` | list your project's tasks |
| `DELETE` | `/omni/media/v1/images/generations/tasks/{id}` | `queued` → cancelled; terminal → record deleted; `running` → `409` |

**Do not call these — they return `404 Not Found` (verified 2026-08-04):**

- `POST /omni/media/v1/images/generations` (no synchronous image surface exists)
- `POST /omni/media/v1/models/{model}:generateContent` (no Gemini-native surface on
  the media base URL)

## Rule zero: fields are forwarded verbatim, and unknown fields are silently ignored

Except `model`, every field you send is **forwarded under its own name and value** —
there is no parameter translation. A field the model doesn't recognize is **dropped
silently**: the create still returns `202` and an image is still produced, just not the
one you asked for. "No error" does not mean "read".

| You send | On | Result |
|---|---|---|
| `size: "1024x1024"` | `nano-banana*` | ignored — use `image_size` + `aspect_ratio` |
| top-level `size: "1024*1024"` | `qwen-image-3.0` | ignored — it reads only `parameters.size` |
| `n: 4` | `nano-banana*` | ignored — use `num_images` |

Confirm a parameter took effect by **comparing the output**. A value the model
**recognizes but rejects** comes back as a 4xx passed through verbatim, naming the field
and valid values — read it.

`prompt` is required by most models. The minimum is one of: `prompt`, an image-input
field (`reference_assets` / `image` / `face_image` …), or an image block in `messages`;
none of them → `400`.

## Text to image

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "nano-banana-pro", "prompt": "an isometric paper-craft city at golden hour",
        "aspect_ratio": "16:9", "image_size": "2K", "num_images": 2, "output_format": "png" }'
# → 202 { "id": "img_..." }
```

**Idempotency:** reuse the same `Idempotency-Key` when retrying a create after a
network failure; use a fresh key for a genuinely new task. Keys are per media surface —
reusing an image key on video or audio (or the reverse) returns `409`.

### nano-banana family

`nano-banana`, `nano-banana-2`, `nano-banana-pro`, `nano-banana-edit`,
`nano-banana-2-edit`, `nano-banana-pro-edit`.

| Field | Type | Notes |
|---|---|---|
| `prompt` | string | required (including `-edit`) |
| `aspect_ratio` | string | `auto` `21:9` `16:9` `3:2` `4:3` `5:4` `1:1` `4:5` `3:4` `2:3` `9:16` `4:1` `1:4` `8:1` `1:8` |
| `image_size` | string | `1K` / `2K` / `4K` — **`-pro` and `-2` only**; also the billing tier |
| `num_images` | int | 1–4 — **`-pro` and `-2` only** |
| `output_format` | string | `jpeg` / `png` / `webp` |
| `seed` | number | `-1` = random |
| `safety_tolerance` | string | `1`–`6`, default `6` |
| `enable_web_search` | bool | **`-pro` and `-2` only** |
| `thinking_level` | string | `minimal` / `high` — **`-2` only** |
| `reference_assets` | array | `[{ "asset_type": "image", "url": … }]`, up to 14 on `nano-banana-2*`, 10 on `nano-banana*` and `nano-banana-pro*` — **required on `-edit`** |

`size` / `quality` / `n` have no effect on this family.

### qwen-image-3.0 / qwen-image-3.0-pro

The **only** models whose parameters are not top-level: they read a nested
`parameters` object and silently ignore same-named top-level fields.

| Field (inside `parameters`) | Notes |
|---|---|
| `size` | **asterisk** format `1024*1024` (not `1024x1024`). Area 512×512 – 2560×2560; outside that the task fails naming the actual area. Sets the billing tier (1k/2k/4k). Default 2048×2048 |
| `n` | number of images — **each one is billed** |
| `prompt_extend` | **defaults to `true`**: the model rewrites your prompt (`rewrite_status: "success"`). Send `false` to keep yours |
| `watermark` | bool |

```json
{ "model": "qwen-image-3.0",
  "prompt": "a red square on a white background",
  "parameters": { "size": "1024*1024", "n": 1, "prompt_extend": false } }
```

### gpt-image-2 / gpt-image-2-edit

OpenAI Images vocabulary: `prompt` (required), `size` (**x** format, e.g. `1024x1024`),
`quality`, `n` (default 1), `output_format` (`png` default, `jpeg`, `webp`). `gpt-image-2-edit` also **requires** `images`: 1–4 items shaped `[{ "image_url": … }]`.

### face-swap

Takes no text. `image` (base image), `face_image` (**required** — the face to swap in;
its presence waives `prompt`), `seed`. Sending only `image` does **not** waive
`prompt` — you get "prompt is required".

### Models with no documented parameters

`qwen-image-edit-spicy`, `wan-2-7-image`, `wan-2-7-pro-image`, `z-image-spicy`. Do not
invent a plausible field set. Send `model` + `prompt` (+ your input image), read the
response: recognized-but-rejected fields come back as a 4xx naming the field and valid
values. A field that "worked" may still have been ignored — compare outputs.

## Image editing — the input image goes somewhere different per family

| Model | Input image goes in | Shape |
|---|---|---|
| `nano-banana-edit`, `nano-banana-2-edit`, `nano-banana-pro-edit` | top-level `reference_assets` | `[{ "asset_type": "image", "url": … }]`, ≤ 14 on `nano-banana-2-edit`, ≤ 10 on the other two, **required** |
| `qwen-image-3.0`, `qwen-image-3.0-pro` | a content block in `messages` | `{ "type": "image", "image": "<data URI or URL>" }` — **not** `image_url` |
| `gpt-image-2-edit` | top-level `images` | `[{ "image_url": … }]`, 1–4, **required**. `reference_assets` is accepted at create but the task fails at poll |
| `face-swap` | `image` + `face_image` | see above |

### nano-banana `-edit`: top-level `reference_assets`

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-edit-001" \
  -d '{
    "model": "nano-banana-pro-edit",
    "prompt": "Background: a sunlit marble kitchen counter. Preserve the product exactly — same shape, label text, colors and proportions as the reference.",
    "reference_assets": [
      { "asset_type": "image", "url": "https://example.com/product.png" }
    ],
    "aspect_ratio": "16:9",
    "image_size": "2K",
    "output_format": "png"
  }'
```

Rejected shapes (verified 2026-08-04):

| You send | Result |
|---|---|
| `content: [{ type: "image_url", ... }]` | `422 Invalid input.reference_assets: required.` |
| `image: "https://…"` | `422 Invalid input.reference_assets: required.` |
| `image_url: { url: "…" }` | `422 Invalid input.reference_assets: required.` |
| `reference_assets: ["https://…"]` (strings) | `422 Invalid input.reference_assets` |

### What `url` accepts in `reference_assets`

| Form | Image endpoint | Notes |
|---|---|---|
| public `https://…` URL | **works** | the upstream must be able to fetch it **without auth** |
| `data:image/png;base64,…` | **works** | whole payload travels in the request body; keep the base64 under 2 MB, larger payloads can fail upstream |
| `asset://<id>` or `asset://<pid>.<id>` | **NOT SUPPORTED** | fails at generation with `provider_error / generation_failed` |

A file uploaded to `POST /v1/files` cannot be used either: its `an_<ulid>` is a chat
file id, not a media reference, and `GET /v1/files/{id}` returns bytes, not a URL. To
use a local image, host it at a public `https://` URL, or send a small image as a
`data:` URI.

### qwen-image edit: `messages`

```json
{ "model": "qwen-image-3.0",
  "parameters": { "size": "1024*1024", "n": 1, "prompt_extend": false },
  "messages": [{ "role": "user", "content": [
    { "type": "image", "image": "data:image/png;base64,…" },
    { "type": "text",  "text": "make the square blue" } ] }] }
```

If you send `messages`, yours are used; a `prompt` sent alongside is appended as a
separate final user message — neither is dropped. Do **not** send qwen input images in
`reference_assets` or as `image_url` blocks.

### Multi-image edits

`nano-banana-2-edit` accepts up to 14 `reference_assets` (`nano-banana-edit` and `nano-banana-pro-edit` up to 10), and the prompt can refer to
them as "Image 1", "Image 2", …. Treat cross-image instructions as **unverified**: in a
single production test (2026-08-04) a two-reference cross-composition instruction was
accepted, rendered and billed, but the instruction was not carried out — the output
kept the first reference's own background. Generate one cheap sample and look at it
before running a batch.

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

- `status` ∈ `queued | running | succeeded | failed | expired | cancelled`; the last
  four are terminal. **Break on all four** — a loop that waits only for `succeeded`
  spins forever on `failed`.
- **`succeeded` does not guarantee a file.** After 24 hours the task still reports
  `succeeded`, but `data[].url` is `null` and `expired: true` is set. Check the URL for
  `null` after checking the status.
- `data` is an array (one URL per image) — walk all of it.
- `meters` lists what the task was actually metered on; per-image models have no
  tokens, so read `meters` rather than `usage` for them.
- `status: "failed"` → `error: { code, message }`, plus `upstream_status` when the
  failure carried an HTTP status.
- **Value errors surface on poll, not at create**, for the `nano-banana` family,
  `gpt-image-2` and `qwen-image`: create validates only the shape (model exists,
  something to generate). Example qwen size error:
  `{"code":"upstream_400","upstream_status":400,"message":"Image area must be between …"}`.
  `kling-*` models instead fail at create, with the status code passed through
  unchanged and a body of `{error:{code,type,message,retryable}}`.

**The extension in `data[].url` is not a format signal** (verified 2026-08-04): a URL
ending `.png` can carry JPEG bytes. If you re-upload or convert the result, sniff the
magic number instead of trusting the filename.

## Billing by size tier

- `nano-banana-pro` / `nano-banana-2`: the tier is the `image_size` you send.
- `qwen-image-3.0` family: the tier comes from `parameters.size` (1k/2k/4k); every image
  from `n` is billed.
- Other per-image models: billed by the **longest side of the image actually
  delivered**: ≤ 1024 px → `1K`, ≤ 2048 px → `2K`, larger → `4K`. A model's default
  output can be wider than you asked for (a 1408×768 result bills at `2K`), and some
  models ignore `size` entirely — read the returned dimensions if cost matters.

Only delivered images are billed. Never quote prices from memory — see the pricing page.

## Errors

Read 4xx messages: the model's own 4xx is passed through verbatim and usually names the
field and valid values. Quote the response's `x-request-id` when reporting a problem.

| Status | Meaning | Action |
|---|---|---|
| `400` | missing `model`, or neither a prompt nor an image input | read the message |
| `401` `token_revoked` | bad key — **also what you get when no key was sent** | check the header actually went out |
| `402` | `insufficient_quota` (balance exhausted; checked **before** validation), or the model's own 402 passed through | not a transient limit — **don't retry**; top up first |
| `403` `permission_denied` | model is restricted; your project isn't on its allow-list | not a key or balance problem; switch models or ask an admin. Not billed |
| `404` | task not found / not yours — **or you called a non-existent endpoint (see above)** | check id and path |
| `409` | `Idempotency-Key` already used for a task on another media surface; or DELETE on a `running` task | use a new key |
| `422` | the model has no available capacity, or the model's own `validation_error` naming field + valid values | switch models / fix the field |
| `429` | the model is rate-limited | `retryable` says whether to retry; back off |
| `500` | the model's own 5xx, passed through (not folded into 502) | — |
| `502` | no response from the model (timeout, connection failure, unparseable body) | retryable |
| `503` | task could not be queued, or `balance_check_unavailable` (balance **read** failed — not insufficient; nothing started, nothing charged) | retryable |

For video or audio see the **atptoken-video** / **atptoken-audio** skills; for auth and
the cross-surface error table see **atptoken-gateway**.
