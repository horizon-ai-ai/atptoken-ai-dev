# 影片生成

> Source: https://atptoken.ai/zh-tw/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

影片生成是**非同步**的：先建立任務（`202` + task id），輪詢到終態後再讀簽章 URL。base URL 與 `atp-` 金鑰同圖像。Gateway 把 unified `model` 路由到影片供應商，同名可容錯切換。

**每一個影片任務**

1. 建立任務 — `POST …/contents/generations/tasks` — 回 `202` + task id；餘額 ≤ 0 時回 `402`
2. 輪詢到終態 — `GET …/contents/generations/tasks/{id}`
3. 下載 `content.video_url` — 簽章 URL — TTL 30 分鐘
   - succeeded
   - failed
   - 30 分鐘後 `expired: true` · 需重建重生

- **成功的任務帶 `content.video_url`——帶簽章的邊緣 URL，**TTL 30 分鐘**。逾期後任務仍回 `succeeded` 但 `video_url` 為 `null` 且 `expired: true`（需重建重生）。**
- 當專案（project）餘額 ≤ 0，請求會以 `402 insufficient_quota` 拒絕。

## 可用的影片模型

名稱以 `GET /v1/models` 確認。

| 系列 | 模型 | 說明 |
| --- | --- | --- |
| Seedance | `seedance-2-0` | 標準 |
| Seedance | `seedance-2-0-mini` | 輕量／較省 |
| Seedance | `seedance-2-0-fast` | 加速 |
| Kling（preview） | `kling-v3-standard`、`kling-v3-pro`、`kling-o3-standard`、`kling-o3-pro` | 按秒×解析度計費；Kling 音訊生成暫未開放 |
| Kling（preview） | `-i2v`、`-reference`、`-reference-7`、`-v2v`、`-video-edit` | 上列 Kling 模型的變體 |
| 阿里（preview） | `wan-2-7-t2v`、`wan-2-7-i2v` | 不論請求解析度皆輸出並依 1080P 計費 |
| 阿里（preview） | `happyhorse-1.1-t2v`、`happyhorse-1.1-i2v` | 3–15 秒；浮水印預設開啟（可傳 `watermark: false` 關閉） |
| 阿里（preview） | `happyhorse-1.1-r2v` | 最多 9 張參考圖；3–15 秒；浮水印預設開啟 |
| 阿里（preview） | `happyhorse-1.0-video-edit` | 來源影片 3–60 秒＋最多 5 張參考圖；浮水印預設開啟 |

> **先確認模型與專案權限**
>
> 請使用建立任務時的同一把金鑰呼叫 `GET https://api.atptoken.ai/v1/models`。模型未出現在回應中，就不能由該專案使用；安裝 Skill 或知道模型名稱不會繞過 allowed models。

## 建立任務

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "seedance-2-0",
    "content": [
      { "type": "text", "text": "a red fox running through snow, cinematic" },
      { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
    ],
    "resolution": "720p",
    "ratio": "16:9",
    "duration": 5
  }'
# → 202 { "id": "task_..." }
```

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | 統一影片模型 ID（`video` 供應商池） |
| content | array · 必填 | 多模態輸入區塊（見下方） |
| resolution | string | `480p` / `720p` / `1080p` / `4k` |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` （別名 `aspect_ratio`） |
| duration | integer | 秒數（與 `frames` 擇一） |
| frames | integer | 影格數（`duration` 的替代） |
| generate_audio | boolean | 加上配樂（別名 `add_audio`） |
| seed | integer | |
| watermark | boolean | |

**`content[]` 區塊**——每個區塊是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。

- 只有文字 → 文生影片；含圖片 → 圖生影片。
- `image_url`/`video_url` 帶 `{ "url": "…" }`。
- `role` 為 `first_frame` / `last_frame` / `reference_image` / `reference_video`。

### `url` 接受哪些形式

> **影片端點接受公開 https URL 或素材 URI**
>
> **影片端點接受公開 `https://` URL；Seedance 另外接受素材 API 產生的 `asset://` URI。**
>
> | 形式 | 影片端點 | 圖片端點 |
> | --- | --- | --- |
> | 公開 `https://…` URL | 可用 | 可用 |
> | `data:image/…;base64,…` | **被擋**——`invalid_parameters: The parameter combination is not supported.` | 可用 |
> | 素材 API 回傳的 `asset://…`（`AssetUri`） | 可用（Seedance） | **不支援** |
>
> 圖片端點收到 `asset://` 引用時，會在生成階段回 `provider_error / generation_failed`。

### 引用上傳的檔案

要引用自己上傳的檔案，先把它換成公開 URL：

```
# 1. upload — the response key is `id` (an_<ULID>), not gw_file_id
curl -s https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." -F "file=@./first-frame.png"
# → 201 { "id": "an_01H...", "object": "file", "bytes": 152340, ... }

# 2. resolve to a no-auth URL — read the 302 Location, do NOT follow it
curl -sD - -o /dev/null https://api.atptoken.ai/v1/files/an_01H... \
  -H "Authorization: Bearer atp-..." | grep -i '^location:'
# → location: https://<object-store>/gateway-files/...?<presigned>  (~15-minute TTL)
```

把那個 `Location` 值當 `url` 用。它免驗證即可下載——正是上游供應商需要的——但約 15 分鐘就過期，所以請在建立任務前才解析，不要快取。

### 引用登記的素材

Seedance 也接受透過素材 API 登記的圖片。登記圖片、等到狀態為 `Completed`，再把回傳的 `AssetUri`（`asset://…`，請原樣使用）當圖片區塊的 `url`：

**把圖片登記成素材**

1. 建立素材群組 — `POST /omni/media/v1/asset-groups`
2. 登記圖片 — `POST /omni/media/v1/assets`
3. 輪詢到 `Completed` — `POST /omni/media/v1/assets/get` — 回傳 `AssetUri`
4. 建立影片任務 — `POST …/contents/generations/tasks` — URI 放在 `content[].image_url.url`

```
{ "type": "image_url", "image_url": { "url": "asset://…" }, "role": "reference_image" }
```

URI 只放在 `image_url.url`，區塊沒有頂層 `url`。`/v1/files` 的 id 不是素材 URI。

## 輪詢至終態

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/task_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| 方法 | 路徑 | 動作 |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | create |
| GET | /omni/media/v1/contents/generations/tasks/{id} | poll |
| GET | /omni/media/v1/contents/generations/tasks | list |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | cancel |

## 阿里影片模型

`wan-2-7-t2v`／`wan-2-7-i2v` 與 HappyHorse 的文生／圖生／參考圖模型與其他影片模型共用同一組端點與 `content[]` 形狀，以下只列各模型特有之處。**`happyhorse-1.0-video-edit` 是例外：它服務於另一組 DashScope 相容端點**（見下）。

| 模型 | 輸入 | 時長 | 計費解析度 | 端點 |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | 文字 | 2–15 秒 | **一律 1080P**（見注意事項） | 統一 |
| `wan-2-7-i2v` | 文字 + 1 張首幀圖 | 2–15 秒 | **一律 1080P**（見注意事項） | 統一 |
| `happyhorse-1.1-t2v` | 文字 | 3–15 秒 | 依請求 720P／1080P | 統一 |
| `happyhorse-1.1-i2v` | 文字 + 1 張首幀圖 | 3–15 秒 | 依請求 720P／1080P | 統一 |
| `happyhorse-1.1-r2v` | 文字 + 1–9 張參考圖 | 3–15 秒 | 依請求 720P／1080P | 統一 |
| `happyhorse-1.0-video-edit` | 1 支來源影片（3–60 秒）+ 最多 5 張參考圖 | 依來源影片長度 | 依請求 720P／1080P | **DashScope** |

> **wan-2-7 不論請求解析度皆輸出 1080P**
>
> `wan-2-7-t2v`／`wan-2-7-i2v` 即使請求 `720P` 仍回傳 1080P 影片，且計費依實際產出計算——5 秒影片會以 1080P 費率計價。請以 1080P 估算預算；若需要 720P 價位請改用 `happyhorse-1.1-*`。

> **HappyHorse 只支援 720P 與 1080P**
>
> 這些模型支援 `720P` 與 `1080P`。請求 `480P` **不會**被拒絕——會以約 1080P 產出並按 1080P 費率計費。需要 720P 價位請明確送 `720P`。

### 文生影片

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "a horse galloping across a green field" }],
    "resolution": "720P", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
```

### 圖生影片

加一個 `role: "first_frame"` 的圖片區塊：

```
"content": [
  { "type": "text", "text": "the subject turns slowly toward the camera" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

### 參考圖生影片

`happyhorse-1.1-r2v` 接受 1 至 9 張參考圖，每張帶 `role: "reference_image"`，在 prompt 中以 `[Image 1]`、`[Image 2]` 指代：

```
"content": [
  { "type": "text", "text": "[Image 1] walks into the room shown in [Image 2]" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

> **多圖合成請先小量驗證**
>
> `kling-o3-pro-reference` 帶多張 `reference_image`、在 prompt 寫「把 [Image 1] 放進 [Image 2] 的場景」時，跨圖合成指示不一定會執行，任務仍會出片並計費。批量生成前，先跑一支短的低解析度影片確認。

### 影片編輯

`happyhorse-1.0-video-edit` **請使用 DashScope 相容端點，不是統一端點。** 統一端點會以 `400 video-edit requires a source video` 拒絕此模型。改以 `input.media[]` 建立任務，並輪詢 `GET /omni/media/v1/tasks/{id}`：

```
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "happyhorse-1.0-video-edit",
    "input": {
      "prompt": "replace the background with a snowy street",
      "media": [
        { "type": "video",           "url": "https://example.com/source.mp4" },
        { "type": "reference_image", "url": "https://example.com/style.jpg" }
      ]
    },
    "parameters": { "resolution": "720P", "watermark": false }
  }'
# → 202 { "output": { "task_id": "cgt_...", "task_status": "PENDING" } }

curl https://api.atptoken.ai/omni/media/v1/tasks/cgt_... -H "Authorization: Bearer atp-..."
# → { "output": { "task_status": "SUCCEEDED", "video_url": "https://media.atptoken.ai/v/..." }, "usage": { … } }
```

- `input.media[].type` 只接受 `video` 與 `reference_image`，網址欄位名為 `url`（不是 `video_url`）。
- 來源影片與每一張參考圖都必須是公網免鑑權可直接下載的檔案；任一個抓不到時任務會以 `FAILED`＋`Failed to download …` 結束且不計費。
- 此端點回傳 DashScope 形狀（`output.task_status`、`output.video_url`），且輸出長度依來源影片長度，而非 `parameters.duration`。

### 計費

按輸出秒數 × 解析度計費，以 video tokens 計量（`寬 × 高 × 秒數 × 24 fps ÷ 1024`）。`-r2v` 與 `-video-edit` 的**輸入影片秒數一併計費**，例如以 5 秒來源影片產出 5 秒成品，計 10 秒。任務失敗不計費。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

### 其他模型特性

- **浮水印**：HappyHorse 浮水印**預設開啟**——需傳 `watermark: false` 關閉；Wan 2.7 預設關閉。
- **畫面比例**：HappyHorse 在共用清單之外另支援 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 長度**：5,000 字元（HappyHorse 中文 2,500 字）。
- 這些模型尚未支援 `generate_audio`。

## 錯誤

- 400 — 請求內容格式錯誤。
- 402 — `insufficient_quota`：專案餘額 ≤ 0（僅阻擋 create；poll / list / cancel 仍可用）。
- 403 — `permission_denied`：gated model 尚未對此專案開放。
- 422 — 該模型沒有影片供應商。
- 502 — 上游生成失敗。

## 下一步

- [Seedance 2.0](https://atptoken.ai/zh-tw/docs/seedance-2-0/) — `seedance-2-0` 的參數、媒體 role 與請求範例。
- [/v1/files](https://atptoken.ai/zh-tw/docs/files/) — 上傳檔案並換成可引用的 URL。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
