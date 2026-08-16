# Seedance 2.0 video generation

> Source: https://atptoken.ai/docs/seedance-2-0/

`POST /v1/media/v1/contents/generations/tasks`

Seedance 2.0 is the current video generation model on ATP. It supports text-to-video, image-to-video, first and last frame control, reference images, optional generated audio, and async task polling.

> **Model id**
>
> Use `seedance-2-0` in the `model` field. Other Seedance variants may exist in internal pricing data, but they are not exposed in the public catalog yet.

### Parameters

| Field | Accepted values | Notes |
| --- | --- | --- |
| `model` | `seedance-2-0` | Required. |
| `resolution` | `480p`, `720p`, `1080p`, `4k` | `480p` is best for draft tests. 4K uses its own billing tier. |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `21:9`, `adaptive` | Cost follows rendered pixels, so square video is cheaper than 16:9 at the same tier. |
| `duration` | integer seconds, `4` to `15` | Use `4` for the cheapest functional test. |
| `generate_audio` | `true`, `false` | Ask the model to generate audio with the video. |
| `return_last_frame` | `true`, `false` | When enabled, completed task output can include the final frame URL. |
| `content` | text plus optional media parts | Use `role` on image/video/audio parts to explain how the asset should be used. |

### Media roles

| Role | Purpose |
| --- | --- |
| `first_frame` | The starting frame for image-to-video. |
| `last_frame` | The ending frame for controlled transitions. |
| `reference_image` | Visual, style, or character reference. This is not the same as a boundary frame. |
| `reference_video` | Motion or style reference video. |
| `reference_audio` | Audio reference when supported by the selected workflow. |

### Text to video

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks" \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "seedance-2-0",
    "content": [
      {
        "type": "text",
        "text": "A cinematic tracking shot of Taipei at night, neon reflections, smooth camera motion"
      }
    ],
    "resolution": "480p",
    "ratio": "16:9",
    "duration": 4,
    "generate_audio": false
  }'
```

The create response returns a task id such as `cgt_...`.

### Image to video

Use an HTTPS image URL, base64 image URL, or an uploaded `asset://...` reference.

```json
{
  "model": "seedance-2-0",
  "content": [
    {
      "type": "text",
      "text": "Animate this product shot with a slow premium studio push-in."
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "https://example.com/product.jpg"
      },
      "role": "first_frame"
    }
  ],
  "resolution": "720p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false,
  "return_last_frame": true
}
```

### First and last frame

```json
{
  "model": "seedance-2-0",
  "content": [
    {
      "type": "text",
      "text": "Create a smooth transition from morning to night with consistent camera framing."
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "asset://tya_first_frame"
      },
      "role": "first_frame"
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "asset://tya_last_frame"
      },
      "role": "last_frame"
    }
  ],
  "resolution": "720p",
  "ratio": "16:9",
  "duration": 6,
  "return_last_frame": true
}
```

### Poll the task

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks/cgt_xxx" \
  -H "Authorization: Bearer $ATP_API_KEY"
```

Poll until the task reaches `succeeded`, `failed`, or `canceled`. Successful responses include the generated video URL and usage metadata.

### Billing

Video is billed on video tokens:

```text
video_tokens = width × height × seconds × 24 ÷ 1024
cost = video_tokens × resolution_rate
```

Failed tasks are not billed. Use `480p`, `duration: 4`, and `generate_audio: false` for the cheapest end-to-end smoke test.
