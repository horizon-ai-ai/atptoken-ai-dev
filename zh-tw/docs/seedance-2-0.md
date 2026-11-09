# Seedance 影片生成

> Source: https://atptoken.ai/zh-tw/docs/seedance-2-0/

`POST /omni/media/v1/contents/generations/tasks`

Seedance 系列支援文生影片、圖生影片、首幀與尾幀控制、參考圖、參考影片與參考音訊，以及可選的生成音訊。所有 Seedance 模型共用[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)的端點與 `content[]` 格式：建立任務、輪詢到終態、下載 `content.video_url`。不確定用哪個，就用 `seedance-2-0`。

## 選模型

| 模型 ID | 適合 | 解析度 | 時長 | 素材怎麼傳 |
| --- | --- | --- | --- | --- |
| `seedance-2-0` | 一般用途 | `480p`、`720p`、`1080p`、`4k` | 4–15 秒 | 公開網址或素材 |
| `seedance-2-0-fast` | 要快 | `480p`、`720p` | 4–15 秒 | **只能公開網址** |
| `seedance-2-0-mini` | 要省 | `480p`、`720p` | 4–15 秒 | 依組合而定，見下方 |
| `seedance-2-5` | 素材較多、片長較長 | `480p`、`720p`、`1080p` | `-1`，或 4–30 秒 | 公開網址或素材 |

> **先確認這把金鑰能用哪些模型**
>
> 用建立任務時的同一把金鑰呼叫 `GET https://api.atptoken.ai/v1/project/models`，這是專案能用的完整清單（`/v1/models` 只列 chat 模型）。清單上沒有不代表不能用；沒有權限時，建立任務會回 `403`，不收費。
>
> 模型 ID 是 `seedance-2-0-mini`。`seedance-2-mini` 不是它的別名，送出會回 `400 InvalidParameter`。

## 支援的生成模式

| 模式 | 要送什麼 |
| --- | --- |
| 文生影片 | 只有文字 part |
| 圖生影片 | 一個 `role: "first_frame"` 的圖片 part |
| 首幀與尾幀 | 分別帶 `first_frame` 與 `last_frame` 的圖片 parts |
| 參考素材 | 一或多個 `reference_image`、`reference_video` 或 `reference_audio` parts |
| 生成音訊 | `generate_audio: true` |

首幀／尾幀模式和參考素材模式是兩種不同的操作：首幀會成為影片的第一個畫面；參考圖只提供外觀、風格或角色，不會被當成第一個畫面。

### 各模型支援的素材組合

| 模型 | 支援的組合（另外都支援純文字） |
| --- | --- |
| `seedance-2-0` | 首幀；首幀＋尾幀；參考圖；參考圖＋參考音訊；參考影片；圖＋影片＋音訊全模態 |
| `seedance-2-0-fast` | 首幀；首幀＋尾幀；參考圖（全部走公開網址） |
| `seedance-2-0-mini` | 首幀（公開網址）；首幀＋尾幀（素材）；最多 3 張參考圖（公開網址） |
| `seedance-2-5` | 只給參考音訊；首幀＋尾幀；參考圖；參考圖＋參考音訊；參考影片 |

### 素材數量上限

| 模型 | 圖 | 影片 | 音訊 |
| --- | --- | --- | --- |
| `seedance-2-0`、`-fast`、`-mini` | 9 | 3 | 3，**不能單獨使用** |
| `seedance-2-5` | 30 | 10 | 10，**可以只有音訊** |

### 媒體 roles

| Role | part 類型 | 用途 |
| --- | --- | --- |
| `first_frame` | `image_url` | 影片的起始畫面。 |
| `last_frame` | `image_url` | 影片的結尾畫面。 |
| `reference_image` | `image_url` | 外觀、風格或角色參考。 |
| `reference_video` | `video_url` | 動作或風格參考。 |
| `reference_audio` | `audio_url` | 聲音參考。只有 `seedance-2-5` 可以單獨送參考音訊。 |

## 參數

| 欄位 | 可用值 | 預設 | 說明 |
| --- | --- | --- | --- |
| `model` | 見上方「選模型」 | | 必填。 |
| `content` | 文字加上可選媒體 parts | | 必填。 |
| `resolution` | 依模型，見上方「選模型」 | `480p` | `480p` 適合低成本測試。`4k` 只有 `seedance-2-0`；`-fast`、`-mini` 最高 `720p`。 |
| `ratio` | `16:9`、`9:16`、`4:3`、`3:4`、`1:1`、`21:9`、`adaptive` | `16:9` | 有首幀時的用法見下方。 |
| `duration` | 整數秒，見上方「選模型」 | `4` | 最便宜的功能測試可用 `4` 秒。`seedance-2-5` 可送 `-1`：交給模型用預設長度，有輸入影片時通常跟著影片長度；依實際輸出秒數計費。 |
| `generate_audio` | `true`、`false` | `false` | 要求模型同時生成音軌。 |
| `return_last_frame` | `true`、`false` | | 啟用後，完成的任務會多帶 `content.last_frame_url`。 |
| `output_format` | `mp4`、`mov` | `mp4` | 僅 `seedance-2-5`。 |

### 有首幀時，畫面比例怎麼決定

- **`seedance-2-0` 系列（含 fast、mini）：輸出比例由 `ratio` 決定，不是由首幀決定。** `ratio` 預設 `16:9`，所以直式首幀不指定比例，會得到橫式影片（480p 時 864×496），畫面被重新構圖。送 `ratio: "adaptive"`，輸出就跟著首幀（直式首幀 → 496×864）。
- **`seedance-2-5`：** 帶首尾幀時**不要送 `ratio`**。沒有首尾幀時可以送，例如 `ratio: "16:9"`。

## 素材怎麼傳

`content[].image_url.url` 可以放公開 `https://` URL、base64，或素材 API 回傳的 `asset://…`（`AssetUri`）。登記素材的做法、常見錯誤與排隊規則，見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)的「素材怎麼傳」。

| 模型 | 公開網址 | 素材（`asset://`） |
| --- | --- | --- |
| `seedance-2-0` | 可以 | 可以 |
| `seedance-2-0-mini` | 首幀、參考圖用這個 | 首幀＋尾幀用這個 |
| `seedance-2-0-fast` | 只能用這個 | 回 `422 this asset's upstream does not serve the requested model` |
| `seedance-2-5` | 可以 | 可以 |

`/v1/files` 的檔案 ID（`an_…`）不是素材網址，放進來會回 `400`。

> **素材名稱最多 64 個字元**
>
> 在 `seedance-2-0`、`seedance-2-0-mini` 上登記素材時，`name` 超過 64 個字元，登記照樣回 200，但 `assets/get` 會回失敗（`InvalidParameter.Name`），建任務得到 `ATP_ASSET_FAILED`。這不是偶發，縮短 `name` 即可，不必改用公開網址。

### 真人照片

真人照片用公開 URL 送出時，可能被拒並回 `400 … may contain real person`。被擋時把同一張圖登記成素材，改傳 `AssetUri`，不需要核身。`seedance-2-0-fast` 不能用素材，所以**真人照片和 `-fast` 不能一起用**，請改用 `seedance-2-0` 或 `seedance-2-5`。產品要求核身時，流程見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)的「真人照片」。

## 範例

以下範例都送到同一個端點：

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-video-job-001" \
  --data-binary @request.json
# → 202 { "id": "cgt_..." }
```

把下列任一段存成 `request.json`。網路中斷後重送同一個請求時，沿用同一個 `Idempotency-Key`；新的作品換新的 key。

### 文生影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "A cinematic tracking shot of Taipei at night, neon reflections, smooth camera motion" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

### 圖生影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "Animate this product shot with a slow premium studio push-in." },
    { "type": "image_url", "image_url": { "url": "https://example.com/product.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "ratio": "adaptive",
  "duration": 4,
  "generate_audio": false,
  "return_last_frame": true
}
```

`"ratio": "adaptive"` 不要拿掉，原因見上方「畫面比例怎麼決定」。

### 首幀與尾幀（Seedance 2.5）

```json
{
  "model": "seedance-2-5",
  "content": [
    { "type": "text", "text": "Create a smooth transition from morning to night with consistent camera framing." },
    { "type": "image_url", "image_url": { "url": "https://example.com/morning.jpg" }, "role": "first_frame" },
    { "type": "image_url", "image_url": { "url": "https://example.com/night.jpg" }, "role": "last_frame" }
  ],
  "resolution": "720p",
  "duration": 6,
  "generate_audio": false,
  "output_format": "mp4"
}
```

這裡刻意不送 `ratio`，原因見上方「畫面比例怎麼決定」。

### 參考圖加參考影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "The character from the reference image dances with the motion of the reference video." },
    { "type": "image_url", "image_url": { "url": "https://example.com/character.jpg" }, "role": "reference_image" },
    { "type": "video_url", "video_url": { "url": "https://example.com/motion.mp4" }, "role": "reference_video" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

## 取得結果

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_xxx \
  -H "Authorization: Bearer $ATP_API_KEY"
```

持續輪詢，直到 `status` 變成 `succeeded`、`failed`、`cancelled` 或 `expired`。成功時從 `content.video_url` 下載影片。這個網址 **24 小時**後失效：狀態仍是 `succeeded`，但 `video_url` 變成 `null`、另有 `expired: true`。請在期限內存到自己的儲存空間。

## 計費

影片按 video tokens 計費，任務進入終態後依實際用量結算：

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` 是輸入影片秒數、`out_dur` 是輸出秒數。模型自己回報用量時，以回報的為準。任務失敗不計費。最便宜的端到端 smoke test 可用 `480p`、`duration: 4`、`generate_audio: false`。

**每秒輸出價格 · 480p**

| 項目 | USD / s |
|---|---:|
| seedance-2-0 | $0.07 |
| seedance-2-0-fast | $0.0538 |

## 下一步

- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 端點參考，含 `url` 接受的形式、素材 API 與錯誤碼。
- [價格](https://atptoken.ai/zh-tw/docs/pricing-model/) — 用量計費與各模型費率怎麼運作。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 用量怎麼從點數扣款。
