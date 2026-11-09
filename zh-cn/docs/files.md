# /v1/files

> Source: https://atptoken.ai/zh-cn/docs/files/

`POST /v1/files`

上传文件到 Gateway，之后在 chat 或 messages 请求中用回传的 **`id`**（格式 `an_<ULID>`）引用它。这个 id 只给 chat 用，**媒体任务（图像、影片、语音）不能用**。

## 上传文件

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, "expires_at": ..., ... }
```

> **文件 ID 栏位是 `id`**
>
> 回应与 OpenAI Files 相容，文件 ID 在 **`id`**。每次上传都会拿到不同的 `id`，内容相同也一样。

上传**不需要指定 `model`**。这个项目允许清单里支持文件的模型都会拿到它，之后给哪个模型用都可以。

Gateway 会把 `purpose` 和其他表单栏位原样转发给供应商，不补默认值。各供应商接受的值不同，常见的有 `assistants`、`user_data`、`file-extract`、`batch`；拒绝这次上传的供应商就不会持有这个文件。要在 chat 引用的文件请用 `assistants`：有些供应商上传时接受 `user_data`，之后的 chat 请求却回 `404 Files [file-…] were not found`。

## 在 chat 里引用

OpenAI 入口（`/v1/chat/completions`）用 `input_file` block：

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

Anthropic 入口（`/v1/messages`）用 `document` block，`source.type` 设为 `"file"`；图片的 `image` block 也一样可以用：

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

同一个 `id` 在 OpenAI 与 Anthropic 入口都能用，不用重新上传。若某个模型读不到这个文件，请求会改用其他可用容量，全部用尽才回错。

## 端点

### POST /v1/files
multipart/form-data 上传，`file` part 必须带 `Content-Type`。成功回 `200`。Gateway 把文件转发给供应商，自己不留存。
### GET /v1/files/:id
回传文件内容，由持有文件的供应商读回，`Content-Type` 沿用供应商回的值。不会重导，也不是每个供应商都支持读取。回应带 `Cache-Control: no-store`。

## Gemini SDK 的上传

用 `google-genai` SDK 上传时，它会走两段式的 `/upload/v1beta/files`：

1. `POST https://api.atptoken.ai/upload/v1beta/files`：只送 header 宣告要传什么。**必须有 `x-goog-upload-header-content-type`**，缺了就是 `400`；`x-goog-upload-header-content-length` 超过 20 MB 回 `413`。第二步的网址在回应的 `x-goog-upload-url` header 里。
2. 用 `POST` 或 `PUT` 把字节送到那个网址。完成后 token 就作废，重送同一个回 `404`。
3. 回应的 `file.uri` 一样是 `an_<ulid>`，规则和 `POST /v1/files` 相同。

从 `/upload/v1/files` 开始也可以，第二步的网址会保留你用的版本。

> **Gemini 模型用不到上传的文件**
>
> 走 Gemini 入口（`:generateContent`）的模型**不能使用 `an_<ulid>`**，用 Gemini SDK 上传的也一样，引用它会回错。要给 Gemini 模型用，请在请求里直接内嵌 `inline_data`。

## 在媒体任务中使用文件

媒体任务不能使用 `/v1/files` 上传的文件。`id` 不是 `asset://` 引用，媒体端点无法用 `id` 取档，`GET /v1/files/{id}` 回传的也是文件内容，不是供应商能抓取的 URL。把 `an_<ulid>` 或 `https://api.atptoken.ai/v1/files/{id}` 放进 `image_url.url`，都会回 `400 The parameter content[1].image_url specified in the request is not valid`。请改传下列其中一种：

| 输入 | 适用端点 | 取得方式 |
| --- | --- | --- |
| 公开 `https://` URL | 图片与影片端点 | 把文件放在供应商免验证就能抓取的位置。 |
| `asset://` URI | 部分影片模型（例如 Seedance；`seedance-2-0-fast` 不收） | 用公开 URL 通过素材 API 登记，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。 |
| `data:` URI | 图片端点 | 把图片编码成 base64，见[图像生成](https://atptoken.ai/zh-cn/docs/media-image/)。 |

## 错误

上传被拒时回 `502`，消息以 `no provider accepted this file:` 开头，后面带供应商自己的状态和消息（最多三种不同原因），例如 `files_api not supported in your workspace.`、`'purpose' must be one of ['file-extract', 'batch']`。读取被拒时，你拿到的是供应商自己的状态码和消息，以 `upstream refused to return this file:` 开头，所以分得出是「文件不在」还是「不支持读取」。

- 400 — 上传时：缺少 file part、file part 没带 Content-Type，或这个项目的模型都不支持文件上传（消息会说明）。读取时：这个文件上传时用的 `purpose` 不能被读回。
- 404 — 读取时：文件 ID 已过期、不存在，或属于其他组织（三者回同一个答案）。
- 413 — 上传时：文件超过 20 MB。
- 500 — 上传时：读取上传字节失败等内部错误。
- 502 — 上传时：供应商拒绝这次上传，原因见消息。读取时：无法连线。
- 503 — 没有供应商能完成这个请求。请稍后重试。

## 限制

- **保留时间：** `id` 的效期是 1 小时，到期时间见回应的 `expires_at`。Gateway 不留存字节，过期后没有备份，请重新上传。
- **大小：** 每个文件上限 20 MB，图片、文件、音讯都一样。
- **音讯格式：** `audio/wav`、`audio/mpeg`、`audio/mp4`、`audio/flac`、`audio/ogg`、`audio/webm`、`audio/opus`、`audio/aac`、`audio/x-m4a`、`audio/pcm`。
- **Gemini 模型：** 无法使用 `id`，请改用 `inline_data` 内嵌文件。

## 下一步

- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 把公开 URL 或素材 URI 当首帧或参考图传入。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 把公开 URL 当编辑类模型的输入图。
- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 送出引用已上传文件的请求。
