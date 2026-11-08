# /v1/files

> Source: https://atptoken.ai/docs/files/

`POST /v1/files`

Upload a file to the Gateway and reference it in subsequent chat or messages requests by the returned **`id`** (format `an_<ULID>`).

## Upload a file

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, ... }
```

> **The file ID field is `id`**
>
> The response follows OpenAI Files: the file ID is in **`id`**. Every upload returns a different `id`, even for identical content.

The Gateway forwards `purpose` and any other form fields to the providers as sent, and adds no default. Accepted values differ by provider, and a provider that refuses the upload does not hold the file. Use `assistants` for a file you will reference in chat: some providers accept `user_data` at upload, then answer the chat request with `404 Files [file-…] were not found`.

## Endpoints

### POST /v1/files
multipart/form-data upload with a `file` part that carries a `Content-Type`. Returns `200`. The Gateway forwards the file to the providers and keeps no copy.
### GET /v1/files/:id
Returns the file's bytes, read back from a provider that holds it. There is no redirect, and not every provider supports this read.

## Use files in media tasks

Media tasks cannot use a `/v1/files` upload. The `id` is not an `asset://` reference, the media endpoints cannot fetch a file by `id`, and `GET /v1/files/{id}` returns the file's bytes rather than a URL a provider can fetch. Pass one of these instead:

| Input | Accepted by | How to get it |
| --- | --- | --- |
| public `https://` URL | image and video endpoints | Host the file where the provider can fetch it without authentication. |
| `asset://` URI | Seedance video | Register a public URL through the asset API; see [video generation](https://atptoken.ai/docs/media-video/). |
| `data:` URI | image and video endpoints | Encode the file as base64 and keep it under 2 MB; see [video generation](https://atptoken.ai/docs/media-video/). |

## Errors

When every provider refuses a request with a client error, you get that status with their own words, after `no provider accepted this file:` on upload or `upstream refused to return this file:` on read.

- 400 — on upload: the file part is missing, has no Content-Type, or no model in this project has a provider with a Files API.
- 404 — on read: the ID has expired, does not exist, or belongs to another organization.
- 413 — on upload: the file exceeds 20 MB.
- 503 — no provider could complete the request. Retry later.

## Limits

- **Lifetime:** an `id` lasts one hour; the response gives the time in `expires_at`. After that, upload the file again.
- **Size:** 20 MB per file.
- **Gemini models:** these cannot use an `id`. Send the file inline with `inline_data`.

## Next steps

- [Video generation](https://atptoken.ai/docs/media-video/) — Pass a public URL, or an asset URI, as a frame or reference image.
- [Image generation](https://atptoken.ai/docs/media-image/) — Use a public URL as an input image for edit-style models.
- [/v1/messages](https://atptoken.ai/docs/messages/) — Send requests that reference your uploaded file.
