# /v1/files

> Source: https://atptoken.ai/zh-cn/docs/files/

`POST /v1/files`

上传档案到 Gateway，之后在 chat 或 messages 请求中用回传的 `gw_file_id`（格式 `an_<ULID>`）引用它。

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → { "gw_file_id": "an_01H...", ... }
```

### POST /v1/files
multipart/form-data 上传，带一个 `file` part。上限 20 MB。相同位元组会以 SHA-256 去重。
### GET /v1/files/:id
回传 302 导向物件储存上的短效 presigned URL。跟随重导即可下载。
