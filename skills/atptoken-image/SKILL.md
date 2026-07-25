---
name: atptoken-image
description: Generate images through the Atptoken LLM Gateway media surface at /omni/media/v1. Synchronous — the response carries a short-lived signed URL (never inline base64). Two client surfaces — OpenAI Images (POST /images/generations) and Gemini-native (POST /models/{model}:generateContent). Use for nanobanana / gpt-image-2 and other image models via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken image generation

Image generation is **synchronous** — one request returns one response with the result. The gateway routes your unified `model` to a real image provider from the `image` pool. Two client surfaces share the same pool; use whichever matches your SDK.

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` + `Content-Type: application/json`
- **Model:** a unified image model name — confirm with `GET /v1/models`. Examples: `gpt-image-2`, `nanobanana`.

**Output delivery:** the upstream base64 is written to object storage inline and returned as a signed edge URL `https://media-<env>.atptoken.ai/v/...?exp=&sig=` with a **30-minute TTL** — never inline base64. Fetch it promptly.

**Balance gate:** refused with `402 insufficient_quota` when the project balance is ≤ 0.

---

## OpenAI Images surface — `POST /omni/media/v1/images/generations`

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "n": 1 }'
```

**Request body**

| Field | Type | Req | Notes |
|---|---|:--:|---|
| `model` | string | ✅ | unified image model (`image` pool) |
| `prompt` | string | ✅ | text prompt |
| `size` | string | | e.g. `1024x1024` |
| `quality` | string | | forwarded to OpenAI-dialect upstreams |
| `n` | int | | number of images (default `1`) |

### Qwen Image Edit Max

Use `qwen-image-edit-max` for text edits, object changes, style transfer, and
multi-image fusion:

```bash
curl https://api.atptoken.ai/omni/media/v1/images/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-image-edit-max",
    "images": [
      "https://example.com/person.jpg",
      "https://example.com/background.jpg"
    ],
    "prompt": "Place the person from Image 1 in the setting from Image 2",
    "negative_prompt": "blurry, low quality",
    "size": "1024*1024",
    "n": 2,
    "prompt_extend": true,
    "seed": 42
  }'
```

- `images`: required, 1–3 public URLs or base64 images. JPG/JPEG/PNG/BMP/TIFF/
  WEBP and the first frame of a GIF are accepted; each image is at most 10 MB
  with width and height from 384–3072 px.
- `prompt`: required, Chinese or English, up to 800 characters. Refer to inputs
  as “Image 1”, “Image 2”, and “Image 3” for fusion tasks.
- `negative_prompt`: optional, up to 500 characters.
- `size`: optional `width*height`; each dimension must be 512–2048. If omitted,
  the output stays near the last input image's aspect ratio at about 1024×1024.
- `n`: 1–6 delivered images; each delivered image is billed separately.
- `prompt_extend`: prompt rewriting, default `true`; `seed`: 0–2147483647.

ATP still returns this asynchronous upstream model through the synchronous image
surface: the gateway waits for completion and returns the normal `data[].url`
response. The caller does not poll an upstream task.

**Response `200`:**
```json
{ "created": 1781776187,
  "data": [ { "url": "https://media-prod.atptoken.ai/v/image/img_...png?exp=...&sig=..." } ] }
```

---

## Gemini-native surface — `POST /omni/media/v1/models/{model}:generateContent`

For Google GenAI SDK users. The model is in the URL path; the prompt is in the Gemini body. Point the SDK's base URL at `.../omni/media/v1` and it appends `/models/{name}:generateContent` itself.

```bash
curl "https://api.atptoken.ai/omni/media/v1/models/nanobanana:generateContent" \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "contents": [ { "role": "user", "parts": [ { "text": "a watercolor cat" } ] } ],
    "generationConfig": { "responseModalities": ["IMAGE"] }
  }'
```

**Request:** `contents[]` (required — each `{ role, parts: [{ text }] }`; prompt comes from `parts[].text`), optional `generationConfig.responseModalities: ["IMAGE"]`.

**Response `200`** (Gemini shape, `fileUri` is a signed media URL — not inline base64):
```json
{ "candidates": [ { "content": { "parts": [
  { "fileData": { "mimeType": "image/png", "fileUri": "https://media-prod.atptoken.ai/v/..." } } ],
  "role": "model" }, "finishReason": "STOP", "index": 0 } ] }
```

> The two surfaces are decoupled from the upstream: `nanobanana` (Gemini 2.5 Flash Image) and `gpt-image-2` (OpenAI GPT-Image-2) can each be reached from either surface, depending on how the model's provider is configured.

---

## Errors

| Status | Meaning |
|---|---|
| `400` | missing `model` or `prompt` |
| `402` `insufficient_quota` | project balance ≤ 0 — top up and retry (don't hammer) |
| `422` | the model has no image provider |
| `502` | upstream generation failed |

Model names are configuration — confirm the live catalogue with `GET /v1/models`. For video or audio see the **atptoken-video** / **atptoken-audio** skills; for auth and the cross-surface error table see **atptoken-gateway**.
