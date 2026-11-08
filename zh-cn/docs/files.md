# /v1/files

> Source: https://atptoken.ai/zh-cn/docs/files/

`POST /v1/files`

上传文件到 Gateway，之后在 chat 或 messages 请求中用回传的 **`id`**（格式 `an_<ULID>`）引用它。

## 上传文件

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, ... }
```

> **文件 ID 栏位是 `id`**
>
> 回应与 OpenAI Files 相容，文件 ID 在 **`id`**。每次上传都会拿到不同的 `id`，内容相同也一样。

Gateway 会把 `purpose` 和其他表单栏位原样转发给供应商，不补默认值。各供应商接受的值不同，拒绝这次上传的供应商就不会持有这个文件。要在 chat 引用的文件请用 `assistants`：有些供应商上传时接受 `user_data`，之后的 chat 请求却回 `404 Files [file-…] were not found`。

## 端点

### POST /v1/files
multipart/form-data 上传，`file` part 必须带 `Content-Type`。成功回 `200`。Gateway 把文件转发给供应商，自己不留存。
### GET /v1/files/:id
回传文件内容，由持有文件的供应商读回。不会重导，也不是每个供应商都支持读取。

## 在媒体任务中使用文件

媒体任务不能使用 `/v1/files` 上传的文件。`id` 不是 `asset://` 引用，媒体端点无法用 `id` 取档，`GET /v1/files/{id}` 回传的也是文件内容，不是供应商能抓取的 URL。请改传下列其中一种：

| 输入 | 适用端点 | 取得方式 |
| --- | --- | --- |
| 公开 `https://` URL | 图片与影片端点 | 把文件放在供应商免验证就能抓取的位置。 |
| `asset://` URI | Seedance 影片 | 用公开 URL 通过素材 API 登记，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。 |
| `data:` URI | 图片与影片端点 | 把文件编码成 base64，控制在 2 MB 内，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。 |

## 错误

所有供应商都以用户端错误拒绝时，你会收到该状态码和供应商自己的消息；上传时消息以 `no provider accepted this file:` 开头，读取时以 `upstream refused to return this file:` 开头。

- 400 — 上传时：缺少 file part、file part 没带 Content-Type，或这个项目的模型都没有支持 Files API 的供应商。
- 404 — 读取时：文件 ID 已过期、不存在，或属于其他组织。
- 413 — 上传时：文件超过 20 MB。
- 503 — 没有供应商能完成这个请求。请稍后重试。

## 限制

- **保留时间：** `id` 的效期是 1 小时，到期时间见回应的 `expires_at`。过期后请重新上传。
- **大小：** 每个文件上限 20 MB。
- **Gemini 模型：** 无法使用 `id`，请改用 `inline_data` 内嵌文件。

## 下一步

- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 把公开 URL 或素材 URI 当首帧或参考图传入。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 把公开 URL 当编辑类模型的输入图。
- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 送出引用已上传文件的请求。
