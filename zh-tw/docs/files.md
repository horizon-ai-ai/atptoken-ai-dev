# /v1/files

> Source: https://atptoken.ai/zh-tw/docs/files/

`POST /v1/files`

上傳檔案到 Gateway，之後在 chat 或 messages 請求中用回傳的 `gw_file_id`（格式 `an_<ULID>`）引用它。

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → { "gw_file_id": "an_01H...", ... }
```

### POST /v1/files
multipart/form-data 上傳，帶一個 `file` part。上限 20 MB。相同位元組會以 SHA-256 去重。
### GET /v1/files/:id
回傳 302 導向物件儲存上的短效 presigned URL。跟隨重導即可下載。
