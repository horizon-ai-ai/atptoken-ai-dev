# /v1/files

> Source: https://atptoken.ai/zh-cn/docs/files/

`POST /v1/files`

上传档案到 Gateway，之后在 chat 或 messages 请求中用回传的 **`id`**（格式 `an_<ULID>`）引用它。

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, "filename": "input.pdf", ... }
```

> **字段名是 `id`——2026-08-04 实测**
>
> 本页旧版写成 `gw_file_id`，响应中并没有这个 key。这支端点与 OpenAI Files 兼容，id 就放在 **`id`**。重复上传相同位元组会返回同一个 `id`、HTTP 由 `201` 变 `200`（SHA-256 去重，实测成立）。

### POST /v1/files
multipart/form-data 上传，带一个 `file` part。上限 20 MB。相同位元组会以 SHA-256 去重。
### GET /v1/files/:id
回传 302 导向物件储存上的短效 presigned URL。跟随重导即可下载。

#### 把上传的档案当媒体参考 URL 用

媒体端点**不接受** `asset://` 引用（2026-08-04 实测）。要把上传的图片喂给图片编辑或图生视频模型，请对 `GET /v1/files/{id}` **不要跟随重导**、直接读 `Location` header，拿那个 URL 用：

```
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>
```

这个 presigned URL **免验证**即可下载——正是上游 provider 需要的形式——时效约 **15 分钟**。请在创建任务前才解析、不要缓存。另见[图像生成](https://atptoken.ai/zh-cn/docs/media-image/)与[视频生成](https://atptoken.ai/zh-cn/docs/media-video/)。
