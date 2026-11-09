# Image generation

> Source: https://atptoken.ai/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

Image generation is **asynchronous** — there is no synchronous version. It takes three steps: create a task (`202` + an `img_…` task id), poll until the status is terminal, then download `data[].url` within 24 hours. Point your client at the media base URL `https://api.atptoken.ai/omni/media/v1` and authenticate with a project `atp-` key. The flow matches video generation.

- **Output is a signed URL (`https://media-<env>.atptoken.ai/v/...`) valid for 24 hours** — never inline base64. Download it if you need to keep it; don't store the URL as a permanent link.
- Requests are refused with `402 insufficient_quota` when the project balance is ≤ 0.
- `callback_url` is accepted but **no webhook is ever sent**. You must poll.

> **Check which models this key can use**
>
> The complete list is `GET https://api.atptoken.ai/v1/project/models`: every model the project allows, text, image, video and audio alike. `GET /v1/models` lists only OpenAI-format chat models — **image models are not on it**. A model missing from a list is not necessarily unusable; a model you are not authorized for is refused with `403` when you create the task, and you are not billed.

## Create a task

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "nano-banana-pro", "prompt": "an isometric paper-craft city at golden hour", "aspect_ratio": "16:9", "image_size": "2K" }'
# → 202 { "id": "img_..." }
```

A `202` means the **image does not exist yet** — you get a task id. If you're unsure which model to use, start with `nano-banana-pro`.

| Field | Type | Notes |
|---|---|---|
| model | string · Req | image model name, e.g. `nano-banana-pro`, `qwen-image-3.0`, `gpt-image-2` |
| prompt | string | text prompt. Required by most models. Models driven only by image input (e.g. `face-swap` with `face_image`) can omit it. Sending neither a prompt nor an input image returns `400` |
| other fields | per model | everything except `model` is **forwarded under its own name and value**. See the next section for each model's fields |

> **Wrong fields don't error — they're ignored**
>
> A field the model doesn't recognize is **silently ignored**: the request still returns `202` and still produces an image, just not the one you wanted. The three most common:
>
> - `size: "1024x1024"` on `nano-banana*`: ignored. Use `image_size` + `aspect_ratio`.
> - top-level `size` on `qwen-image-3.0`: ignored. It reads only `parameters.size`.
> - `n: 4` on `nano-banana*`: ignored. Use `num_images`.
>
> To confirm a parameter took effect, compare the output — not the status code. Conversely, a value the model **recognizes but rejects** returns a 4xx whose message names the field and its valid values; follow it.

**Idempotency:** reuse the same `Idempotency-Key` when retrying a create after a network failure; use a fresh key for a genuinely new task. Image, video and audio each need their own keys: a key used first for video and then for an image returns `409`.

## Parameters by model

### nano-banana family

Applies to `nano-banana`, `nano-banana-2`, `nano-banana-pro`, and the editing models `nano-banana-edit`, `nano-banana-2-edit`, `nano-banana-pro-edit`.

| Field | Type | Notes |
|---|---|---|
| prompt | string · Req | text prompt — required on `-edit` models too |
| aspect_ratio | string | `auto` `21:9` `16:9` `3:2` `4:3` `5:4` `1:1` `4:5` `3:4` `2:3` `9:16` `4:1` `1:4` `8:1` `1:8` |
| image_size | string | `1K` / `2K` / `4K`. **`-pro` and `-2` only**; also the billing tier |
| num_images | integer | 1–4. **`-pro` and `-2` only** |
| output_format | string | `jpeg` / `png` / `webp` |
| seed | number | `-1` for random |
| safety_tolerance | string | `1`–`6`, default `6` |
| enable_web_search | boolean | **`-pro` and `-2` only** |
| thinking_level | string | `minimal` / `high`. **`-2` only** |
| reference_assets | array | input images, `[{ "asset_type": "image", "url": "…" }]`, up to 14 on the `nano-banana-2` family and up to 10 on `nano-banana` and `nano-banana-pro`. **Required on `-edit` models**; see "Editing" below |

This family does not read `size`, `quality` or `n`.

### qwen-image-3.0 / qwen-image-3.0-pro

These are the **only models whose parameters don't go at the top level**: they read only a nested `parameters` object and silently ignore top-level fields of the same name. `{"size": "1024*1024"}` does nothing; write `{"parameters": {"size": "1024*1024"}}`.

| Field (inside `parameters`) | Type | Notes |
|---|---|---|
| size | string | **asterisk** format `width*height`, e.g. `1024*1024` — not `1024x1024`. The area must be between 512×512 and 2560×2560; outside that the task fails with the actual area in the message. Also sets the billing tier (1k/2k/4k). Default 2048×2048 |
| n | integer | number of images; **each one is billed** |
| prompt_extend | boolean | **defaults to `true`**: the model rewrites your prompt (the response's `rewrite_status` is `success`). Send `false` to use your prompt as written |
| watermark | boolean | watermark |

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-image-3.0",
    "prompt": "a red square on a white background",
    "parameters": { "size": "1024*1024", "n": 1, "prompt_extend": false }
  }'
# → 202 { "id": "img_..." }
```

### gpt-image-2 / gpt-image-2-edit

These read the OpenAI Images vocabulary:

| Field | Type | Notes |
|---|---|---|
| prompt | string · Req | text prompt |
| size | string | **x** format, e.g. `1024x1024` |
| quality | string | image quality |
| n | integer | number of images, default `1` |
| images | array | **`gpt-image-2-edit` only, required**: 1–4 input images shaped `[{ "image_url": "…" }]`; a public https URL or a data URI |
| output_format | string | `png` (default), `jpeg`, `webp` |

### face-swap

This model **takes no text**. It has three parameters:

| Field | Type | Notes |
|---|---|---|
| image | string | the base image whose face is replaced |
| face_image | string · Req | the face to swap in. When present, `prompt` is not needed |
| seed | number | random seed |

Sending only `image` without `face_image` does not waive `prompt` — you get "prompt is required".

### Other image models

`qwen-image-edit-spicy`, `wan-2-7-image`, `wan-2-7-pro-image` and `z-image-spicy` have no documented parameter set. Send `model` + `prompt` (plus your input image) and read the response: a field the model recognizes but rejects returns a 4xx naming the field and its valid values. A successful request does not prove a field took effect — compare the output.

## Editing: where the input image goes

Same endpoint, same flow — but **each model family puts the input image in a different place**:

| Model | Input image goes in | Shape |
| --- | --- | --- |
| `nano-banana-edit`, `nano-banana-2-edit`, `nano-banana-pro-edit` | top-level `reference_assets` | `[{ "asset_type": "image", "url": "…" }]`, up to 14 on `nano-banana-2-edit`, 10 on the other two; required |
| `qwen-image-3.0`, `qwen-image-3.0-pro` | a content block in `messages` | `{ "type": "image", "image": "<data URI or URL>" }` — **not** `image_url` |
| `gpt-image-2-edit` | top-level `images` | `[{ "image_url": "…" }]`, 1–4, required. **Do not use `reference_assets`**: create succeeds but the task fails at poll time |
| `face-swap` | `image` and `face_image` | see the section above |

### nano-banana `-edit` models

> **Put input images in top-level `reference_assets`**
>
> Input images go in a **top-level `reference_assets` array of objects**: `[{ "asset_type": "image", "url": "…" }]`.
>
> - `content[]`, `image` and `image_url` are all rejected with `422 Invalid input.reference_assets: required.`
> - A plain array of URL strings is rejected as `Invalid input.reference_assets`.

```
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
# → 202 { "id": "img_..." }
```

`prompt` is still required when editing with this family. A short instruction is enough.

**What `url` accepts** (image endpoint):

| Form | Image endpoint | Notes |
| --- | --- | --- |
| public `https://…` URL | works | must be fetchable by the upstream **without authentication** |
| `data:image/png;base64,…` | works | the whole payload travels in the request body — keep the base64 under 2 MB; larger payloads can fail upstream |
| `asset://<id>` / `asset://<pid>.<id>` | **not supported** | every attempt fails at generation time with `provider_error / generation_failed` |

A `/v1/files` upload cannot be used here: its `an_<ulid>` is a chat file id, not a media reference, and `GET /v1/files/{id}` returns the file's bytes, not a URL. To use a local image, host it at a public `https://` URL, or send a small image as a `data:` URI. See [/v1/files](https://atptoken.ai/docs/files/).

### qwen-image editing

qwen-image edits go through `messages`; parameters still go in `parameters`:

```
{"model": "qwen-image-3.0",
 "parameters": {"size": "1024*1024", "n": 1, "prompt_extend": false},
 "messages": [{"role": "user", "content": [
   {"type": "image", "image": "data:image/png;base64,…"},
   {"type": "text",  "text": "make the square blue"}]}]}
```

- The image block is `{"type": "image", "image": …}`; these models don't accept the `image_url` shape.
- When you send `messages`, yours are used as-is. If you also send `prompt`, it is appended as a separate final user message — neither is dropped.

## Poll until terminal

Poll every 3–8 seconds. A task is visible as soon as it is created:

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

There are six statuses; four are terminal:

| Status | Terminal | Meaning |
| --- | --- | --- |
| `queued` | no | queued — keep polling |
| `running` | no | generating — keep polling |
| `succeeded` | yes | result is in `data[].url` |
| `failed` | yes | failed — reason in `error` |
| `expired` | yes | the result is gone |
| `cancelled` | yes | cancelled |

- **Exit the loop on all four terminal statuses.** A loop that waits only for `succeeded` spins forever on `failed`.
- **`succeeded` does not guarantee a file.** After 24 hours the status is still `succeeded`, but `data[].url` becomes `null` and `expired: true` appears. After checking `succeeded`, check that the URL is not `null`. The only way to get it back is to generate again.
- `data` is an array — one URL per image when you generate several. Walk the whole array to get them all.
- `usage` reports token usage; `meters` says what the task was actually metered on (per-image models have no tokens — read `meters`).
- A `failed` task carries an `error` object (`code`, `message`, plus `upstream_status` when the failure had an HTTP status).
- **Parameter-value errors may only show up when polling.** For the `nano-banana` family, `gpt-image-2` and the `qwen-image` family, create checks only the request shape; an invalid value surfaces as `failed` on poll — e.g. an out-of-range qwen-image size gives `{"code":"upstream_400","upstream_status":400,"message":"Image area must be between …"}`. The `kling-*` family instead returns errors at create, with the status code passed through unchanged.
- **The extension in `data[].url` is not a format signal**: a URL ending `.png` can carry JPEG bytes. If the format matters downstream (re-uploading the result, converting it), sniff the bytes (magic number) instead of trusting the filename.

| Method | Path | Action |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | create |
| GET | /omni/media/v1/images/generations/tasks/{id} | poll; `404` if not found or not your project's |
| GET | /omni/media/v1/images/generations/tasks | list this project's tasks |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | `queued` is cancelled; terminal deletes the record; `running` returns `409` and cannot be cancelled |

## Python example

A minimal create + poll loop:

```python
import os, time, requests

BASE = "https://api.atptoken.ai/omni/media/v1"
HEADERS = {
    "Authorization": f"Bearer {os.environ['ATP_API_KEY']}",
    "Content-Type": "application/json",
}

resp = requests.post(
    f"{BASE}/images/generations/tasks",
    headers={**HEADERS, "Idempotency-Key": "img-job-001"},
    json={
        "model": "gpt-image-2",
        "prompt": "a watercolor cat",
        "size": "1024x1024",
        "quality": "high",
        "n": 1,
    },
    timeout=60,
)
resp.raise_for_status()
task_id = resp.json()["id"]

while True:
    task = requests.get(
        f"{BASE}/images/generations/tasks/{task_id}", headers=HEADERS, timeout=60
    ).json()
    if task["status"] in ("succeeded", "failed", "cancelled", "expired"):
        break
    time.sleep(5)

if task["status"] != "succeeded":
    raise RuntimeError(task.get("error"))

for i, item in enumerate(task["data"]):
    if item.get("url") is None:  # signed URL expired after 24h (expired: true)
        raise RuntimeError("result expired; generate again")
    image = requests.get(item["url"], timeout=120).content  # signed URL, 24h TTL
    with open(f"result_{i}.png", "wb") as f:
        f.write(image)
```

## How per-image billing picks a size tier

The tier depends on the model:

- **`nano-banana-pro`, `nano-banana-2`**: the tier is the `image_size` you send (`1K` / `2K` / `4K`).
- **`qwen-image-3.0` family**: the tier is set by `parameters.size` (1k / 2k / 4k), and every image from `n` is billed.
- **Other per-image models**: the tier is set by the **image we actually deliver**, using its **longest side**:

| Longest side | Tier |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| larger | `4K` |

Two things to know before estimating cost:

- **A model's default output can be wider than you expect.** A 1408×768 result (about 1.1 megapixels) has a longest side of 1408, so it bills at `2K` — even though its pixel count is closer to a 1K image.
- **Some models ignore the requested `size`** and always return their native resolution. If the tier matters to your cost, read the dimensions of the image you got back rather than assuming your request was honored.

Only delivered images are billed — a failed generation or an incomplete upload is not. Where a model prices several tiers the same (Nano Banana, Nano Banana Pro), the tier doesn't change what you pay. For prices, see [pricing](https://atptoken.ai/docs/pricing-model/).

## Errors

Read the 4xx message, not just the status code: the model's own 4xx is passed through unchanged, and its message usually names the field and valid values. Include the response's `x-request-id` when you report a problem.

- 400 — missing `model`, or neither a prompt nor an input image. Read the message.
- 401 — `token_revoked`: invalid key — **also returned when no key was sent at all**. Check that the header actually went out.
- 402 — two sources: the project balance is exhausted (`insufficient_quota` — not a transient rate limit, **don't retry**; top up first), or the model's own 402, passed through.
- 403 — `permission_denied`: the model is restricted and your project is not on its allow-list. Not a key or balance problem; switch models or ask an admin for access. Not billed.
- 404 — on poll: the task doesn't exist or isn't your project's.
- 409 — on create: this `Idempotency-Key` already belongs to a task on another media surface; use a new key. On cancel: the task is `running` and can't be cancelled.
- 422 — the model has no available capacity (switch models), or the model's own `validation_error`, naming the field and valid values.
- 429 — the model is rate-limited. The response's `retryable` field says whether to retry; if so, back off and retry.
- 500 — the model's own 5xx, passed through unchanged.
- 502 — no response from the model (timeout, connection failure, unparseable body). Retryable.
- 503 — the task couldn't be queued, or `balance_check_unavailable` (**the balance couldn't be read — not insufficient balance**; nothing started, nothing charged). Both are retryable.

## Next steps

- [/v1/files](https://atptoken.ai/docs/files/) — Upload files for chat and messages requests. Media tasks cannot use them.
- [Video generation](https://atptoken.ai/docs/media-video/) — Video models use the same task flow.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means and what to check first.
