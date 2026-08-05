# Files through the gateway

Upload a file once, get a reference id, and use that id in later requests instead of re-sending the bytes.

## Upload — `POST /v1/files`

`multipart/form-data` with a `file` part and an optional `purpose` field (default `user_data`). Maximum size **20 MB**.

```bash
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -F "file=@./data.csv" \
  -F "purpose=user_data"
```

Response (OpenAI Files-compatible):

```json
{
  "id":         "an_01J9ZK7VQHX3M9PNQ4ABCDEFGH",
  "object":     "file",
  "bytes":      152340,
  "created_at": 1714579200,
  "expires_at": 1715184000,
  "filename":   "data.csv",
  "purpose":    "user_data",
  "mime_type":  "text/csv"
}
```

Use the returned `id` to reference the file in subsequent chat/messages requests.

**Idempotent:** uploading identical bytes again returns the existing record (HTTP `200` instead of `201`) — no duplicate is stored.

**Errors:** `400` (no file part) · `413` (over 20 MB) · `500` (storage failure).

## Retrieve — `GET /v1/files/{id}`

```bash
curl -L https://api.atptoken.ai/v1/files/an_01J9ZK7VQHX3M9PNQ4ABCDEFGH \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY"
```

Returns a `302` redirect to a short-lived download URL; pass `-L` (or let your HTTP client follow redirects) to fetch the bytes. A file can only be retrieved with a key from the same account that uploaded it (otherwise `403`); unknown ids return `404`.

## Using an upload with the media endpoints

> **Verified 2026-08-04 against production.**

The image and video endpoints under `/omni/media/v1` do **not** understand
`asset://<id>` or `asset://<pid>.<id>`. Both spellings, on both endpoints, are accepted
at create time and then fail during generation with `provider_error /
generation_failed`. **Do not use `asset://`.**

What each endpoint accepts for a reference URL:

| Form | Image (`/images/generations/tasks`) | Video (`/contents/generations/tasks`) |
|---|---|---|
| public `https://…` URL | works | works |
| `data:image/png;base64,…` | works | rejected — `invalid_parameters: The parameter combination is not supported.` |
| `asset://…` | not supported | not supported |

So the portable pattern is: upload, then turn the upload into a public URL by reading
the `Location` header **without** following the redirect.

```bash
FILE_ID=$(curl -s https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" -F "file=@./frame.png" | jq -r .id)

REF_URL=$(curl -sD - -o /dev/null "https://api.atptoken.ai/v1/files/$FILE_ID" \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  | grep -i '^location:' | cut -d' ' -f2 | tr -d '\r')
```

`REF_URL` is an object-store presigned URL: downloadable **without authentication**
(which is what the upstream provider needs) and valid for roughly **15 minutes**.
Resolve it immediately before creating the generation task; never cache or persist it.

Then pass it as:

- image editing → top-level `reference_assets: [{ "url": REF_URL }]`
- video → `content: [{ "type": "image_url", "image_url": { "url": REF_URL }, "role": "first_frame" }]`
