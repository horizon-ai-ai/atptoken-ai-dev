# /v1/files

> Source: https://atptoken.ai/docs/files/

`POST /v1/files`

Upload a file to the Gateway and reference it in subsequent chat or messages requests by the returned **`id`** (format `an_<ULID>`). The id is for chat only — **media tasks (image, video, audio) cannot use it**.

## Upload a file

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, "expires_at": ..., ... }
```

> **The file ID field is `id`**
>
> The response follows OpenAI Files: the file ID is in **`id`**. Every upload returns a different `id`, even for identical content.

An upload **takes no `model`**. Every file-capable model on this project's allow-list receives it, so you can use it with any of them later.

The Gateway forwards `purpose` and any other form fields to the providers as sent, and adds no default. Accepted values differ by provider — common ones are `assistants`, `user_data`, `file-extract` and `batch` — and a provider that refuses the upload does not hold the file. Use `assistants` for a file you will reference in chat: some providers accept `user_data` at upload, then answer the chat request with `404 Files [file-…] were not found`.

## Reference it in chat

On the OpenAI entry point (`/v1/chat/completions`), use an `input_file` block:

```
{
  "model": "gpt-4o",
  "messages": [{ "role": "user", "content": [
    { "type": "input_file", "input_file": { "file_id": "an_01JXXXXXXXXXXXXXXXXXXXXX" } },
    { "type": "text", "text": "Summarize the key points of this document." }
  ]}],
  "max_tokens": 1024
}
```

On the Anthropic entry point (`/v1/messages`), use a `document` block with `source.type` set to `"file"`; an `image` block works the same way:

```
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "messages": [{ "role": "user", "content": [
    { "type": "document", "source": { "type": "file", "file_id": "an_01JXXXXXXXXXXXXXXXXXXXXX" } },
    { "type": "text", "text": "Summarize the key points of this document." }
  ]}]
}
```

The same `id` works on both the OpenAI and Anthropic entry points without re-uploading. If a model can't read the file, the request moves to other available capacity and errors only when all of it is exhausted.

## Endpoints

### POST /v1/files
multipart/form-data upload with a `file` part that carries a `Content-Type`. Returns `200`. The Gateway forwards the file to the providers and keeps no copy.
### GET /v1/files/:id
Returns the file's bytes, read back from a provider that holds it, with that provider's `Content-Type`. There is no redirect, and not every provider supports this read. Responses carry `Cache-Control: no-store`.

## Uploading with the Gemini SDK

The `google-genai` SDK uploads in two steps through `/upload/v1beta/files`:

1. `POST https://api.atptoken.ai/upload/v1beta/files` sends only headers that declare the upload. **`x-goog-upload-header-content-type` is required** — without it you get `400`; an `x-goog-upload-header-content-length` over 20 MB gets `413`. The URL for step two is in the `x-goog-upload-url` response header.
2. `POST` or `PUT` the bytes to that URL. The token is spent once the upload completes; replaying it returns `404`.
3. The response's `file.uri` is an `an_<ulid>` too, under the same rules as `POST /v1/files`.

Starting from `/upload/v1/files` also works; the step-two URL keeps the version you used.

> **Gemini models can't use uploaded files**
>
> Models on the Gemini entry point (`:generateContent`) **cannot use an `an_<ulid>`** — including one uploaded through the Gemini SDK — and referencing it returns an error. To give a file to a Gemini model, send it inline with `inline_data`.

## Use files in media tasks

Media tasks cannot use a `/v1/files` upload. The `id` is not an `asset://` reference, the media endpoints cannot fetch a file by `id`, and `GET /v1/files/{id}` returns the file's bytes rather than a URL a provider can fetch. Putting an `an_<ulid>` or `https://api.atptoken.ai/v1/files/{id}` in `image_url.url` returns `400 The parameter content[1].image_url specified in the request is not valid`. Pass one of these instead:

| Input | Accepted by | How to get it |
| --- | --- | --- |
| public `https://` URL | image and video endpoints | Host the file where the provider can fetch it without authentication. |
| `asset://` URI | some video models (e.g. Seedance; not `seedance-2-0-fast`) | Register a public URL through the asset API; see [video generation](https://atptoken.ai/docs/media-video/). |
| `data:` URI | image endpoint | Encode the image as base64; see [image generation](https://atptoken.ai/docs/media-image/). |

## Errors

A refused upload returns `502` with a message that starts `no provider accepted this file:` followed by the providers' own status and words (up to three distinct reasons), e.g. `files_api not supported in your workspace.` or `'purpose' must be one of ['file-extract', 'batch']`. A refused read gives you the provider's own status code and words after `upstream refused to return this file:`, so you can tell "file not there" from "read not supported".

- 400 — on upload: the file part is missing, has no Content-Type, or no model in this project supports file uploads (the message says so). On read: the file was uploaded with a `purpose` that can't be read back.
- 404 — on read: the ID has expired, does not exist, or belongs to another organization (all three give the same answer).
- 413 — on upload: the file exceeds 20 MB.
- 500 — on upload: an internal error such as failing to read the uploaded bytes.
- 502 — on upload: the providers refused the upload; see the message. On read: could not connect.
- 503 — no provider could complete the request. Retry later.

## Limits

- **Lifetime:** an `id` lasts one hour; the response gives the time in `expires_at`. The Gateway keeps no bytes, so there is nothing to recover after that — upload the file again.
- **Size:** 20 MB per file, for images, documents and audio alike.
- **Audio formats:** `audio/wav`, `audio/mpeg`, `audio/mp4`, `audio/flac`, `audio/ogg`, `audio/webm`, `audio/opus`, `audio/aac`, `audio/x-m4a`, `audio/pcm`.
- **Gemini models:** these cannot use an `id`. Send the file inline with `inline_data`.

## Next steps

- [Video generation](https://atptoken.ai/docs/media-video/) — Pass a public URL, or an asset URI, as a frame or reference image.
- [Image generation](https://atptoken.ai/docs/media-image/) — Use a public URL as an input image for edit-style models.
- [/v1/messages](https://atptoken.ai/docs/messages/) — Send requests that reference your uploaded file.
