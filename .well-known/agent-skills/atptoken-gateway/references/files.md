# Files through the gateway

Upload a file once, get a reference id, and use that id in later chat and messages requests instead of re-sending the bytes. The gateway forwards the file to the providers and keeps no copy, so an id lasts **one hour**.

## Upload — `POST /v1/files`

`multipart/form-data` with a `file` part that carries a `Content-Type`. Maximum size **20 MB**.

`purpose` and any other form fields are forwarded to the providers as sent, and the gateway adds no default. Accepted values differ by provider, and a provider that refuses the upload does not hold the file. Use `assistants` for a file you will reference in chat: some providers accept `user_data` at upload, then answer the chat request with `404 Files [file-…] were not found`.

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

Use the returned `id` to reference the file in subsequent chat/messages requests. After `expires_at` the id is dead; upload the file again.

**No deduplication:** every upload returns a different `id`, even for identical bytes.

**Gemini models cannot use an `id`.** Send the file inline with `inline_data`.

**Errors:** `400` (no file part, no `Content-Type`, or no model in this project has a provider with a Files API) · `413` (over 20 MB) · `503` (no provider could complete the request; retry later). When every provider refuses with a client error, you get that status and their words after `no provider accepted this file:`.

## Retrieve — `GET /v1/files/{id}`

```bash
curl https://api.atptoken.ai/v1/files/an_01J9ZK7VQHX3M9PNQ4ABCDEFGH \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" -o data.csv
```

Returns `200` with the file's bytes, read back from a provider that holds it. There is no redirect, and not every provider supports this read: when none can return the file, you get the provider's status and words after `upstream refused to return this file:`. An expired id, an unknown id, and another organization's id all return `404`.

## Using a file with the media endpoints

The image and video endpoints under `/omni/media/v1` cannot use a `/v1/files` upload. The `id` is not a media reference, `asset://<file id>` fails during generation with `provider_error / generation_failed`, and `GET /v1/files/{id}` returns bytes, not a URL a provider can fetch.

What each endpoint accepts for a reference URL:

| Form | Image (`/images/generations/tasks`) | Video (`/contents/generations/tasks`) |
|---|---|---|
| public `https://…` URL | works | works |
| `data:image/png;base64,…` | works | works — keep it under 2 MB (Wan 3.0: see the video skill) |
| `asset://…` (`AssetUri` from the asset API) | not supported | works (Seedance) |

So the portable pattern is: host the file at a public `https://` URL the provider can fetch **without authentication**, then pass it as:

- image editing → top-level `reference_assets: [{ "url": REF_URL }]`
- video → `content: [{ "type": "image_url", "image_url": { "url": REF_URL }, "role": "first_frame" }]`

Registering an asset also takes a public URL, so a local file has to be hosted first either way.
