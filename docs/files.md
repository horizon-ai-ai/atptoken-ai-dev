# /v1/files

> Source: https://atptoken.ai/docs/files/

`POST /v1/files`

Upload a file to the Gateway and reference it in subsequent chat or messages requests by the returned **`id`** (format `an_<ULID>`).

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, "filename": "input.pdf", ... }
```

> **The key is `id` — verified 2026-08-04**
>
> Earlier revisions of this page called the field `gw_file_id`. The response has no such key; it is OpenAI Files-compatible and the id lives in **`id`**. Re-uploading identical bytes returns the same `id` with HTTP `200` instead of `201` (SHA-256 dedupe, confirmed in testing).

### POST /v1/files
multipart/form-data upload with a `file` part. Max 20 MB. Identical bytes are deduped by SHA-256.
### GET /v1/files/:id
Returns 302 to a short-lived presigned URL on the object store. Follow the redirect to download.

#### Using an upload as a media reference URL

The media endpoints do **not** accept `asset://` references (verified 2026-08-04). To feed an uploaded image to an image-edit or image-to-video model, read the `Location` header of `GET /v1/files/{id}` **without following the redirect** and pass that URL:

```
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>
```

That presigned URL is downloadable without authentication — which is what the upstream provider needs — and lives about **15 minutes**. Resolve it immediately before creating the task; do not cache it. See [image generation](https://atptoken.ai/docs/media-image/) and [video generation](https://atptoken.ai/docs/media-video/).
