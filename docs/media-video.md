# Video generation

> Source: https://atptoken.ai/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

Video generation is **asynchronous**, with no synchronous variant: create a task (`202` + task id), poll until the status is terminal, then download the signed URL. Same base URL and `atp-` key as image. **The model decides the request shape**: on the same endpoint, different models take different field names, sometimes with different casing. Do not infer one model's fields from another's.

**Every video task**

1. Create the task — `POST …/contents/generations/tasks` — `202` + `cgt_…`
2. Poll until terminal — `GET …/contents/generations/tasks/{id}` — stop on all four terminal states
3. Download `content.video_url` — signed URL — valid for 24 hours
   - succeeded
   - failed: reason in `error`
   - after 24 hours: still `succeeded`, but `video_url` is `null` and `expired: true`

- **`succeeded` does not guarantee a file.** After 24 hours the task still reports `succeeded`, but `content.video_url` becomes `null` and `expired: true` appears; the only fix is a new task. Download what you want to keep, and do not store the URL as a permanent link.
- **There are no webhooks; you must poll.** `callback_url` is accepted but never used.
- When the project balance is exhausted, create returns `402 insufficient_quota`.

## Choose a model

If unsure, use `seedance-2-0`. First find the model's family: **the family decides the outer shape of the request**.

| Family | Models | Where text and media go |
| --- | --- | --- |
| Seedance | `seedance-2-0`, `seedance-2-0-fast`, `seedance-2-0-mini`, `seedance-2-5` | `content[]`; see [Seedance](https://atptoken.ai/docs/seedance-2-0/) |
| Kling | `kling-o3-*`, `kling-v3-*` | `content[]`; except `-v2v` and `-video-edit`, which use `input` |
| Wan 2.7, HappyHorse | `wan-2-7-t2v`, `wan-2-7-i2v`, `wan-2-7-video`, `happyhorse-1.1-t2v` / `-i2v` / `-r2v` | `content[]` |
| HappyHorse video edit | `happyhorse-1.0-video-edit` | a separate endpoint, `input.media[]` |
| MiniMax | `minimax-h3` | `content[]` |
| Wan 3.0, spicy | `wan-3-0-video`, `wan-3-0-video-pro`, `wan-3-0-video-prime`, `wan-2-2-i2v-spicy`, `wan-2-7-i2v-spicy` | **flat**: `prompt` and media at the top level |

> **Check which models this key can use**
>
> The complete list is `GET https://api.atptoken.ai/v1/project/models`: every model this project allows, text, image and video alike. `GET /v1/models` lists only OpenAI-dialect chat models; video models are not on it.
>
> A model missing from a list is not necessarily unusable, and a listed model may have no upstream serving it right now. Without permission, create returns `403` and nothing is billed.

**Video models are open by default.** An administrator can gate a specific model so only allow-listed accounts can use it. A `403 permission_denied` is not a key or balance problem: switch models or ask the administrator for access. This gate applies only to video and is independent of chat permissions.

## Create a task

```
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
# → 202 { "id": "cgt_..." }
```

Only `model` and `content` are required (`model` and `prompt` for the flat family). The table lists every field the endpoint accepts; which ones a model actually reads is in that model's section.

| Field | Type | Notes |
|---|---|---|
| model | string · Req | model ID |
| content | array · Req | text and media blocks (see below) |
| resolution | string | `480p` `720p` `1080p` `4k` `768P` `2K`; some models take uppercase only |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` (alias `aspect_ratio`, which some models reject) |
| duration | integer | seconds (mutually exclusive with `frames`) |
| frames | integer | frame count (alt to `duration`) |
| generate_audio | boolean | generate a soundtrack (alias `add_audio`); some models call it `audio` or `sound` |
| return_last_frame | boolean | adds `content.last_frame_url` to the result |
| seed | integer | |
| camera_fixed | boolean | |
| watermark | boolean | some models reject it |

`callback_url`, `service_tier`, `safety_identifier` and `execution_expires_after` are accepted and dropped; they have no effect on the output.

**`content[]` blocks**: each block is `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`.

- Text only → text-to-video; with an image → image-to-video.
- The URL goes inside `image_url: { "url": "…" }` (`video_url` for video, `audio_url` for audio). A block has **no top-level `url`**; putting it there returns `400 missing content[1].image_url`.
- `role` is `first_frame`, `last_frame`, `reference_image`, `reference_video` or `reference_audio`.

**Idempotency**: send `Idempotency-Key` (or `X-Idempotency-Key`, `X-Thankyou-Task-Id`). Resending with the same key returns the original task id, with no duplicate task and no double charge. Use a separate key per media surface: a key first used for an image task and then for a video task returns `409`.

### Wrong field names do not raise errors

The `content[]` families **do not check field names**. A misspelled field, or one the model does not read, still gets `202` and simply has no effect. Undeclared top-level fields on Kling and Seedance are forwarded to the model as-is (for example `negative_prompt`); fields placed in an `input: {…}` bag are forwarded too, and `input` wins when names clash.

To confirm a parameter took effect, read `resolved_params` (the parameters the model actually used) in the polled task; `params_raw` is the body the gateway sent. `resolved_params` also includes defaults the model filled in, so compare the **value** with what you sent, not just whether the field is present.

The flat family is the opposite: extra fields are rejected with `400 Extra inputs are not permitted`.

## Passing media

`content[].image_url.url` (or `video_url.url`, `audio_url.url`) can hold:

| Form | Notes |
| --- | --- |
| public `https://…` URL | Simplest. The model must be able to fetch it without auth. |
| base64 | Also accepted. |
| `asset://…` (`AssetUri` from the asset API) | Pass it exactly as returned. Some models require this; see below. |

**`/v1/files` uploads cannot be used as media.** The `an_…` id it returns is a chat file id; in `image_url.url` it returns `400 The parameter content[1].image_url specified in the request is not valid`, and `https://api.atptoken.ai/v1/files/{id}` returns `400` too. Host the file at a public `https://` URL, or register it as an asset.

The image endpoint does not support `asset://` references; it fails at generation time with `provider_error / generation_failed`.

### Register an asset

Registering an asset needs a public URL as well, so assets are not a substitute for having one. They are a different way of referencing media that some models require.

**Register media as an asset**

1. Create an asset group — `POST /omni/media/v1/asset-groups` — body: `Name`, `Description`, `model` (recommended)
2. Register the media — `POST /omni/media/v1/assets` — body: `group_id`, `url`, `asset_type`, `name`
3. Poll until ready — `POST /omni/media/v1/assets/get` — body: `asset_id`; returns `AssetUri`
4. Create the video task — `POST …/contents/generations/tasks` — `AssetUri` goes in `content[].image_url.url`

```
{ "type": "image_url", "image_url": { "url": "asset://…" }, "role": "reference_image" }
```

Where this chain usually goes wrong:

- **The order is fixed.** You cannot register without a `group_id`. Creating a task before the asset is ready returns `400` (`reason: asset_not_ready`); a failed asset returns `400` (`reason: asset_failed`). The polling step is not optional.
- **Always set `asset_type`** to `Image`, `Video` or `Audio`. Without it a video can be registered as an image, silently.
- **Pass `model` when creating the group.** That guarantees the group can be used with that model later.
- **Groups have a quota (about 50).** Reuse groups; do not open one per asset.
- **`name` is at most 64 characters.** A longer name still gets 200 at registration and only fails when polled (`InvalidParameter.Name`); a task using it gets `ATP_ASSET_FAILED`. Shorten the name.
- **One task cannot mix assets from different sources**; that returns `400`.
- The asset is ready when its status is `Completed` or `Active`; which one you get is up to the upstream.

**Some models queue registrations.** Each group accepts one creation every 20 seconds, so you immediately get an `asset-q-…` id (`AssetUri` is `asset://asset-q-…`), status `Processing`, and an estimated wait in `Retry-After`. Poll until `Completed` before using it. Different groups queue independently.

An asset lives as long as its group: once the group is cleaned up (reclaimed after the video completes, or in the daily cleanup of groups idle for more than a day), the id no longer resolves.

`seedance-2-0-fast` does not take assets and returns `422 this asset's upstream does not serve the requested model`; pass a public URL. Per-model support for Seedance is on [Seedance](https://atptoken.ai/docs/seedance-2-0/).

### Photos of real people

A public URL of a photo of a real person can be rejected with `400 may contain real person`. When that happens, register the same image as an asset and pass the `AssetUri`; **no identity verification is needed**. `seedance-2-0-fast` cannot use assets, so do not use it for these photos.

Use the identity verification flow only when your product requires it:

**Real-person verification (optional)**

1. Start verification — `POST /omni/media/v1/validate-session` — returns `h5_link` + `session_ref`; not billed
2. The user verifies — give the user `h5_link` — you receive a `byted_token` afterwards
3. Get the group — `POST /omni/media/v1/validate-result` — body: `session_ref`, `byted_token`; returns `group_id`
4. Register and create — `POST /omni/media/v1/assets` → `assets/get` → create the task — use that `group_id`

The verification flow supplies its own group; **do not create another one**. To inspect a group, call `GET /omni/media/v1/asset-groups/{id}` (returns `group_type`).

## Poll and download

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| Status | Terminal | Meaning |
| --- | --- | --- |
| `queued` | | queued; keep polling |
| `running` | | generating; keep polling |
| `succeeded` | ✓ | has a result; still check whether `video_url` is `null` |
| `failed` | ✓ | failed; reason in `error: { code, message }` |
| `expired` | ✓ | the result is gone |
| `cancelled` | ✓ | cancelled |

A loop that only waits for `succeeded` spins forever on `failed`; stop on all four terminal states. A video takes minutes.

| Method | Path | Action |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | create |
| GET | /omni/media/v1/contents/generations/tasks/{id} | poll; `404` if not found or not yours |
| GET | /omni/media/v1/contents/generations/tasks | list this project's tasks |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | `queued` → cancel; terminal → delete record; `running` → `409` |

For the last frame, send `return_last_frame: true` at create; the result carries `content.last_frame_url`.

## Kling video models

Kling uses the same endpoint as Seedance. **The model name, not a parameter, decides the operation and quality**: `standard` renders 720p and `pro` renders 1080p (except `-v2v` and `-video-edit`); the suffix picks the operation.

| What you want | Models | Media |
| --- | --- | --- |
| Text-to-video | `kling-o3-standard` / `-pro`, `kling-v3-standard` / `-pro` | text only |
| Image-to-video | the models above plus `-i2v` | one `first_frame` |
| Reference images to video | `kling-o3-standard-reference` / `kling-o3-pro-reference` (1–6 images), `-reference-7` (7 images) | `reference_image` |
| New video using a source clip as reference | `kling-o3-standard-v2v`, `kling-o3-pro-v2v` | in `input`, see below |
| Edit a source clip | `kling-o3-standard-video-edit`, `kling-o3-pro-video-edit` | in `input`, see below |

Send media in `content[]`; the gateway converts it to the shape the model needs. Do not build `reference_assets` yourself (except for `-v2v` and `-video-edit`). Do not send `last_frame` for now.

| Field | Values | Default |
| --- | --- | --- |
| `prompt` (text block) | up to 2500 characters; required on `kling-v3-*` | |
| `ratio` | only `16:9`, `9:16`, `1:1` | `16:9` |
| `duration` | 3–15 s | `5` |
| `resolution` | `720p`, `1080p`; **read only by `-i2v`** | |
| `generate_audio` | boolean; `kling-o3-*` | `true` |
| `sound` | boolean; `kling-v3-standard`, `kling-v3-*-i2v` | `false` |
| `negative_prompt` | up to 1000 characters; `kling-v3-*` | |
| `cfg_scale` | 0–1; `kling-v3-standard` / `-standard-i2v` | `0.5` |
| `guidance_scale` | 0–1; `kling-v3-standard`, `kling-v3-*-i2v` | `0.5` |
| `multi_prompt` | array; `kling-o3-*` | |

Where the output differs from what you send:

- **The audio field differs by group.** o3 uses `generate_audio`, which **defaults to `true`**, so omitting it gives a soundtrack; send `false` for silence. v3 uses `sound`. `kling-v3-pro` has no audio field.
- **`-i2v` ignores `ratio`**; the input image sets the aspect ratio. Sending it does not error but has no effect.
- **`-reference-7` ignores `ratio` too**: ask for `16:9` and you get 960×960.
- To be sure, inspect the returned video or compare `resolved_params`.

### Text-to-video

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-job-001" \
  -d '{
    "model": "kling-o3-standard",
    "content": [{ "type": "text", "text": "an orange cat walking slowly along the beach at sunset, steady tracking shot" }],
    "ratio": "16:9",
    "duration": 5,
    "generate_audio": false
  }'
# → 202 { "id": "cgt_..." }
```

### Image-to-video

```
{
  "model": "kling-o3-standard-i2v",
  "content": [
    { "type": "text", "text": "the person slowly turns and smiles; keep the outfit and background unchanged" },
    { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "duration": 5
}
```

For Pro, switch to the Pro model ID and set `resolution` to `1080p`.

### Reference images to video

```
{
  "model": "kling-o3-standard-reference",
  "content": [
    { "type": "text", "text": "the figure turns and walks away" },
    { "type": "image_url", "image_url": { "url": "https://example.com/figure.jpg" }, "role": "reference_image" }
  ],
  "ratio": "16:9",
  "duration": 3,
  "generate_audio": false
}
```

### Video-to-video and video editing

Pick the operation first: to **change this clip** (swap the background or an object, restyle it, keep the rest), use `-video-edit`; to **generate a new clip that uses the source for motion or content**, use `-v2v`.

Both put the request in **`input`**, not `content[]`. The source video must be at a public `https://` URL:

```
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
# → 202 { "id": "cgt_..." }
```

| Field (all inside `input`) | Values | Notes |
| --- | --- | --- |
| `prompt` | up to 2500 characters | Required |
| `reference_assets` | array | Required. Exactly one `source_video`; 0–4 reference images |
| `keep_original_sound` | boolean | Default `false`. Send `true` to keep the source audio |
| `duration` | 3–15 s | `-v2v` only; `5` when omitted |

To set how a new subject looks, add reference images, one entry each, and name them in the prompt, for example "the dog in Image 1":

```
{ "role": "reference", "asset_type": "image", "url": "https://example.com/dog.jpg" }
```

**The output follows the source clip, not the standard/pro 720p/1080p rule.** Given a 1280×720, 3-second source: `-video-edit` returns 1280×720, 3 s (pro too); `-v2v` without `duration` returns 1280×720, 5 s.

**Put the change in the first sentence of the prompt.** Name the target and its new state, and cover what to keep in one sentence. Listing everything to preserve, or asking the new subject to match the old one's look, can make the model change nothing: the task still `succeeded` and you get the original back. `succeeded` does not mean the edit took effect; check the video.

These mistakes are rejected at create, with no task and no charge:

- Video placed in `content[]` (with `role` `source_video` or `reference_video`) → `422 The parameter combination is not supported.`
- Reference image `role` written as `reference_image` or `image` → same error. Use `reference` here.

## Alibaba video models

`wan-2-7-t2v` / `wan-2-7-i2v` and the HappyHorse text/image/reference models use the same endpoint and `content[]` shape; the notes below are the model-specific parts. **`happyhorse-1.0-video-edit` is the exception: it uses a different endpoint** (see below).

| Model | Input | Duration | Billed resolution | Endpoint |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | text | 2–15 s | **always 1080P** (see caveat) | unified |
| `wan-2-7-i2v` | text + 1 `first_frame` | 2–15 s | **always 1080P** (see caveat) | unified |
| `happyhorse-1.1-t2v` | text | 3–15 s | 720p / 1080p as requested | unified |
| `happyhorse-1.1-i2v` | text + 1 `first_frame` | 3–15 s | 720p / 1080p as requested | unified |
| `happyhorse-1.1-r2v` | text + 1–9 `reference_image` | 3–15 s | 720p / 1080p as requested | unified |
| `happyhorse-1.0-video-edit` | 1 source video (3–60 s) + up to 5 reference images | follows the source clip | 720P / 1080P as requested | **video-synthesis** |

| Field | Values | Notes |
| --- | --- | --- |
| `resolution` | `720p`, `1080p` (lowercase) | only these two tiers |
| `ratio` | `16:9` etc. | used together with `resolution` |
| `duration` | whole seconds | ranges in the table above |
| `watermark` | boolean | |
| `seed` | integer | |
| `audio_setting` | | `-video-edit` only |

> **Some models may be temporarily unavailable**
>
> `wan-2-7-t2v`, `wan-2-7-i2v` and `happyhorse-1.1-t2v` can return `404 not_found_error — upstream returned 404` at create. The model is temporarily unavailable; the request is not wrong. No task is created and nothing is billed. For text-to-video, use `wan-2-7-video` (same `content[]` shape) or try again later.

> **wan-2-7 renders 1080P regardless of the requested resolution**
>
> `wan-2-7-t2v` / `wan-2-7-i2v` return a 1080P clip even when the request says `720p`, and billing follows what was produced — so a 5-second clip costs the 1080P rate. Budget for 1080P, or use `happyhorse-1.1-*` when you need 720P pricing.

> **HappyHorse accepts 720p and 1080p only**
>
> Sending `480p` is the same as sending nothing: the model uses its own default, rendering at roughly 1080P and billing at the 1080P rate. Send `720p` when you want 720P pricing.

### Text-to-video

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: hh-job-001" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "a horse galloping across a green field" }],
    "resolution": "720p", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
# → 202 { "id": "cgt_..." }
```

### Image-to-video

Add an image block with `role: "first_frame"`:

```
"content": [
  { "type": "text", "text": "the subject turns slowly toward the camera" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

### Reference-to-video

`happyhorse-1.1-r2v` takes 1 to 9 reference images, each with `role: "reference_image"`. Refer to them in the prompt as `[Image 1]`, `[Image 2]`, …:

```
"content": [
  { "type": "text", "text": "[Image 1] walks into the room shown in [Image 2]" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

### Video edit

For `happyhorse-1.0-video-edit`, **use the video-synthesis endpoint, not the unified one.** On the unified endpoint, create returns `400` with a message telling you to use this endpoint and put the video in `input.media[]`. After creating, poll `GET /omni/media/v1/tasks/{id}`:

```
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "happyhorse-1.0-video-edit",
    "input": {
      "prompt": "replace the background with a snowy street",
      "media": [
        { "type": "video",           "url": "https://example.com/source.mp4" },
        { "type": "reference_image", "url": "https://example.com/style.jpg" }
      ]
    },
    "parameters": { "resolution": "720P", "watermark": false }
  }'
# → 202 { "output": { "task_id": "cgt_...", "task_status": "PENDING" } }

curl https://api.atptoken.ai/omni/media/v1/tasks/cgt_... -H "Authorization: Bearer atp-..."
# → { "output": { "task_status": "SUCCEEDED", "video_url": "https://media.atptoken.ai/v/..." }, "usage": { … } }
```

- `input.media[].type` accepts only `video` and `reference_image`, and the URL field is `url` (not `video_url`).
- **A wrong body still gets `202` at create.** The error only shows when polling, as `InvalidParameter`, for example `InvalidParameter: Field required: input.media`. A successful create does not mean the body is right.
- The source video and every reference image must be directly downloadable without auth; if any one cannot be fetched, the task ends `FAILED` with `Failed to download …` and is not billed.
- This endpoint returns its own shape (`output.task_status`, `output.video_url`); after expiry it reports `SUCCEEDED` with `video_url: null`. Output length follows the source clip, not `parameters.duration`.
- This model can also return `404 not_found_error — upstream returned 404` at create: temporarily unavailable, not billed.
- Access, balance and billing rules are identical to the unified endpoint.

### Other model notes

- **Watermark**: HappyHorse has the watermark **on by default** — pass `watermark: false` to disable it. Wan 2.7 defaults to off.
- **Ratio**: HappyHorse also accepts `4:5`, `5:4`, `9:21`, `21:9` on top of the shared list.
- **Prompt length**: 5,000 characters (2,500 Chinese characters on HappyHorse).
- These models do not support `generate_audio` yet.

## Wan 3.0 and spicy: flat requests

`wan-3-0-video`, `wan-3-0-video-pro`, `wan-3-0-video-prime`, `wan-2-2-i2v-spicy` and `wan-2-7-i2v-spicy` **do not take `content[]`**; `prompt` and media go at the top level. A `content` array is dropped, and a body left empty returns `missing_prompt_or_image`.

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: wan3-job-001" \
  -d '{
    "model": "wan-3-0-video",
    "prompt": "a paper boat drifting on still water",
    "first_frame": "https://example.com/first-frame.png",
    "resolution": "480P",
    "ratio": "16:9",
    "duration": 4,
    "audio": false,
    "prompt_extend": false
  }'
# → 202 { "id": "cgt_..." }
```

**The two easiest mistakes: the audio field is `audio`, not `generate_audio`, and `resolution` is uppercase.**

| Field | Values | Default |
| --- | --- | --- |
| `prompt` | string | required |
| `first_frame`, `last_frame` | image URL | frame mode |
| `reference_images` | up to 10 URLs | reference mode |
| `reference_videos`, `reference_audios` | up to 5 URLs each | reference mode |
| `resolution` | `480P`, `720P`, `1080P`; `-pro` also `2K`, `4K` | `480P` |
| `duration` | `-1` (model default length, usually following the input video), or 2–30 s | `4` |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `adaptive` | `16:9` |
| `audio` | boolean | `false` |
| `prompt_extend` | boolean | `false` |

- Supports text-to-video, first frame, first and last frame, reference image plus reference audio, and reference video.
- A request uses frame mode **or** reference mode, never both.
- Sending `aspect_ratio`, `generate_audio`, `watermark` or `media` returns `400 Extra inputs are not permitted`. `content` is dropped and `input` is flattened into the top level; use neither.
- The two spicy models use the same flat shape and field-name rules as `wan-3-0-video*`.

## MiniMax H3

`minimax-h3` uses the `content[]` shape:

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: minimax-job-001" \
  -d '{
    "model": "minimax-h3",
    "content": [{ "type": "text", "text": "a paper boat drifting on still water" }],
    "resolution": "768P",
    "duration": 6
  }'
# → 202 { "id": "cgt_..." }
```

- `resolution` has only two tiers, `768P` and `2K`; `480p`, `720p`, `1080p` and `4k` map onto them.
- **Do not send `watermark`.** Both `false` and `"false"` are rejected at create with `400 invalid params, watermark is invalid (2013)`.

## Billing

Charges settle after the task reaches a terminal state, on **actual** usage:

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` is the input video length in seconds, `out_dur` the output length, and `W × H` the output size. When a model reports its own usage, that figure is used instead. The polled task's `usage` holds the token counts; video input is always 0. Rates are on the [pricing page](https://atptoken.ai/pricing/).

- **Create only makes a light reservation**: any positive balance passes; only an exhausted balance (`credit − inflight ≤ 0`) returns `402`.
- If the balance is short at settlement it goes negative, and **the next request is blocked**.
- Gating decides who can use a model, not what it costs; ungated models are billed the same way.
- Requests rejected at create create no task and are not billed. Failed tasks are not billed.
- Models that take an input video (for example `-r2v`, `-video-edit`) **also bill the input seconds**: a 5-second source producing a 5-second clip bills 10 seconds.

## Errors

**Read the 4xx message, not just the status code.** Model 4xx errors are passed through as-is, and the message usually names the field and the valid values. Include the response's `x-request-id` when reporting a problem.

- 400 — Malformed request: missing `model` or prompt, mixed asset sources, `asset_not_ready`, `asset_failed`. Read the message and fix it.
- 401 — `token_revoked`: the key is invalid, or **no key was sent at all**. Check that the header went out.
- 402 — `insufficient_quota`: the project balance is exhausted. Not a temporary limit; **do not retry** until you top up.
- 403 — `permission_denied`: the model is gated and the project is not allow-listed. Switch models or ask an administrator.
- 404 — At create, `upstream returned 404`: the model is temporarily unavailable; switch models or retry later. When polling: the task does not exist or is not yours.
- 409 — This `Idempotency-Key` already points at a task on another media surface; or you tried to cancel a `running` task.
- 422 — The outer shape or media role is not what the model expects; or the asset cannot be used with this model; or the model has no capacity right now.
- 429 — Rate limited. Back off and retry.
- 502 — Create failed. Safe to retry (the idempotency reservation is released).
- 503 — Enqueue failed, or `balance_check_unavailable` (**the balance could not be read; it is not insufficient**, and nothing was charged). Retry after `Retry-After`.

Common messages (all rejected at create, with no task and no charge):

| Message | Cause | Fix |
| --- | --- | --- |
| `422 The parameter combination is not supported.` | wrong outer shape or media role; most often Kling `-v2v` / `-video-edit` with the video in `content[]` | follow that model's example |
| `422 this asset's upstream does not serve the requested model` | the asset cannot be used with this model (e.g. `seedance-2-0-fast`) | pass a public URL |
| `400 may contain real person` | a public-URL image shows a real person | register it as an asset and pass the `AssetUri` |
| `400 The parameter content[1].image_url specified in the request is not valid` | `url` is not downloadable, e.g. an `an_…` id from `/v1/files` | pass a public URL or an `AssetUri` |
| `400 missing content[1].image_url` | the URL is at the block's top level | put it in `image_url: { "url": … }` |
| `400 Extra inputs are not permitted` | a flat model received a field it does not know | use that model's own field names |
| `400 invalid params, watermark is invalid (2013)` | the model does not accept `watermark` | remove `watermark` |

When the task itself fails, its status is `failed` and the reason is in `error`.

## Next steps

- [Seedance](https://atptoken.ai/docs/seedance-2-0/) — Seedance 2.0 and 2.5 model choice, media combinations, parameters and examples.
- [/v1/files](https://atptoken.ai/docs/files/) — upload files for chat and messages requests. Media tasks cannot use them.
- [Errors](https://atptoken.ai/docs/errors/) — what each status code means and what to check first.
