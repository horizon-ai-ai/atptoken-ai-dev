# /v1/files

> Source: https://atptoken.ai/zh-tw/docs/files/

`POST /v1/files`

上傳檔案到 Gateway，之後在 chat 或 messages 請求中用回傳的 **`id`**（格式 `an_<ULID>`）引用它。這個 id 只給 chat 用，**媒體任務（圖像、影片、語音）不能用**。

## 上傳檔案

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf" \
  -F "purpose=assistants"
# → 200 { "id": "an_01H...", "object": "file", "bytes": 152340, "expires_at": ..., ... }
```

> **檔案 ID 欄位是 `id`**
>
> 回應與 OpenAI Files 相容，檔案 ID 在 **`id`**。每次上傳都會拿到不同的 `id`，內容相同也一樣。

上傳**不需要指定 `model`**。這個專案允許清單裡支援檔案的模型都會拿到它，之後給哪個模型用都可以。

Gateway 會把 `purpose` 和其他表單欄位原樣轉發給供應商，不補預設值。各供應商接受的值不同，常見的有 `assistants`、`user_data`、`file-extract`、`batch`；拒絕這次上傳的供應商就不會持有這個檔案。要在 chat 引用的檔案請用 `assistants`：有些供應商上傳時接受 `user_data`，之後的 chat 請求卻回 `404 Files [file-…] were not found`。

## 在 chat 裡引用

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

Anthropic 入口（`/v1/messages`）用 `document` block，`source.type` 設為 `"file"`；圖片的 `image` block 也一樣可以用：

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

同一個 `id` 在 OpenAI 與 Anthropic 入口都能用，不用重新上傳。若某個模型讀不到這個檔案，請求會改用其他可用容量，全部用盡才回錯。

## 端點

### POST /v1/files
multipart/form-data 上傳，`file` part 必須帶 `Content-Type`。成功回 `200`。Gateway 把檔案轉發給供應商，自己不留存。
### GET /v1/files/:id
回傳檔案內容，由持有檔案的供應商讀回，`Content-Type` 沿用供應商回的值。不會重導，也不是每個供應商都支援讀取。回應帶 `Cache-Control: no-store`。

## Gemini SDK 的上傳

用 `google-genai` SDK 上傳時，它會走兩段式的 `/upload/v1beta/files`：

1. `POST https://api.atptoken.ai/upload/v1beta/files`：只送 header 宣告要傳什麼。**必須有 `x-goog-upload-header-content-type`**，缺了就是 `400`；`x-goog-upload-header-content-length` 超過 20 MB 回 `413`。第二步的網址在回應的 `x-goog-upload-url` header 裡。
2. 用 `POST` 或 `PUT` 把位元組送到那個網址。完成後 token 就作廢，重送同一個回 `404`。
3. 回應的 `file.uri` 一樣是 `an_<ulid>`，規則和 `POST /v1/files` 相同。

從 `/upload/v1/files` 開始也可以，第二步的網址會保留你用的版本。

> **Gemini 模型用不到上傳的檔案**
>
> 走 Gemini 入口（`:generateContent`）的模型**不能使用 `an_<ulid>`**，用 Gemini SDK 上傳的也一樣，引用它會回錯。要給 Gemini 模型用，請在請求裡直接內嵌 `inline_data`。

## 在媒體任務中使用檔案

媒體任務不能使用 `/v1/files` 上傳的檔案。`id` 不是 `asset://` 引用，媒體端點無法用 `id` 取檔，`GET /v1/files/{id}` 回傳的也是檔案內容，不是供應商能抓取的 URL。把 `an_<ulid>` 或 `https://api.atptoken.ai/v1/files/{id}` 放進 `image_url.url`，都會回 `400 The parameter content[1].image_url specified in the request is not valid`。請改傳下列其中一種：

| 輸入 | 適用端點 | 取得方式 |
| --- | --- | --- |
| 公開 `https://` URL | 圖片與影片端點 | 把檔案放在供應商免驗證就能抓取的位置。 |
| `asset://` URI | 部分影片模型（例如 Seedance；`seedance-2-0-fast` 不收） | 用公開 URL 透過素材 API 登記，見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。 |
| `data:` URI | 圖片端點 | 把圖片編碼成 base64，見[圖像生成](https://atptoken.ai/zh-tw/docs/media-image/)。 |

## 錯誤

上傳被拒時回 `502`，訊息以 `no provider accepted this file:` 開頭，後面帶供應商自己的狀態和訊息（最多三種不同原因），例如 `files_api not supported in your workspace.`、`'purpose' must be one of ['file-extract', 'batch']`。讀取被拒時，你拿到的是供應商自己的狀態碼和訊息，以 `upstream refused to return this file:` 開頭，所以分得出是「檔案不在」還是「不支援讀取」。

- 400 — 上傳時：缺少 file part、file part 沒帶 Content-Type，或這個專案的模型都不支援檔案上傳（訊息會說明）。讀取時：這個檔案上傳時用的 `purpose` 不能被讀回。
- 404 — 讀取時：檔案 ID 已過期、不存在，或屬於其他組織（三者回同一個答案）。
- 413 — 上傳時：檔案超過 20 MB。
- 500 — 上傳時：讀取上傳位元組失敗等內部錯誤。
- 502 — 上傳時：供應商拒絕這次上傳，原因見訊息。讀取時：無法連線。
- 503 — 沒有供應商能完成這個請求。請稍後重試。

## 限制

- **保留時間：** `id` 的效期是 1 小時，到期時間見回應的 `expires_at`。Gateway 不留存位元組，過期後沒有備份，請重新上傳。
- **大小：** 每個檔案上限 20 MB，圖片、文件、音訊都一樣。
- **音訊格式：** `audio/wav`、`audio/mpeg`、`audio/mp4`、`audio/flac`、`audio/ogg`、`audio/webm`、`audio/opus`、`audio/aac`、`audio/x-m4a`、`audio/pcm`。
- **Gemini 模型：** 無法使用 `id`，請改用 `inline_data` 內嵌檔案。

## 下一步

- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 把公開 URL 或素材 URI 當首幀或參考圖傳入。
- [圖像生成](https://atptoken.ai/zh-tw/docs/media-image/) — 把公開 URL 當編輯類模型的輸入圖。
- [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) — 送出引用已上傳檔案的請求。
