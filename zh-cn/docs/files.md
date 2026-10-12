# /v1/files

> Source: https://atptoken.ai/zh-cn/docs/files/

`POST /v1/files`

上传文件到 Gateway，之后在 chat 或 messages 请求中用回传的 **`id`**（格式 `an_<ULID>`）引用它。

## 上传文件

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, "filename": "input.pdf", ... }
```

> **文件 ID 栏位是 `id`**
>
> 回应与 OpenAI Files 相容，文件 ID 在 **`id`**。重复上传相同内容会回传同一个 `id`，HTTP 由 `201` 变 `200`（以 SHA-256 去重）。

## 端点

### POST /v1/files
multipart/form-data 上传，带一个 `file` part。上限 20 MB。相同字节会以 SHA-256 去重。
### GET /v1/files/:id
回传 302 导向物件储存上的短效 presigned URL。跟随重导即可下载。

## 把上传的文件当媒体参考 URL 用

`/v1/files` 的 id 不是 `asset://` 引用，媒体端点无法用 id 取档。Seedance 影片只接受另一套素材 API 产生的 `asset://` URI，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。要把上传的图片喂给图片编辑或图生影片模型，请对 `GET /v1/files/{id}` **不要跟随重导**、直接读 `Location` header，拿那个 URL 用：

**上传 → 媒体参考 URL**

1. 上传文件 — `POST /v1/files` — 回 `201`，带 `id`（`an_…`）
2. 不跟随重导地解析 — `GET /v1/files/{id}` — 读 `302` 的 `Location` header
3. 立刻建立任务 — presigned URL — 时效约 15 分钟

```
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>
```

这个 presigned URL **免验证**即可下载——正是上游供应商需要的形式——时效约 **15 分钟**。请在建立任务前才解析、不要快取。另见[图像生成](https://atptoken.ai/zh-cn/docs/media-image/)与[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。

## 下一步

- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 把 URL 或素材 URI 当首帧或参考图传入。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 把 URL 当编辑类模型的输入图。
- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 送出引用已上传文件的请求。
