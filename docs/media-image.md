# Image generation

> Source: https://atptoken.ai/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

Image generation runs in **two steps**: create a task (`202` + task id), then poll until the status is terminal and download the signed URL. Point your client at the media base URL `https://api.atptoken.ai/omni/media/v1` and authenticate with a project `atp-` key. The gateway routes your unified `model` to an image provider (e.g. `gpt-image-2`); confirm names with `GET /v1/models`. The flow matches video generation.

- **Output is written to object storage and returned as a signed edge URL (`https://media-<env>.atptoken.ai/v/...`) with a **30-minute TTL** — never inline base64. Fetch it promptly.**
- Requests are refused with `402 insufficient_quota` when the project balance is ≤ 0.

> **Check the model with the same key first**
>
> Media availability depends on the environment and project. Call `GET https://api.atptoken.ai/v1/models` first; a model absent from that response is not available to that key.

#### Create a task

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "quality": "high", "n": 1 }'
# → 202 { "id": "img_..." }
```

| Field | Type | Notes |
|---|---|---|
| model | string · Req | unified image model (`image` pool) |
| prompt | string · Req | text prompt — **required on every image call, including edit-style models** (send a short instruction such as `"edit this image"` when the model is driven mainly by the input images) |
| size | string | model-specific; OpenAI images commonly use `1024x1024` |
| quality | string | forwarded to OpenAI-dialect upstreams (e.g. `high` / `medium`) |
| n | integer | number of images, 1–4 (default `1`) |
| reference_assets | array | **top-level** input images for edit-style models — `[{ "url": "…" }]`. See below. |

Reuse the same `Idempotency-Key` when retrying a create after a network failure; use a fresh key for a genuinely new task.

#### Input images for edit-style models — `reference_assets`

> **Verified against production 2026-08-04**
>
> Edit-style models (`nano-banana-pro-edit`, `qwen-image-edit-max`, …) take their input images in a **top-level `reference_assets` array of objects**. `content[]`, `image` and `image_url` are all rejected with `422 Invalid input.reference_assets: required.`, and a plain array of URL strings is rejected as `Invalid input.reference_assets`. It must be `[{ "url": "…" }]`.

```
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
# → 202 { "id": "img_..." }
```

**What `url` accepts** (image endpoint, verified 2026-08-04):

| Form | Image endpoint | Notes |
| --- | --- | --- |
| public `https://…` URL | works | must be fetchable by the upstream **without authentication** |
| `data:image/png;base64,…` | works | the whole payload travels in the request body — keep it small |
| `asset://<id>` / `asset://<pid>.<id>` | **not supported** | every attempt fails at generation time with `provider_error / generation_failed` |

The simplest way to turn an upload into a usable URL: `POST /v1/files` (the response key is **`id`**), then `GET /v1/files/{id}` **without following the redirect** and use the `Location` header — an object-store presigned URL that needs no auth and lives about 15 minutes. See [/v1/files](https://atptoken.ai/docs/files/).

`prompt` is still required on an edit call. A short instruction is enough, but the field cannot be omitted.

#### How per-image billing picks a size tier

Models billed per image are charged by the tier of the image **we actually deliver**, measured from its **longest side**:

| Longest side | Tier |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| larger | `4K` |

Two things worth knowing before you budget:

- **A model's default output can be wider than you expect.** For example a 1408×768 result (about 1.1 megapixels) has a longest side of 1408, so it is billed at the `2K` tier even though its pixel count is closer to a 1K image.
- **Some models ignore the requested `size`** and always return their native resolution. If the tier matters for your cost, read the dimensions of the returned image rather than assuming the request was honoured.

Only delivered images are billed — a failed generation, or one whose upload never completed, costs nothing. Where a model prices several tiers the same (Nano Banana, Nano Banana Pro), the tier makes no difference to what you pay.

#### Poll until terminal

Poll every 3–8 seconds:

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

- `status` transitions `queued` → `running` → `succeeded` / `failed` / `cancelled` / `expired`.
- A succeeded task's `data[].url` is a signed URL with a **30-minute TTL**; after expiry the task still reports `succeeded` with `expired: true` and a null `url` — download promptly (re-create to regenerate).
- `usage` reports token usage for billing transparency; a `failed` task carries a structured `error` object.
- **The extension in `data[].url` is not a reliable format signal** (verified 2026-08-04): a URL ending in `.png` can carry JPEG bytes. If the format matters — you are re-uploading the result, or converting it — sniff the bytes (magic number) rather than trusting the filename.

| Method | Path | Action |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | create |
| GET | /omni/media/v1/images/generations/tasks/{id} | poll |
| GET | /omni/media/v1/images/generations/tasks | list |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | cancel |

### Python example

A minimal create-and-poll flow:

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

if task["status"] == "succeeded":
    for i, item in enumerate(task["data"]):
        image = requests.get(item["url"], timeout=120).content  # signed URL, 30-min TTL
        with open(f"result_{i}.png", "wb") as f:
            f.write(image)
else:
    raise RuntimeError(task.get("error"))
```

### Errors

- 400 — missing `model` or `prompt`.
- 402 — `insufficient_quota`: project balance ≤ 0; top up and retry (don't hammer).
- 404 — task not found or not owned by this project (poll).
- 422 — the model has no image provider.
- 502 — upstream generation failed.
