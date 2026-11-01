---
name: atptoken-video
description: Generate video (text-to-video / image-to-video) through the Atptoken LLM Gateway media surface at /omni/media/v1. Video is asynchronous — create a task, poll until it succeeds, then fetch a short-lived signed URL. Two client dialects (ModelArk-compatible and DashScope-native). Use for Seedance / Wan and other video models via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken video generation

Video generation is **asynchronous**: you create a task (`202` + task id), poll until the status is terminal, then read a short-lived signed URL for the output. The gateway routes your unified `model` to a real video provider (Seedance, Wan, …) from the `video` pool, with same-name failover.

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` + `Content-Type: application/json`
- **Model:** a unified video model name — confirm with `GET /v1/models`. Examples: `seedance-2-0`, `seedance-2-0-mini`, `wan-2-6-t2v`, `wan-2-6-i2v`.

**Output delivery:** the succeeded task carries `video_url` = a signed edge URL `https://media-<env>.atptoken.ai/v/...?exp=&sig=` with a **30-minute TTL**. Fetch it promptly; after expiry the task still reports `succeeded` but `video_url` is `null` and `expired: true` (re-create to regenerate).

**Balance gate:** create is refused with `402 insufficient_quota` when the project balance is ≤ 0. Poll / list / cancel stay open.

Two client dialects share one task store — pick the one matching your SDK.

---

## ModelArk-compatible dialect (BytePlus SDK drop-in)

| Method | Path | Action |
|---|---|---|
| `POST` | `/omni/media/v1/contents/generations/tasks` | create |
| `GET` | `/omni/media/v1/contents/generations/tasks/{id}` | poll status/result |
| `GET` | `/omni/media/v1/contents/generations/tasks` | list your tasks |
| `DELETE` | `/omni/media/v1/contents/generations/tasks/{id}` | cancel |

### Create

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "seedance-2-0",
    "content": [
      { "type": "text", "text": "a red fox running through snow, cinematic" },
      { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
    ],
    "resolution": "720p",
    "ratio": "16:9",
    "duration": 5
  }'
```

**Request body**

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `model` | string | ✅ | unified video model (`video` pool) |
| `content` | array | ✅ | multimodal input blocks (see below). Text only → text-to-video; include an image → image-to-video |
| `resolution` | string | | `480p` / `720p` / `1080p` / `4k` |
| `ratio` | string | | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` (alias `aspect_ratio`) |
| `duration` | int | | seconds (mutually exclusive with `frames`) |
| `frames` | int | | frame count (alt to `duration`) |
| `generate_audio` | bool | | generate a soundtrack (alias `add_audio`) |
| `return_last_frame` | bool | | also return `content.last_frame_url` |
| `seed` | int | | |
| `camera_fixed` | bool | | |
| `watermark` | bool | | |
| `service_tier` | string | | `default` / `flex` (ModelArk-compat; no output effect) |

**`content[]` block**: `{ "type": "text"|"image_url"|"video_url"|"audio_url", ... }`
- `text` — the prompt text (`type: text`)
- `image_url` / `video_url` — `{ "url": "<url>" }`. **The video endpoint accepts public `https://` URLs only** — see below.
- `role` — `first_frame` / `last_frame` / `reference_image` / `reference_video` / `reference_audio`

### What `url` accepts — verified 2026-08-04 against production

| Form | Video endpoint | Image endpoint |
|---|---|---|
| public `https://…` URL | **works** | works |
| `data:image/…;base64,…` | **REJECTED** — `invalid_parameters: The parameter combination is not supported.` | works |
| `asset://<id>` or `asset://<pid>.<id>` | **NOT SUPPORTED** | NOT SUPPORTED |

An earlier revision of this skill listed `asset://<pid>.<id>` as a valid form. **It is
not.** Both spellings, on both the video and image endpoints, fail at generation time
with `provider_error / generation_failed` — eight calls, zero successes. Do not attempt
it, and do not fall back to base64 on the video endpoint either.

**To reference a file you uploaded**, resolve it to a URL the upstream can fetch without
auth: read the `Location` header of `GET /v1/files/{id}` **without following the
redirect**.

```bash
FILE_ID=$(curl -s https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATP_KEY" -F "file=@./first-frame.png" | jq -r .id)
# NOTE: the response key is `id` (an_<ULID>), not `gw_file_id`.

FRAME_URL=$(curl -sD - -o /dev/null "https://api.atptoken.ai/v1/files/$FILE_ID" \
  -H "Authorization: Bearer $ATP_KEY" | grep -i '^location:' | cut -d' ' -f2 | tr -d '\r')
# presigned object-store URL: no auth, ~15-minute TTL. Resolve it immediately before
# creating the task — do not cache it, and do not store it in a manifest.
```

Then pass `$FRAME_URL` as `content[].image_url.url` with `role: "first_frame"`.

**Idempotency** (retry-safe create): send one of `Idempotency-Key`, `X-Idempotency-Key`, `X-Thankyou-Task-Id`. The same key returns the original task id without creating a duplicate (no double charge). No key → a fresh task every call.

**Response `202`:** `{ "id": "cgt_01JABCDEF..." }` — use `id` to poll / cancel.

### Poll — `GET .../tasks/{id}`

```json
{
  "id": "cgt_01J...",
  "model": "seedance-2-0",
  "status": "succeeded",
  "content": {
    "video_url": "https://media-prod.atptoken.ai/v/video/<key>.mp4?exp=...&sig=...",
    "last_frame_url": null
  },
  "usage": { "completion_tokens": 108900, "total_tokens": 108900, "source": "formula" },
  "expired": false,
  "created_at": 1781776187,
  "updated_at": 1781776321
}
```

- `status` ∈ `queued | running | succeeded | failed | expired | cancelled`
- `content.video_url` — signed URL (30-min TTL); `null` + `"expired": true` once the blob URL expires
- `usage.source` — `actual` (upstream-reported) or `formula` (estimated from resolution/duration/fps); video `input` tokens are always 0
- `status: "failed"` → an `error: { "code": ..., "message": ... }` block explains the upstream failure

### List — `GET .../tasks`
`{ "items": [ <task>, ... ] }` — tasks belonging to your api key's project/org only.

### Cancel — `DELETE .../tasks/{id}`
`200 {}` when queued (→ cancelled) or terminal (record deleted); **`409`** if the task is already `running` (can't cancel a running task); `404` if not found / not yours.

---

### Multi-image reference (`[Image N]` composition) — validate before batching

Reference models (`kling-*-reference`, `happyhorse-1.1-r2v`, …) take several
`role: "reference_image"` blocks and the prompt refers to them as `[Image 1]`,
`[Image 2]`, …. In one production test (2026-08-04) `kling-o3-pro-reference` with two
reference images and the prompt *"place [Image 1] in the scene of [Image 2]"* was
accepted, rendered and **billed** — but the composition was not performed: the output
kept Image 1's own background. One test with synthetic source images is not proof the
feature is broken, so this is a warning, not a "does not work". **Render one short
low-resolution clip and inspect it before committing a batch or a user-facing flow.**

## DashScope-native dialect (Alibaba Wan SDK drop-in)

| Method | Path | Action |
|---|---|---|
| `POST` | `/omni/media/v1/services/aigc/video-generation/video-synthesis` | create |
| `GET` | `/omni/media/v1/tasks/{id}` | poll |

```bash
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "wan-2-6-i2v",
    "input": { "prompt": "...", "img_url": "https://example.com/in.jpg", "negative_prompt": "blurry" },
    "parameters": { "size": "1280*720", "duration": 5, "seed": 0, "watermark": false }
  }'
```

**Request:** `model` (required), `input` (required — `{ prompt, img_url (i2v first frame), negative_prompt }`), `parameters` (`{ size e.g. "1280*720", duration, seed, watermark }`).

**Response `202`:** `{ "output": { "task_id": "cgt_...", "task_status": "PENDING" } }`

**Poll — `GET /omni/media/v1/tasks/{id}`:**
```json
{
  "output": { "task_id": "cgt_...", "task_status": "SUCCEEDED",
              "video_url": "https://media-prod.atptoken.ai/v/..." },
  "usage": { "completion_tokens": 108900, "total_tokens": 108900, "source": "formula" }
}
```
`task_status` ∈ `PENDING | RUNNING | SUCCEEDED | FAILED | CANCELED`. Succeeded-but-expired → `video_url: null`.

---

## Wan model-specific payloads

Use the ATP ModelArk-compatible endpoint above. ATP keeps the unified model name
and task lifecycle while forwarding the model-specific fields.

**Wan 2.6 text-to-video**

```json
{
  "model": "wan-2-6-t2v",
  "content": [
    { "type": "text", "text": "Waves crashing against rocks, cinematic tracking shot" }
  ],
  "size": "1280*720",
  "duration": 10,
  "negative_prompt": "blurry, low quality",
  "prompt_extend": true,
  "shot_type": "multi",
  "audio": true,
  "seed": 42
}
```

Supported durations are `5`, `10`, or `15` seconds. `size` accepts the published
720P/1080P dimensions. `shot_type` is `single` or `multi` and only takes effect
when `prompt_extend` is enabled. A custom `audio_url` (WAV/MP3, 3–30 seconds,
up to 15 MB) overrides automatic audio.

**Wan 2.6 image-to-video**

```json
{
  "model": "wan-2-6-i2v",
  "content": [
    { "type": "text", "text": "The camera rises slowly while the cat looks up" }
  ],
  "input": {
    "image": "https://example.com/first-frame.jpg"
  },
  "resolution": "720P",
  "duration": 5,
  "prompt_extend": true,
  "audio": false
}
```

For this model, put the required first frame in `input.image` (public URL or
base64). Accepted files are JPEG/JPG/PNG without transparency, BMP, or WEBP;
each side must be 360–2000 px and the file must be at most 10 MB. Optional
`last_frame` uses the same URL/base64 form.

**Wan 2.2 text-to-video plus**

Use `wan-2-2-t2v-plus` with `duration: 5`. It outputs 30 fps and accepts:

- 480P: `832*480`, `480*832`, `624*624`
- 1080P: `1920*1080`, `1080*1920`, `1440*1440`, `1632*1248`, `1248*1632`

Availability is project-specific. Do not hard-code this list as entitlement;
check `GET /v1/models` with the same `atp-` key before creating a task.

---

## Errors

| Status | Meaning |
|---|---|
| `400` | missing `model`, or no prompt and no image, or mixed-upstream asset |
| `402` `insufficient_quota` | project balance ≤ 0 — top up and retry (don't hammer) |
| `403` `permission_denied` | the model is **gated** (whitelist-only) and your project isn't enabled — ask your Atptoken admin |
| `422` | the model has no video provider, or an asset upstream is unavailable |
| `502` | upstream create failed — the idempotency reservation is released, safe to retry |

Some premium video models are gated per-project (403 elsewhere). Billing is settled asynchronously by the gateway when the task reaches a terminal state. Model names are configuration — always confirm the live catalogue with `GET /v1/models`. For image or audio generation see the **atptoken-image** / **atptoken-audio** skills; for auth and the cross-surface error table see **atptoken-gateway**.
