# /v1/files

> Source: https://atptoken.ai/zh-tw/docs/files/

`POST /v1/files`

上傳檔案到 Gateway，之後在 chat 或 messages 請求中用回傳的 **`id`**（格式 `an_<ULID>`）引用它。

## 上傳檔案

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, ... }
```

> **檔案 ID 欄位是 `id`**
>
> 回應與 OpenAI Files 相容，檔案 ID 在 **`id`**。每次上傳都會拿到不同的 `id`，內容相同也一樣。

Gateway 會把 `purpose` 和其他表單欄位原樣轉發給供應商，不補預設值。各供應商接受的值不同，拒絕這次上傳的供應商就不會持有這個檔案。要在 chat 引用的檔案請用 `assistants`：有些供應商上傳時接受 `user_data`，之後的 chat 請求卻回 `404 Files [file-…] were not found`。

## 端點

### POST /v1/files
multipart/form-data 上傳，`file` part 必須帶 `Content-Type`。成功回 `200`。Gateway 把檔案轉發給供應商，自己不留存。
### GET /v1/files/:id
回傳檔案內容，由持有檔案的供應商讀回。不會重導，也不是每個供應商都支援讀取。

## 在媒體任務中使用檔案

媒體任務不能使用 `/v1/files` 上傳的檔案。`id` 不是 `asset://` 引用，媒體端點無法用 `id` 取檔，`GET /v1/files/{id}` 回傳的也是檔案內容，不是供應商能抓取的 URL。請改傳下列其中一種：

| 輸入 | 適用端點 | 取得方式 |
| --- | --- | --- |
| 公開 `https://` URL | 圖片與影片端點 | 把檔案放在供應商免驗證就能抓取的位置。 |
| `asset://` URI | Seedance 影片 | 用公開 URL 透過素材 API 登記，見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。 |
| `data:` URI | 圖片與影片端點 | 把檔案編碼成 base64，控制在 2 MB 內，見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。 |

## 錯誤

所有供應商都以用戶端錯誤拒絕時，你會收到該狀態碼和供應商自己的訊息；上傳時訊息以 `no provider accepted this file:` 開頭，讀取時以 `upstream refused to return this file:` 開頭。

- 400 — 上傳時：缺少 file part、file part 沒帶 Content-Type，或這個專案的模型都沒有支援 Files API 的供應商。
- 404 — 讀取時：檔案 ID 已過期、不存在，或屬於其他組織。
- 413 — 上傳時：檔案超過 20 MB。
- 503 — 沒有供應商能完成這個請求。請稍後重試。

## 限制

- **保留時間：** `id` 的效期是 1 小時，到期時間見回應的 `expires_at`。過期後請重新上傳。
- **大小：** 每個檔案上限 20 MB。
- **Gemini 模型：** 無法使用 `id`，請改用 `inline_data` 內嵌檔案。

## 下一步

- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 把公開 URL 或素材 URI 當首幀或參考圖傳入。
- [圖像生成](https://atptoken.ai/zh-tw/docs/media-image/) — 把公開 URL 當編輯類模型的輸入圖。
- [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) — 送出引用已上傳檔案的請求。
