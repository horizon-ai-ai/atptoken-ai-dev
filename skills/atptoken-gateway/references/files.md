# Files through the gateway

Upload a file once, get a reference id, and use that id in later chat and messages requests instead of re-sending the bytes. The gateway forwards the file to the providers and keeps no copy, so an id lasts **one hour**. The id is for chat only — the media endpoints (image, video, audio) cannot use it.

## Upload — `POST /v1/files`

`multipart/form-data` with a `file` part that carries a `Content-Type`. Maximum size **20 MB** (images, documents and audio alike).

The upload takes **no `model`**: every file-capable model on the project's allow-list receives it, so the id can be used with any of them later.

`purpose` and any other form fields are forwarded to the providers as sent, and the gateway adds no default. Accepted values differ by provider (common ones: `assistants`, `user_data`, `file-extract`, `batch`), and a provider that refuses the upload does not hold the file. Use `assistants` for a file you will reference in chat: some providers accept `user_data` at upload, then answer the chat request with `404 Files [file-…] were not found`.

```bash
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -F "file=@./data.csv" \
  -F "purpose=assistants"
```

Response `200` (OpenAI Files-compatible):

```json
{
  "id":         "an_01J9ZK7VQHX3M9PNQ4ABCDEFGH",
  "object":     "file",
  "bytes":      152340,
  "created_at": 1714579200,
  "expires_at": 1714582800,
  "filename":   "data.csv",
  "purpose":    "assistants",
  "mime_type":  "text/csv"
}
```

Use the returned `id` to reference the file in subsequent chat/messages requests. After `expires_at` the id is dead and the bytes are gone; upload the file again.

**No deduplication:** every upload returns a different `id`, even for identical bytes.

**Supported audio MIME types:** `audio/wav`, `audio/mpeg`, `audio/mp4`, `audio/flac`, `audio/ogg`, `audio/webm`, `audio/opus`, `audio/aac`, `audio/x-m4a`, `audio/pcm`.

**Errors:** `400` (no file part, no `Content-Type`, or no model in this project supports file uploads — the message says so) · `413` (over 20 MB) · `500` (internal error, e.g. reading the uploaded bytes failed) · `502` (the upload was refused; the message, after `no provider accepted this file:`, carries the providers' own status and body — up to three distinct reasons, e.g. `files_api not supported in your workspace.` or `'purpose' must be one of ['file-extract', 'batch']`) · `503` (no provider could complete the request; retry later).

## Reference it in chat

OpenAI entry point (`POST /v1/chat/completions`) — an `input_file` block:

```json
{
  "model": "gpt-4o",
  "messages": [{ "role": "user", "content": [
    { "type": "input_file", "input_file": { "file_id": "an_01J9ZK7VQHX3M9PNQ4ABCDEFGH" } },
    { "type": "text", "text": "Summarize the key points of this document." }
  ]}],
  "max_tokens": 1024
}
```

Anthropic entry point (`POST /v1/messages`) — a `document` block (or `image` block) with `source.type: "file"`:

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "messages": [{ "role": "user", "content": [
    { "type": "document", "source": { "type": "file", "file_id": "an_01J9ZK7VQHX3M9PNQ4ABCDEFGH" } },
    { "type": "text", "text": "Summarize the key points of this document." }
  ]}]
}
```

The same id works on both entry points without re-uploading. If a model can't read the file, the request moves to other available capacity and errors only when all of it is exhausted.

**Gemini models cannot use an `id`** — models on the `:generateContent` entry point return an error when you reference one, and they don't warn you in advance. Send the file inline with `inline_data`.

## Gemini SDK uploads — `/upload/v1beta/files`

The `google-genai` SDK uploads in two steps:

1. `POST https://api.atptoken.ai/upload/v1beta/files` with headers only. **`x-goog-upload-header-content-type` is required** (missing → `400`, before any bytes are sent); `x-goog-upload-header-content-length` over 20 MB → `413` and no upload URL. The step-two URL is in the `x-goog-upload-url` response header.
2. `POST` or `PUT` the bytes to that URL. Actual bytes over 20 MB → `413`. The token is spent on completion; replaying it → `404`.
3. The response's `file.uri` is an `an_<ulid>` with the same one-hour, no-retained-bytes rules.

The returned URL keeps the API version you started with (`/upload/v1/files` → `/upload/v1/files/{token}`). Files uploaded this way still **cannot** be used by Gemini-entry models — use `inline_data` for those.

## Retrieve — `GET /v1/files/{id}`

```bash
curl https://api.atptoken.ai/v1/files/an_01J9ZK7VQHX3M9PNQ4ABCDEFGH \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" -o data.csv
```

Returns `200` with the file's bytes, read back from a provider that holds it, with that provider's `Content-Type` and `Cache-Control: no-store`. There is no redirect, and not every provider supports this read: a file uploaded with a `purpose` that isn't readable returns `400`, and when no provider can return the file you get the provider's own status and words after `upstream refused to return this file:`. An expired id, an unknown id, and another organization's id all return the same `404`. `502` means the provider couldn't be reached.

## Using a file with the media endpoints

The image and video endpoints under `/omni/media/v1` cannot use a `/v1/files` upload. The `id` is not a media reference, `asset://<file id>` fails during generation with `provider_error / generation_failed`, and `GET /v1/files/{id}` returns bytes, not a URL a provider can fetch. Putting an `an_<ulid>` — or `https://api.atptoken.ai/v1/files/{id}` — in `image_url.url` returns `400 The parameter content[1].image_url specified in the request is not valid`.

What each endpoint accepts for a reference URL:

| Form | Image (`/images/generations/tasks`) | Video (`/contents/generations/tasks`) |
|---|---|---|
| public `https://…` URL | works | works |
| `data:image/png;base64,…` | works (nano-banana `reference_assets`, qwen-image `messages` image block) | rejected — `invalid_parameters: The parameter combination is not supported.` |
| `asset://…` (`AssetUri` from the asset API) | not supported | works on models that take assets (e.g. Seedance); `seedance-2-0-fast` refuses with `422 this asset's upstream does not serve the requested model` |

So the portable pattern is: host the file at a public `https://` URL the provider can fetch **without authentication**, then pass it as:

- nano-banana `-edit` image editing → top-level `reference_assets: [{ "asset_type": "image", "url": REF_URL }]`
- qwen-image editing → a `messages` content block `{ "type": "image", "image": REF_URL }`
- video → `content: [{ "type": "image_url", "image_url": { "url": REF_URL }, "role": "first_frame" }]`

Registering an asset also takes a public URL, so a local file has to be hosted first either way.
