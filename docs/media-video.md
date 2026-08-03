# Video generation

> Source: https://atptoken.ai/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

Video generation is **asynchronous**: create a task (`202` + task id), poll until the status is terminal, then read the signed URL. Same base URL and `atp-` key as image. The gateway routes your unified `model` to a video provider with same-name failover. Available video models: `seedance-2-0` (standard), `seedance-2-0-mini` (lighter / lower cost), `seedance-2-0-fast` (faster rendering), and the Kling family (preview): `kling-v3-standard`/`-pro`, `kling-o3-standard`/`-pro` with `-i2v` / `-reference` / `-reference-7` / `-v2v` / `-video-edit` variants — all billed per second by resolution (Kling audio generation not yet available); plus the Alibaba family (preview): `wan-2-7-t2v`, `wan-2-7-i2v`, `happyhorse-1.1-t2v`, `happyhorse-1.1-i2v`, `happyhorse-1.1-r2v` (up to 9 reference images) and `happyhorse-1.0-video-edit` (source clip 3–60 s + up to 5 reference images). HappyHorse duration is 3–15 s and its watermark defaults to on (pass `watermark: false`); `wan-2-7-*` currently renders and bills 1080P regardless of the requested resolution. Confirm names with `GET /v1/models`.

- **A succeeded task carries `content.video_url` — a signed edge URL with a **30-minute TTL**. After expiry the task still reports `succeeded` but `video_url` is `null` and `expired: true` (re-create to regenerate).**
- Requests are refused with `402 insufficient_quota` when the project balance is ≤ 0.

> **Check the model and project permission first**
>
> Call `GET https://api.atptoken.ai/v1/models` with the same key used to create the task. If a model is absent, that project cannot use it; installing a skill or knowing the model name does not bypass allowed models.

#### Create a task

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
# → 202 { "id": "task_..." }
```

| Field | Type | Notes |
|---|---|---|
| model | string · Req | unified video model (`video` pool) |
| content | array · Req | multimodal input blocks (see below) |
| resolution | string | `480p` / `720p` / `1080p` / `4k` |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` (alias `aspect_ratio`) |
| duration | integer | seconds (mutually exclusive with `frames`) |
| frames | integer | frame count (alt to `duration`) |
| generate_audio | boolean | add a soundtrack (alias `add_audio`) |
| seed | integer | |
| watermark | boolean | |

**`content[]` blocks** — Each block is `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`. Text only → text-to-video; include an image → image-to-video. `image_url`/`video_url` take `{ "url": "<https | base64 | asset://pid.id>" }`; `role` is `first_frame` / `last_frame` / `reference_image` / `reference_video`.

#### Poll until terminal

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/task_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| Method | Path | Action |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | create |
| GET | /omni/media/v1/contents/generations/tasks/{id} | poll |
| GET | /omni/media/v1/contents/generations/tasks | list |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | cancel |

### Alibaba video models — model guide

`wan-2-7-t2v` / `wan-2-7-i2v` and the HappyHorse text/image/reference models use the same unified endpoint and `content[]` shape as every other video model — the notes below are the model-specific parts. **`happyhorse-1.0-video-edit` is the exception: it is served on a separate DashScope-compatible endpoint** (see below).

| Model | Input | Duration | Resolution billed | Endpoint |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | text | 2–15 s | **always 1080P** (see caveat) | unified |
| `wan-2-7-i2v` | text + 1 first-frame image | 2–15 s | **always 1080P** (see caveat) | unified |
| `happyhorse-1.1-t2v` | text | 3–15 s | 720P / 1080P as requested | unified |
| `happyhorse-1.1-i2v` | text + 1 first-frame image | 3–15 s | 720P / 1080P as requested | unified |
| `happyhorse-1.1-r2v` | text + 1–9 reference images | 3–15 s | 720P / 1080P as requested | unified |
| `happyhorse-1.0-video-edit` | 1 source video (3–60 s) + up to 5 reference images | follows the source clip | 720P / 1080P as requested | **DashScope** |

> **wan-2-7 renders 1080P regardless of the requested resolution**
>
> `wan-2-7-t2v` / `wan-2-7-i2v` currently return a 1080P clip even when the request says `720P`, and billing follows what was produced — so a 5-second clip costs the 1080P rate. Budget for 1080P, or use `happyhorse-1.1-*` when you need 720P pricing.

> **HappyHorse accepts 720P and 1080P only**
>
> These models support `720P` and `1080P`. A request for `480P` is **not** rejected — it renders at roughly 1080P and is billed at the 1080P rate. Send `720P` when you want 720P pricing.

**Text-to-video**

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "a horse galloping across a green field" }],
    "resolution": "720P", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
```

**Image-to-video** — add one image block with `role: "first_frame"`:

```
"content": [
  { "type": "text", "text": "the subject turns slowly toward the camera" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

**Reference-to-video** (`happyhorse-1.1-r2v`) — 1 to 9 reference images, each with `role: "reference_image"`. Refer to them in the prompt as `[Image 1]`, `[Image 2]`, …:

```
"content": [
  { "type": "text", "text": "[Image 1] walks into the room shown in [Image 2]" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

**Video editing** (`happyhorse-1.0-video-edit`) — **use the DashScope-compatible endpoint, not the unified one.** The unified endpoint rejects this model with `400 video-edit requires a source video`. Create the task with `input.media[]` and poll `GET /omni/media/v1/tasks/{id}`:

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

`input.media[].type` accepts `video` or `reference_image` only, and the URL key is `url` (not `video_url`). Every URL — source clip and reference images alike — must be publicly downloadable without authentication; if any of them cannot be fetched the task ends `FAILED` with `Failed to download …` and is not billed. This endpoint returns the DashScope response shape (`output.task_status`, `output.video_url`), and the output length currently follows the source clip rather than `parameters.duration`.

**Billing** — per second of output at the requested resolution, metered as video tokens (`width × height × seconds × 24 fps ÷ 1024`). For `-r2v` and `-video-edit` the input clip's seconds are billed too, so a 5-second edit of a 5-second source bills 10 seconds. Failed tasks are not billed. Rates are on the [pricing page](https://atptoken.ai/pricing/).

**Other model-specific notes**

- **Watermark**: HappyHorse has the watermark **on by default** — pass `watermark: false` to disable it. Wan 2.7 defaults to off.
- **Ratio**: HappyHorse also accepts `4:5`, `5:4`, `9:21`, `21:9` on top of the shared list.
- **Prompt length**: 5,000 characters (HappyHorse: 2,500 for Chinese text).
- `generate_audio` is not available on these models yet.

### Errors

- 400 — invalid request body.
- 402 — `insufficient_quota`: project balance ≤ 0 (create only; poll / list / cancel stay open).
- 403 — `permission_denied`: the gated model is not enabled for this project.
- 422 — the model has no video provider.
- 502 — upstream generation failed.
