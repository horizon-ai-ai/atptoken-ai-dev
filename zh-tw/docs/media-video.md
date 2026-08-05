# 影片生成

> Source: https://atptoken.ai/zh-tw/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

影片生成是**非同步**的：先建立任務（`202` + task id），輪詢到終態後再讀簽章 URL。base URL 與 `atp-` key 同圖像。gateway 把 unified `model` 路由到影片 provider，同名可容錯切換。可用影片模型：`seedance-2-0`（標準）、`seedance-2-0-mini`（輕量／較省）、`seedance-2-0-fast`（加速），及 Kling 系列（preview）：`kling-v3-standard`/`-pro`、`kling-o3-standard`/`-pro`（含 `-i2v`／`-reference`／`-reference-7`／`-v2v`／`-video-edit` 變體）——均按秒×解析度計費（Kling 音訊生成暫未開放）；以及阿里系列（preview）：`wan-2-7-t2v`、`wan-2-7-i2v`、`happyhorse-1.1-t2v`、`happyhorse-1.1-i2v`、`happyhorse-1.1-r2v`（最多 9 張參考圖）與 `happyhorse-1.0-video-edit`（來源影片 3–60 秒＋最多 5 張參考圖）。HappyHorse 時長 3–15 秒、浮水印預設開啟（可傳 `watermark: false` 關閉）；`wan-2-7-*` 目前不論請求解析度皆輸出並依 1080P 計費。名稱以 `GET /v1/models` 確認。

- **成功的任務帶 `content.video_url`——帶簽章的邊緣 URL，**TTL 30 分鐘**。逾期後任務仍回 `succeeded` 但 `video_url` 為 `null` 且 `expired: true`（需重建重生）。**
- 當 project 餘額 ≤ 0，請求會以 `402 insufficient_quota` 拒絕。

> **先確認模型與 project 權限**
>
> 請使用建立任務時的同一把 key 呼叫 `GET https://api.atptoken.ai/v1/models`。模型未出現在回應中，就不能由該 project 使用；安裝 Skill 或知道模型名稱不會繞過 allowed models。

#### 建立任務

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
| model | string · 必填 | unified video model (`video` pool) |
| content | array · 必填 | multimodal input blocks (see below) |
| resolution | string | `480p` / `720p` / `1080p` / `4k` |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` (alias `aspect_ratio`) |
| duration | integer | seconds (mutually exclusive with `frames`) |
| frames | integer | frame count (alt to `duration`) |
| generate_audio | boolean | add a soundtrack (alias `add_audio`) |
| seed | integer | |
| watermark | boolean | |

**`content[]` 區塊** — 每個區塊是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。只有文字 → 文生影片；含圖片 → 圖生影片。`image_url`/`video_url` 帶 `{ "url": "…" }`；`role` 為 `first_frame` / `last_frame` / `reference_image` / `reference_video`。

#### `url` 接受哪些形式

> **2026-08-04 對 production 實測**
>
> **影片端點只接受公開 `https://` URL。**
>
> | 形式 | 影片端點 | 圖片端點 |
> | --- | --- | --- |
> | 公開 `https://…` URL | 可用 | 可用 |
> | `data:image/…;base64,…` | **被擋**——`invalid_parameters: The parameter combination is not supported.` | 可用 |
> | `asset://<id>`／`asset://<pid>.<id>` | **不支援** | **不支援** |
>
> 本頁舊版把 `asset://` 列為合法形式，實際不是：兩種寫法、兩個端點都在生成階段失敗，回 `provider_error / generation_failed`。不要浪費呼叫去試。

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

把那個 `Location` 值當 `url` 用。它免驗證即可下載——正是上游 provider 需要的——但約 15 分鐘就過期，所以請在建立任務前才解析，不要快取。

#### 輪詢至終態

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

### 阿里影片模型 — 模型指南

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
> `wan-2-7-t2v`／`wan-2-7-i2v` 目前即使請求 `720P` 仍回傳 1080P 影片，且計費依實際產出計算——5 秒影片會以 1080P 費率計價。請以 1080P 估算預算；若需要 720P 價位請改用 `happyhorse-1.1-*`。

> **HappyHorse 只支援 720P 與 1080P**
>
> 這些模型支援 `720P` 與 `1080P`。請求 `480P` **不會**被拒絕——會以約 1080P 產出並按 1080P 費率計費。需要 720P 價位請明確送 `720P`。

**文生影片**

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "一匹馬奔馳過綠色草原" }],
    "resolution": "720P", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
```

**圖生影片** — 加一個 `role: "first_frame"` 的圖片區塊：

```
"content": [
  { "type": "text", "text": "主體緩緩轉向鏡頭" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

**參考圖生影片**（`happyhorse-1.1-r2v`）— 1 至 9 張參考圖，每張帶 `role: "reference_image"`，在 prompt 中以 `[Image 1]`、`[Image 2]` 指代：

```
"content": [
  { "type": "text", "text": "[Image 1] 走進 [Image 2] 的房間" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

> **多圖合成請先小量驗證**
>
> 2026-08-04 對 production 實測一次：`kling-o3-pro-reference` 帶兩張 `reference_image`、prompt 寫「把 [Image 1] 放進 [Image 2] 的場景」，任務被接受、有出片、也照常計費——但**那個合成指示沒有被執行**，產出沿用了 Image 1 自己的背景。這是單次測試、素材為合成圖，不足以斷定功能壞掉；但也請不要假設 `[Image N]` 跨圖合成一定生效：先跑一支短的低解析度片子看過，再決定要不要批量生成。

**影片編輯**（`happyhorse-1.0-video-edit`）— **請使用 DashScope 相容端點，不是統一端點。** 統一端點會以 `400 video-edit requires a source video` 拒絕此模型。改以 `input.media[]` 建立任務，並輪詢 `GET /omni/media/v1/tasks/{id}`：

```
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "happyhorse-1.0-video-edit",
    "input": {
      "prompt": "把背景換成下雪的街道",
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

`input.media[].type` 只接受 `video` 與 `reference_image`，網址欄位名為 `url`（不是 `video_url`）。來源影片與每一張參考圖都必須是公網免鑑權可直接下載的檔案；任一個抓不到時任務會以 `FAILED`＋`Failed to download …` 結束且不計費。此端點回傳 DashScope 形狀（`output.task_status`、`output.video_url`），且目前輸出長度依來源影片長度，而非 `parameters.duration`。

**計費** — 按輸出秒數 × 解析度計費，以 video tokens 計量（`寬 × 高 × 秒數 × 24 fps ÷ 1024`）。`-r2v` 與 `-video-edit` 的**輸入影片秒數一併計費**，例如以 5 秒來源影片產出 5 秒成品，計 10 秒。任務失敗不計費。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

**其他模型特性**

- **浮水印**：HappyHorse 浮水印**預設開啟**——需傳 `watermark: false` 關閉；Wan 2.7 預設關閉。
- **畫面比例**：HappyHorse 在共用清單之外另支援 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 長度**：5,000 字元（HappyHorse 中文 2,500 字）。
- 這些模型目前不支援 `generate_audio`。

### 錯誤

- 400 — invalid request body.
- 402 — `insufficient_quota`：project balance ≤ 0（僅阻擋 create；poll / list / cancel 仍可用）。
- 403 — `permission_denied`：gated model 尚未對此 project 開放。
- 422 — the model has no video provider.
- 502 — upstream generation failed.
