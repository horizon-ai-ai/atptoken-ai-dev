# Seedance video generation

> Source: https://atptoken.ai/docs/seedance-2-0/

`POST /omni/media/v1/contents/generations/tasks`

The Seedance family supports text-to-video, image-to-video, first and last frame control, reference images, reference video and reference audio, with optional generated audio. Every Seedance model uses the endpoint and `content[]` format described in [Video generation](https://atptoken.ai/docs/media-video/): create a task, poll until it is terminal, then download `content.video_url`. If unsure, use `seedance-2-0`.

## Choose a model

| Model ID | Best for | Resolution | Duration | How to pass media |
| --- | --- | --- | --- | --- |
| `seedance-2-0` | General use | `480p`, `720p`, `1080p`, `4k` | 4–15 s | public URL or asset |
| `seedance-2-0-fast` | Speed | `480p`, `720p` | 4–15 s | **public URL only** |
| `seedance-2-0-mini` | Lower cost | `480p`, `720p` | 4–15 s | depends on the combination, see below |
| `seedance-2-5` | More inputs, longer clips | `480p`, `720p`, `1080p` | `-1`, or 4–30 s | public URL or asset |

> **Check which models this key can use**
>
> Call `GET https://api.atptoken.ai/v1/project/models` with the same key you create tasks with; it is the project's complete list (`/v1/models` lists chat models only). A model missing from a list is not necessarily unusable; without permission, create returns `403` and nothing is billed.
>
> The model ID is `seedance-2-0-mini`. `seedance-2-mini` is not an alias for it and returns `400 InvalidParameter`.

## Generation modes

| Mode | What to send |
| --- | --- |
| Text-to-video | A text part only |
| Image-to-video | One image part with `role: "first_frame"` |
| First and last frame | Image parts with `first_frame` and `last_frame` |
| References | One or more `reference_image`, `reference_video` or `reference_audio` parts |
| Generated audio | `generate_audio: true` |

First/last frame and references are different operations. A first frame becomes the opening shot of the video; a reference image only supplies a look, style or character and is not used as the opening shot.

### Supported media combinations

| Model | Supported combinations (all also support text only) |
| --- | --- |
| `seedance-2-0` | first frame; first + last frame; reference image; reference image + reference audio; reference video; image + video + audio together |
| `seedance-2-0-fast` | first frame; first + last frame; reference image (all via public URL) |
| `seedance-2-0-mini` | first frame (public URL); first + last frame (asset); up to 3 reference images (public URL) |
| `seedance-2-5` | reference audio only; first + last frame; reference image; reference image + reference audio; reference video |

### Media limits

| Model | Images | Videos | Audio |
| --- | --- | --- | --- |
| `seedance-2-0`, `-fast`, `-mini` | 9 | 3 | 3, **not on its own** |
| `seedance-2-5` | 30 | 10 | 10, **audio alone is allowed** |

### Media roles

| Role | Part type | Use |
| --- | --- | --- |
| `first_frame` | `image_url` | The opening frame. |
| `last_frame` | `image_url` | The closing frame. |
| `reference_image` | `image_url` | Look, style or character reference. |
| `reference_video` | `video_url` | Motion or style reference. |
| `reference_audio` | `audio_url` | Sound reference. Only `seedance-2-5` accepts reference audio on its own. |

## Parameters

| Field | Values | Default | Notes |
| --- | --- | --- | --- |
| `model` | See "Choose a model" | | Required. |
| `content` | Text plus optional media parts | | Required. |
| `resolution` | Per model, see "Choose a model" | `480p` | `480p` is good for low-cost tests. `4k` is `seedance-2-0` only; `-fast` and `-mini` top out at `720p`. |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `21:9`, `adaptive` | `16:9` | See below for requests with a first frame. |
| `duration` | Whole seconds, see "Choose a model" | `4` | `4` is the cheapest functional test. `seedance-2-5` also takes `-1`: the model uses its default length, which usually follows the input video when there is one; billed on the actual output length. |
| `generate_audio` | `true`, `false` | `false` | Ask the model to generate a soundtrack too. |
| `return_last_frame` | `true`, `false` | | When enabled, a finished task also carries `content.last_frame_url`. |
| `output_format` | `mp4`, `mov` | `mp4` | `seedance-2-5` only. |

### Aspect ratio with a first frame

- **`seedance-2-0` family (including fast and mini): `ratio` sets the output shape, not the first frame.** `ratio` defaults to `16:9`, so a portrait first frame without a ratio gives a landscape video (864×496 at 480p), reframed. Send `ratio: "adaptive"` and the output follows the frame (portrait frame → 496×864).
- **`seedance-2-5`:** with first and last frames, **do not send `ratio`**. Without them you can, for example `ratio: "16:9"`.

## Passing media

`content[].image_url.url` can hold a public `https://` URL, base64, or an `asset://…` URI (`AssetUri`) from the asset API. How to register assets, common mistakes and queueing rules are in [Video generation](https://atptoken.ai/docs/media-video/) under "Passing media".

| Model | Public URL | Asset (`asset://`) |
| --- | --- | --- |
| `seedance-2-0` | yes | yes |
| `seedance-2-0-mini` | use for first frame and reference images | use for first + last frame |
| `seedance-2-0-fast` | the only option | returns `422 this asset's upstream does not serve the requested model` |
| `seedance-2-5` | yes | yes |

A `/v1/files` file id (`an_…`) is not a media URL and returns `400`.

> **Asset names are at most 64 characters**
>
> When registering assets for `seedance-2-0` or `seedance-2-0-mini`, a `name` over 64 characters still gets 200 at registration, but `assets/get` reports failure (`InvalidParameter.Name`) and the task gets `ATP_ASSET_FAILED`. This is not intermittent: shorten `name`; there is no need to switch to public URLs.

### Photos of real people

A public URL of a photo of a real person can be rejected with `400 … may contain real person`. When that happens, register the same image as an asset and pass the `AssetUri`; no identity verification is needed. `seedance-2-0-fast` cannot use assets, so **real-person photos and `-fast` do not go together**; use `seedance-2-0` or `seedance-2-5`. If your product requires identity verification, the flow is in [Video generation](https://atptoken.ai/docs/media-video/) under "Photos of real people".

## Examples

Every example below is sent to the same endpoint:

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-video-job-001" \
  --data-binary @request.json
# → 202 { "id": "cgt_..." }
```

Save any of the bodies below as `request.json`. When you resend the same request after a network failure, reuse the same `Idempotency-Key`; use a new key for a new piece of work.

### Text-to-video

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "A cinematic tracking shot of Taipei at night, neon reflections, smooth camera motion" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

### Image-to-video

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "Animate this product shot with a slow premium studio push-in." },
    { "type": "image_url", "image_url": { "url": "https://example.com/product.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "ratio": "adaptive",
  "duration": 4,
  "generate_audio": false,
  "return_last_frame": true
}
```

Keep `"ratio": "adaptive"`; see "Aspect ratio with a first frame" above.

### First and last frame (Seedance 2.5)

```json
{
  "model": "seedance-2-5",
  "content": [
    { "type": "text", "text": "Create a smooth transition from morning to night with consistent camera framing." },
    { "type": "image_url", "image_url": { "url": "https://example.com/morning.jpg" }, "role": "first_frame" },
    { "type": "image_url", "image_url": { "url": "https://example.com/night.jpg" }, "role": "last_frame" }
  ],
  "resolution": "720p",
  "duration": 6,
  "generate_audio": false,
  "output_format": "mp4"
}
```

`ratio` is left out on purpose; see "Aspect ratio with a first frame" above.

### Reference image plus reference video

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "The character from the reference image dances with the motion of the reference video." },
    { "type": "image_url", "image_url": { "url": "https://example.com/character.jpg" }, "role": "reference_image" },
    { "type": "video_url", "video_url": { "url": "https://example.com/motion.mp4" }, "role": "reference_video" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

## Get the result

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_xxx \
  -H "Authorization: Bearer $ATP_API_KEY"
```

Keep polling until `status` is `succeeded`, `failed`, `cancelled` or `expired`. On success, download the video from `content.video_url`. The URL expires after **24 hours**: the status stays `succeeded`, but `video_url` becomes `null` and `expired: true` appears. Copy the file to your own storage within that window.

## Billing

Video is billed on video tokens, settled on actual usage once the task is terminal:

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` is the input video length in seconds and `out_dur` the output length. When a model reports its own usage, that figure is used. Failed tasks are not billed. The cheapest end-to-end smoke test is `480p`, `duration: 4`, `generate_audio: false`.

**Price per second of output · 480p**

| Item | USD / s |
|---|---:|
| seedance-2-0 | $0.07 |
| seedance-2-0-fast | $0.0538 |

## Next steps

- [Video generation](https://atptoken.ai/docs/media-video/) — endpoint reference, including accepted `url` forms, the asset API and error codes.
- [Pricing](https://atptoken.ai/docs/pricing-model/) — how usage billing and per-model rates work.
- [How credits work](https://atptoken.ai/docs/credits/) — how usage is deducted from credits.
