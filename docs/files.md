# /v1/files

> Source: https://atptoken.ai/docs/files/

`POST /v1/files`

Upload a file to the Gateway and reference it in subsequent chat or messages requests by the returned **`id`** (format `an_<ULID>`).

## Upload a file

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, "filename": "input.pdf", ... }
```

> **The file ID field is `id`**
>
> The response follows OpenAI Files: the file ID is in **`id`**. Uploading identical content returns the same ID, with HTTP `200` instead of `201` (SHA-256 deduplication).

## Endpoints

### POST /v1/files
multipart/form-data upload with a `file` part. Max 20 MB. Identical bytes are deduped by SHA-256.
### GET /v1/files/:id
Returns 302 to a short-lived presigned URL on the object store. Follow the redirect to download.

## Use an upload as a media reference URL

A `/v1/files` id is not an `asset://` reference, and the media endpoints cannot fetch it by id. Seedance video accepts `asset://` URIs only from the separate asset API; see [video generation](https://atptoken.ai/docs/media-video/). To feed an uploaded image to an image-edit or image-to-video model, read the `Location` header of `GET /v1/files/{id}` **without following the redirect** and pass that URL:

**Upload → media reference URL**

1. Upload the file — `POST /v1/files` — `201` with `id` (`an_…`)
2. Resolve without following the redirect — `GET /v1/files/{id}` — read the `302` `Location` header
3. Create the task right away — presigned URL — lives about 15 minutes

```
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>
```

That presigned URL is downloadable without authentication — which is what the upstream provider needs — and lives about **15 minutes**. Resolve it immediately before creating the task; do not cache it. See [image generation](https://atptoken.ai/docs/media-image/) and [video generation](https://atptoken.ai/docs/media-video/).

## Next steps

- [Video generation](https://atptoken.ai/docs/media-video/) — Pass the URL, or an asset URI, as a frame or reference image.
- [Image generation](https://atptoken.ai/docs/media-image/) — Use the URL as an input image for edit-style models.
- [/v1/messages](https://atptoken.ai/docs/messages/) — Send requests that reference your uploaded file.
