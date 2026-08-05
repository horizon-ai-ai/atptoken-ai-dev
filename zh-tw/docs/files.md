# /v1/files

> Source: https://atptoken.ai/zh-tw/docs/files/

`POST /v1/files`

上傳檔案到 Gateway，之後在 chat 或 messages 請求中用回傳的 **`id`**（格式 `an_<ULID>`）引用它。

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, "filename": "input.pdf", ... }
```

> **欄位名是 `id`——2026-08-04 實測**
>
> 本頁舊版寫成 `gw_file_id`，回應中並沒有這個 key。這支端點與 OpenAI Files 相容，id 就放在 **`id`**。重複上傳相同位元組會回傳同一個 `id`、HTTP 由 `201` 變 `200`（SHA-256 去重，實測成立）。

### POST /v1/files
multipart/form-data 上傳，帶一個 `file` part。上限 20 MB。相同位元組會以 SHA-256 去重。
### GET /v1/files/:id
回傳 302 導向物件儲存上的短效 presigned URL。跟隨重導即可下載。

#### 把上傳的檔案當媒體參考 URL 用

媒體端點**不接受** `asset://` 引用（2026-08-04 實測）。要把上傳的圖片餵給圖片編輯或圖生影片模型，請對 `GET /v1/files/{id}` **不要跟隨重導**、直接讀 `Location` header，拿那個 URL 用：

```
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>
```

這個 presigned URL **免驗證**即可下載——正是上游 provider 需要的形式——時效約 **15 分鐘**。請在建立任務前才解析、不要快取。另見[圖像生成](https://atptoken.ai/zh-tw/docs/media-image/)與[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。
