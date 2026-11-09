---
name: atptoken-video
description: Generate video (text-to-video / image-to-video / video edit) through the Atptoken LLM Gateway media surface at /omni/media/v1. Video is asynchronous — create a task, poll until it is terminal, then download a signed URL within 24 hours. The model decides the body shape. Two client dialects (ModelArk-compatible and DashScope-native). Use for Seedance / Kling / Wan / HappyHorse / MiniMax video models via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken video generation

Video generation is **asynchronous** and has no synchronous variant: you create a task (`202` + task id), poll until the status is terminal, then download the signed URL for the output. A video takes minutes.

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` + `Content-Type: application/json`
- **Model:** confirm what this key may call with `GET https://api.atptoken.ai/v1/project/models` (every model the project allows, all modalities). `GET /v1/models` lists only OpenAI-dialect chat models — video models are not on it. A name missing from a list is not necessarily unusable; an unauthorized model returns `403` at create and is not billed. If unsure, use `seedance-2-0`.

**The model decides the body shape.** On the same endpoint different model families take different field names, sometimes with different casing. Never infer one model's fields from another's.

**Output delivery:** the succeeded task carries `content.video_url` = a signed URL `https://media-<env>.atptoken.ai/v/...?exp=&sig=` valid for **24 hours**. After that the task still reports `succeeded`, but `video_url` is `null` and `expired: true` (re-create to regenerate). Always check for `null` after `succeeded`. Do not store the URL as a permanent link.

**No webhooks.** `callback_url` is accepted but never used; you must poll. `service_tier`, `safety_identifier` and `execution_expires_after` are likewise accepted and dropped.

**Balance gate:** create is refused with `402 insufficient_quota` when the project balance is exhausted (`credit − inflight ≤ 0`). Poll / list / cancel stay open.

Two client dialects share one task store — pick the one matching your SDK.

---

## Pick the body shape by family

| Family | Models | Text and media go in |
|---|---|---|
| Seedance | `seedance-2-0`, `seedance-2-0-fast`, `seedance-2-0-mini`, `seedance-2-5` | `content[]` with `role` |
| Kling | `kling-o3-*`, `kling-v3-*` | `content[]` with `role` — **except `-v2v` / `-video-edit`: `input`** |
| Wan 2.7 / HappyHorse | `wan-2-7-t2v`, `wan-2-7-i2v`, `wan-2-7-video`, `happyhorse-1.1-t2v` / `-i2v` / `-r2v` | `content[]` with `role` |
| HappyHorse video edit | `happyhorse-1.0-video-edit` | DashScope-native endpoint, `input.media[]` |
| MiniMax | `minimax-h3` | `content[]` |
| Wan 3.0 / spicy | `wan-3-0-video`, `wan-3-0-video-pro`, `wan-3-0-video-prime`, `wan-2-2-i2v-spicy`, `wan-2-7-i2v-spicy` | **flat**: top-level `prompt`, `first_frame`, … |

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

**Request body** (the space the endpoint accepts — what a given model reads is per model, below)

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `model` | string | ✅ | model ID |
| `content` | array | ✅ | multimodal input blocks (see below). Text only → text-to-video; include an image → image-to-video. Flat models use `prompt` instead |
| `resolution` | string | | `480p` / `720p` / `1080p` / `4k` / `768P` / `2K`; some models take uppercase only |
| `ratio` | string | | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` (alias `aspect_ratio`, which some models reject) |
| `duration` | int | | seconds (mutually exclusive with `frames`) |
| `frames` | int | | frame count (alt to `duration`) |
| `generate_audio` | bool | | generate a soundtrack (alias `add_audio`); some models call it `audio` or `sound` |
| `return_last_frame` | bool | | also return `content.last_frame_url` |
| `seed` | int | | |
| `camera_fixed` | bool | | |
| `watermark` | bool | | some models reject it |
| `service_tier` | string | | `default` / `flex` (ModelArk-compat; no output effect) |

**`content[]` block**: `{ "type": "text"|"image_url"|"video_url"|"audio_url", ... }`
- `text` — the prompt text (`type: text`)
- `image_url` / `video_url` / `audio_url` — `{ "url": "<url>" }`. The block has **no top-level `url`**; putting it there returns `400 missing content[1].image_url`.
- `role` — `first_frame` / `last_frame` / `reference_image` / `reference_video` / `reference_audio`

**The endpoint does not validate field names** on `content[]` models. A misspelled field, or one the model does not read, still gets `202` and has no effect. Undeclared top-level fields on Kling / Seedance are forwarded as-is (e.g. `negative_prompt`); fields in an `input: {…}` bag are forwarded too and win over same-named top-level fields. To confirm a parameter took effect, compare the **value** in the polled task's `resolved_params` (what the model actually used; it also contains model defaults) with what you sent. `params_raw` is the body the gateway sent. Flat models are the opposite: extra fields return `400 Extra inputs are not permitted`.

### What `url` accepts

| Form | Video endpoint | Image endpoint |
|---|---|---|
| public `https://…` URL | works — must be fetchable by the model without auth | works |
| base64 | accepted | works |
| `asset://…` (`AssetUri` from the asset API) | works where the model accepts assets (not `seedance-2-0-fast`) | NOT SUPPORTED — fails at generation with `provider_error / generation_failed` |

**`/v1/files` is not a media source.** Its `an_<ulid>` id in `image_url.url` returns `400 The parameter content[1].image_url specified in the request is not valid`; `https://api.atptoken.ai/v1/files/{id}` returns `400` too. Host the file at a public `https://` URL, or register it as an asset.

### Asset chain

Registering an asset needs a public URL too; assets are a different reference form that some models require, not a substitute for having a URL.

1. `POST /omni/media/v1/asset-groups` — body `Name`, `Description`, `model` (optional but recommended: it guarantees the group works with that model). Groups have a quota (~50) — **reuse groups**, do not open one per asset.
2. `POST /omni/media/v1/assets` — body `group_id`*, `url`*, `asset_type`, `name`. **Always set `asset_type`** (`Image` / `Video` / `Audio`); without it a video can be silently registered as an image. Keep `name` ≤ 64 characters: a longer name still returns 200 here, then fails in step 3 (`InvalidParameter.Name`) and a task using it gets `ATP_ASSET_FAILED`.
3. `POST /omni/media/v1/assets/get` — body `asset_id`*. Poll until ready (`Completed`, or `Active` depending on the upstream), then read `AssetUri`. **Not optional:** a task with an unready asset returns `400` (`reason: asset_not_ready`); a failed asset returns `400` (`reason: asset_failed`).
4. Pass the `AssetUri` unchanged as `content[].image_url.url`.

- **Queued registration:** for some models each group accepts one creation every 20 seconds, so the upload returns immediately with an `asset-q-<ULID>` id (`AssetUri` `asset://asset-q-<ULID>`), status `Processing`, and a `Retry-After` estimate. Poll to `Completed` before use. Different groups queue independently.
- **Lifetime:** an asset lives as long as its group; groups are reclaimed after the video completes, or in the daily cleanup of groups idle for over a day.
- **Do not mix asset sources in one task** → `400`.
- `seedance-2-0-fast` does not take assets → `422 this asset's upstream does not serve the requested model`; pass a public URL.

**Photos of real people:** a public URL can be rejected with `400 may contain real person`. Register the same image as an asset and pass the `AssetUri`; no identity verification is needed. `seedance-2-0-fast` cannot use assets, so real-person photos and `-fast` are mutually exclusive.

**Optional identity verification (KYC)** — only when your product requires it:
1. `POST /omni/media/v1/validate-session` (body `callback_url` optional) → `h5_link` + `session_ref`. Passthrough, not billed.
2. Give `h5_link` to the end user; after verifying you receive a `byted_token`.
3. `POST /omni/media/v1/validate-result` with `session_ref`* + `byted_token`* → `group_id`.
4. Continue at asset step 2 with that `group_id` — **do not create another group**.

Check a group with `GET /omni/media/v1/asset-groups/{id}` (returns `group_type`).

**Idempotency** (retry-safe create): send one of `Idempotency-Key`, `X-Idempotency-Key`, `X-Thankyou-Task-Id`. The same key returns the original task id without creating a duplicate (no double charge). No key → a fresh task every call. Use a separate key per media surface: a key reused across image and video returns `409`.

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

- `status` ∈ `queued | running | succeeded | failed | expired | cancelled`; the last four are terminal — exit the loop on all four, not only `succeeded`.
- `content.video_url` — signed URL (24 h); `null` + `"expired": true` once it expires (status stays `succeeded`)
- `usage.source` — `actual` (upstream-reported) or `formula`; video `input` tokens are always 0
- `status: "failed"` → an `error: { "code": ..., "message": ... }` block explains the failure
- `404` — not found, or not your task

### List — `GET .../tasks`
`{ "items": [ <task>, ... ] }` — tasks belonging to your api key's project/org only.

### Cancel — `DELETE .../tasks/{id}`
`200 {}` when queued (→ cancelled) or terminal (record deleted); **`409`** if the task is already `running` (can't cancel a running task); `404` if not found / not yours.

---

## Seedance

| Model | Resolution | Duration | Media transport | Supported combinations (plus text-only) |
|---|---|---|---|---|
| `seedance-2-0` | `480p` `720p` `1080p` `4k` (default `480p`) | 4–15 (default 4) | public URL or asset | first frame; first+last; reference image; ref image + ref audio; reference video; image+video+audio |
| `seedance-2-0-fast` | `480p` `720p` | same | **public URL only** | first frame; first+last; reference image |
| `seedance-2-0-mini` | `480p` `720p` | same | first frame and refs: public URL; first+last: asset | first frame; first+last; up to 3 reference images |
| `seedance-2-5` | `480p` `720p` `1080p` | `-1` (model default; usually follows the input video), or 4–30 | asset (public URL also documented) | reference audio only; first+last; reference image; ref image + ref audio; reference video |

- Media limits: `seedance-2-0` / `-fast` / `-mini` — 9 images, 3 videos, 3 audio (audio **not alone**). `seedance-2-5` — 30 images, 10 videos, 10 audio (audio alone OK).
- `ratio` defaults to `16:9`; `generate_audio` defaults to `false`. `seedance-2-5` also takes `output_format` (`mp4` / `mov`).
- **Aspect ratio with a first frame:** on the `seedance-2-0` family `ratio` sets the output shape, not the frame — a portrait frame without `ratio` gives a landscape video (864×496 at 480p). Send `ratio: "adaptive"` to follow the frame (496×864). On `seedance-2-5`, **do not send `ratio` with first+last frames**.
- The ID is `seedance-2-0-mini`; `seedance-2-mini` is not an alias and returns `400 InvalidParameter`.

## Kling

The **model name** decides operation and quality: `standard` renders 720p, `pro` 1080p (except `-v2v` / `-video-edit`). Suffix: `-i2v` (first frame), `-reference` (1–6 images), `-reference-7` (7 images), `-v2v` (new clip using a source video), `-video-edit` (edit the source clip).

Send media in `content[]` — the gateway builds the model's `reference_assets`; do not build it yourself (except `-v2v` / `-video-edit`). Do not send `last_frame` for now.

| Param | Values | Default |
|---|---|---|
| prompt (text block) | ≤ 2500 chars; required on `kling-v3-*` | — |
| `ratio` | `16:9` `9:16` `1:1` only | `16:9` |
| `duration` | 3–15 | `5` |
| `resolution` | `720p` `1080p` — **only `-i2v` reads it** | — |
| `generate_audio` | bool (o3) | **`true`** |
| `sound` | bool (`kling-v3-standard`, `kling-v3-*-i2v`) | `false` |
| `negative_prompt` | ≤ 1000 chars (v3) | — |
| `cfg_scale` | 0–1 (`kling-v3-standard` / `-standard-i2v`) | `0.5` |
| `guidance_scale` | 0–1 (`kling-v3-standard`, `kling-v3-*-i2v`) | `0.5` |
| `multi_prompt` | array (o3) | — |

- o3 outputs have a soundtrack unless you send `generate_audio: false`. `kling-v3-pro` has no audio field.
- `-i2v` ignores `ratio` (the image decides). `-reference-7` ignores `ratio` too — `16:9` yields 960×960.

### Kling `-v2v` / `-video-edit` — body in `input`, not `content[]`

`kling-o3-standard-v2v`, `kling-o3-pro-v2v`, `kling-o3-standard-video-edit`, `kling-o3-pro-video-edit`. Use `-video-edit` to change this clip (background, object, style; keep the rest); `-v2v` to generate a new clip using the source for motion/content.

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-edit-001" \
  -d '{
    "model": "kling-o3-standard-video-edit",
    "input": {
      "prompt": "Replace the cat in the video with a Shiba Inu. Keep the motion, camera and everything else unchanged.",
      "reference_assets": [
        { "role": "source_video", "asset_type": "video", "url": "https://example.com/source.mp4" }
      ],
      "keep_original_sound": false
    }
  }'
```

| `input` field | Values | Notes |
|---|---|---|
| `prompt` | ≤ 2500 chars | required |
| `reference_assets` | array | required; exactly one `{"role":"source_video","asset_type":"video","url":…}`; plus 0–4 `{"role":"reference","asset_type":"image","url":…}` |
| `keep_original_sound` | bool | default `false` (this is the audio field here, not `generate_audio`) |
| `duration` | 3–15 | `-v2v` only; default `5` |

- Output follows the source clip, not the 720p/1080p rule: a 1280×720, 3 s source → `-video-edit` 1280×720, 3 s (pro too); `-v2v` 1280×720, 5 s without `duration`.
- Video in `content[]` (role `source_video` or `reference_video`), or a reference image role of `reference_image` / `image` → `422 The parameter combination is not supported.` at create (no charge).
- **Prompt: put the change in the first sentence** ("Replace X with Y. Keep the motion…"). Long preserve-lists, or asking the new subject to match the old one, can return the original unchanged while the task still `succeeded`. Check the video.

## Wan 2.7 / HappyHorse (`content[]`)

- `resolution`: `720p` / `1080p` (lowercase) only; `480p` is treated as not sent (model default, ~1080P, billed at 1080P). `ratio`, `duration`, `watermark`, `seed`; `audio_setting` only on `-video-edit`.
- Roles by suffix: `-i2v` → one `first_frame`; `-r2v` → 1–9 `reference_image` (refer to them in the prompt as `[Image 1]`, `[Image 2]`, … — render one short low-resolution clip and inspect it before batching).
- `wan-2-7-t2v`, `wan-2-7-i2v`, `happyhorse-1.1-t2v` (and `happyhorse-1.0-video-edit`) can return `404 not_found_error — upstream returned 404` at create: temporarily unavailable, not a body error, no task, no charge. For text-to-video, `wan-2-7-video` uses the same `content[]` shape.
- `happyhorse-1.0-video-edit` is not served on this endpoint (`400` pointing you to `input.media`); use the DashScope-native dialect below.

## Wan 3.0 / spicy — flat body, not `content[]`

`wan-3-0-video`, `wan-3-0-video-pro`, `wan-3-0-video-prime`, `wan-2-2-i2v-spicy`, `wan-2-7-i2v-spicy`.

```json
{
  "model": "wan-3-0-video",
  "prompt": "a paper boat drifting on still water",
  "first_frame": "https://example.com/first-frame.png",
  "resolution": "480P",
  "ratio": "16:9",
  "duration": 4,
  "audio": false,
  "prompt_extend": false
}
```

- `resolution` uppercase: `480P` `720P` `1080P` (default `480P`); `-pro` also `2K` `4K`. `duration` `-1` (model default length, usually follows the input video) or 2–30 (default 4). `ratio` `16:9` `9:16` `4:3` `3:4` `1:1` `adaptive`. `audio` (not `generate_audio`, default `false`). `prompt_extend` (default `false`).
- Frame mode (`first_frame` / `last_frame`) **or** reference mode (`reference_images` ≤ 10, `reference_videos` ≤ 5, `reference_audios` ≤ 5), never both.
- A `content` array is dropped; a body left empty returns `missing_prompt_or_image`. `input` is flattened into the top level — use neither. Sending `aspect_ratio`, `generate_audio`, `watermark` or `media` returns `400 Extra inputs are not permitted`.

## MiniMax H3

`minimax-h3` uses `content[]`. `resolution` has two tiers, `768P` and `2K`; standard tiers (`480p` `720p` `1080p` `4k`) map onto them. **Do not send `watermark`** (`false` or `"false"`) → `400 invalid params, watermark is invalid (2013)`.

---

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

**Request:** `model` (required), `input` (required — contents depend on the model, e.g. `{ prompt, img_url (i2v first frame), negative_prompt }`), `parameters` (e.g. `{ size e.g. "1280*720", duration, seed, watermark }`).

**`happyhorse-1.0-video-edit`** goes here, with the video in `input.media[]`:

```json
{
  "model": "happyhorse-1.0-video-edit",
  "input": {
    "prompt": "replace the background with a snowy street",
    "media": [
      { "type": "video",           "url": "https://example.com/source.mp4" },
      { "type": "reference_image", "url": "https://example.com/style.jpg" }
    ]
  },
  "parameters": { "resolution": "720P", "watermark": false }
}
```

A wrong body still gets `202` here; the error surfaces when polling as `InvalidParameter` (e.g. `InvalidParameter: Field required: input.media`). Output length follows the source clip.

**Response `202`:** `{ "output": { "task_id": "cgt_...", "task_status": "PENDING" } }`

**Poll — `GET /omni/media/v1/tasks/{id}`:**
```json
{
  "output": { "task_id": "cgt_...", "task_status": "SUCCEEDED",
              "video_url": "https://media-prod.atptoken.ai/v/..." },
  "usage": { "completion_tokens": 108900, "total_tokens": 108900, "source": "formula" }
}
```
`task_status` ∈ `PENDING | RUNNING | SUCCEEDED | FAILED | CANCELED`. Succeeded-but-expired → `video_url: null`. Access control, balance gate and pricing are identical to the ModelArk-compatible endpoint.

---

## Wan 2.6 / 2.2 model-specific payloads

Use the ATP ModelArk-compatible endpoint above. ATP keeps the model name and task lifecycle while forwarding the model-specific fields.

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
check `GET /v1/project/models` with the same `atp-` key before creating a task.

---

## Billing

Settled after the task is terminal, on actual usage: `(in_dur + out_dur) × W × H × fps ÷ 1024` video tokens, or the usage the model reports. Create only reserves lightly (any positive balance passes); a short balance at settlement goes negative and blocks the next request. Gated or not, every video model is billed the same way. Requests rejected at create are not billed.

## Errors

**Read the 4xx message** — model 4xx errors pass through as-is and usually name the field and valid values. Report problems with the response's `x-request-id`.

| Status | Meaning | Retry? |
|---|---|---|
| `400` | missing `model` / prompt, mixed asset sources, `asset_not_ready`, `asset_failed`, `may contain real person`, `missing content[1].image_url`, `Extra inputs are not permitted`, `watermark is invalid (2013)` | fix the body |
| `401` `token_revoked` | key invalid **or not sent at all** | check the header |
| `402` `insufficient_quota` | balance exhausted | **no** — top up first |
| `403` `permission_denied` | the model is **gated** (whitelist-only) and your project isn't enabled — not a key or balance problem | switch model or ask your Atptoken admin |
| `404` | at create: `upstream returned 404` — model temporarily unavailable; at poll: not found / not yours | switch model or retry later |
| `409` | `Idempotency-Key` already used on another media surface; or cancelling a `running` task | use a new key |
| `422` | wrong outer shape / role (`The parameter combination is not supported.`), asset not usable by this model (`this asset's upstream does not serve the requested model`), or no capacity | follow the model's shape; use a public URL instead of an asset |
| `429` | rate limited | back off and retry |
| `502` | create failed — the idempotency reservation is released | yes |
| `503` | enqueue failed, or `balance_check_unavailable` (balance could not be read — not insufficient; nothing charged) | yes, after `Retry-After` |

A failed task reports `status: failed` with the reason in `error`. Video model gating is independent of chat permissions. For image or audio generation see the **atptoken-image** / **atptoken-audio** skills; for auth and the cross-surface error table see **atptoken-gateway**.
