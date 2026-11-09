# 影片生成

> Source: https://atptoken.ai/zh-tw/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

影片生成是**非同步**的，沒有同步版本：先建立任務（回 `202` 和 task id），輪詢到終態，再下載簽章 URL。base URL 與 `atp-` 金鑰同圖像。**請求的寫法由模型決定**：同一個端點，不同模型收不同的欄位名，連大小寫都可能不同，不要從一個模型推另一個。

**每一個影片任務**

1. 建立任務 — `POST …/contents/generations/tasks` — 回 `202` + `cgt_…`
2. 輪詢到終態 — `GET …/contents/generations/tasks/{id}` — 四個終態都要跳出
3. 下載 `content.video_url` — 簽章 URL — 24 小時內有效
   - succeeded
   - failed：原因在 `error`
   - 超過 24 小時：仍是 `succeeded`，但 `video_url` 為 `null`、`expired: true`

- **`succeeded` 不保證拿得到檔案。** 超過 24 小時後狀態仍是 `succeeded`，但 `content.video_url` 變成 `null`，另有 `expired: true`，只能重建任務。要留存就下載，不要把網址存進資料庫當永久連結。
- **沒有 webhook，必須輪詢。** `callback_url` 會被接受，但不會被使用。
- 專案餘額耗盡時，建立任務會回 `402 insufficient_quota`。

## 選模型

不確定就用 `seedance-2-0`。先看模型屬於哪一系列：**請求外層由系列決定**。

| 系列 | 模型 | 文字與素材放哪 |
| --- | --- | --- |
| Seedance | `seedance-2-0`、`seedance-2-0-fast`、`seedance-2-0-mini`、`seedance-2-5` | `content[]`，見 [Seedance](https://atptoken.ai/zh-tw/docs/seedance-2-0/) |
| Kling | `kling-o3-*`、`kling-v3-*` | `content[]`；`-v2v`、`-video-edit` 例外，放 `input` |
| Wan 2.7、HappyHorse | `wan-2-7-t2v`、`wan-2-7-i2v`、`wan-2-7-video`、`happyhorse-1.1-t2v`／`-i2v`／`-r2v` | `content[]` |
| HappyHorse 影片編輯 | `happyhorse-1.0-video-edit` | 另一個端點，放 `input.media[]` |
| MiniMax | `minimax-h3` | `content[]` |
| Wan 3.0、spicy | `wan-3-0-video`、`wan-3-0-video-pro`、`wan-3-0-video-prime`、`wan-2-2-i2v-spicy`、`wan-2-7-i2v-spicy` | **扁平**：`prompt` 與素材放頂層 |

> **先確認這把金鑰能用哪些模型**
>
> 完整清單是 `GET https://api.atptoken.ai/v1/project/models`：這個專案放行的每一個模型，不分文字、影像、影片。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，影片模型不在裡面。
>
> 清單上沒有，不代表不能用；清單上有，也可能暫時沒有上游在服務。沒有權限時，建立任務會回 `403`，不收費。

**影片模型預設開放。** 管理者可以把特定模型設為受控，只有白名單帳號能用。收到 `403 permission_denied` 不是金鑰或餘額問題：換一個模型，或請管理者授權。這個機制只作用於影片，跟 chat 的權限無關。

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
# → 202 { "id": "cgt_..." }
```

必填只有 `model` 和 `content`（扁平系列是 `model` 和 `prompt`）。下表是端點接受的所有欄位；某個模型實際吃哪些，看該模型的段落。

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | 模型 ID |
| content | array · 必填 | 文字與素材區塊（見下方） |
| resolution | string | `480p` `720p` `1080p` `4k` `768P` `2K`；部分模型只吃大寫 |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive`（別名 `aspect_ratio`，但有模型會拒絕這個別名） |
| duration | integer | 秒數（與 `frames` 擇一） |
| frames | integer | 影格數（`duration` 的替代） |
| generate_audio | boolean | 生成音軌（別名 `add_audio`）；有模型的欄位叫 `audio` 或 `sound` |
| return_last_frame | boolean | 結果多帶 `content.last_frame_url` |
| seed | integer | |
| camera_fixed | boolean | |
| watermark | boolean | 有模型會拒絕 |

`callback_url`、`service_tier`、`safety_identifier`、`execution_expires_after` 會被接受但丟掉，對輸出沒有影響。

**`content[]` 區塊**：每個區塊是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。

- 只有文字 → 文生影片；含圖片 → 圖生影片。
- 網址放在 `image_url: { "url": "…" }`（影片用 `video_url`、音訊用 `audio_url`）。區塊**沒有頂層 `url`**，放錯會回 `400 missing content[1].image_url`。
- `role` 為 `first_frame`、`last_frame`、`reference_image`、`reference_video`、`reference_audio`。

**冪等**：帶 `Idempotency-Key`（或 `X-Idempotency-Key`、`X-Thankyou-Task-Id`），同一把 key 重送會回原本的 task id，不會重複建立、不會重複計費。影片、圖像、語音各用各的 key：同一把 key 先用在圖像再用在影片，會回 `409`。

### 欄位寫錯不會報錯

`content[]` 系列**不檢查欄位名**。拼錯的欄位、或這個模型不吃的欄位，一樣回 `202`，只是沒有效果。Kling、Seedance 沒宣告的頂層欄位會原樣轉給模型（例如 `negative_prompt`）；放進 `input: {…}` 的欄位也會轉送，而且同名時 `input` 裡的優先。

要確認參數有沒有生效，看輪詢結果裡的 `resolved_params`（模型實際採用的參數）；`params_raw` 是 gateway 實際送出的內容。`resolved_params` 也包含模型自己填的預設值，所以要比對**值**是不是你送的，不是只看欄位在不在。

扁平系列相反：多餘的欄位會被拒絕，回 `400 Extra inputs are not permitted`。

## 素材怎麼傳

`content[].image_url.url`（或 `video_url.url`、`audio_url.url`）可以放：

| 形式 | 說明 |
| --- | --- |
| 公開 `https://…` URL | 最簡單。模型要能免登入直接抓得到。 |
| base64 | 也接受。 |
| 素材 API 回傳的 `asset://…`（`AssetUri`） | 原樣放進來。部分模型要求這種方式，見下方。 |

**`/v1/files` 的檔案不能當素材。** 它回的 `an_…` 是 chat 用的檔案 id，放進 `image_url.url` 會回 `400 The parameter content[1].image_url specified in the request is not valid`；放 `https://api.atptoken.ai/v1/files/{id}` 也是 `400`。請把檔案放到公開 `https://` URL，或登記成素材。

圖片端點不支援 `asset://` 引用，收到時會在生成階段回 `provider_error / generation_failed`。

### 登記素材

登記素材本身也要一個公開網址，所以它不是「沒有公開網址時」的替代品，而是部分模型要求的另一種引用方式。

**把素材登記成 asset**

1. 建立素材群組 — `POST /omni/media/v1/asset-groups` — body：`Name`、`Description`、`model`（建議帶）
2. 登記素材 — `POST /omni/media/v1/assets` — body：`group_id`、`url`、`asset_type`、`name`
3. 輪詢到就緒 — `POST /omni/media/v1/assets/get` — body：`asset_id`；回傳 `AssetUri`
4. 建立影片任務 — `POST …/contents/generations/tasks` — `AssetUri` 放在 `content[].image_url.url`

```
{ "type": "image_url", "image_url": { "url": "asset://…" }, "role": "reference_image" }
```

這條鏈最常出錯的地方：

- **順序不能跳。** 沒有 `group_id` 不能登記。素材還沒就緒就建任務，回 `400`（`reason: asset_not_ready`）；素材建立失敗，回 `400`（`reason: asset_failed`）。所以第三步的輪詢不能省。
- **`asset_type` 一定要寫**，值是 `Image`、`Video`、`Audio`。不寫的話，影片可能被登記成圖片，而且不會報錯。
- **建群組時帶 `model`。** 帶了才保證這個群組之後能給那個模型用。
- **群組有配額（約 50 個）。** 重複使用群組，不要一個素材開一個。
- **`name` 最多 64 個字元。** 超過時登記照樣回 200，輪詢才看到失敗（`InvalidParameter.Name`），拿它建任務會得到 `ATP_ASSET_FAILED`。縮短名字即可。
- **同一個任務不能混用不同來源的素材**，會回 `400`。
- 狀態變成 `Completed` 或 `Active`（依上游而定）才算就緒。

**部分模型的登記是排隊的。** 每個群組每 20 秒只建立一筆，所以會立刻回一個 `asset-q-…` 的 id（`AssetUri` 是 `asset://asset-q-…`）、狀態 `Processing`，並用 `Retry-After` 給出預估秒數。輪詢到 `Completed` 再拿去建任務。不同群組各自排隊。

素材跟群組同壽命：群組被清理後（影片完成後回收，或每天清掉閒置超過一天的群組），這個 id 就查不到了。

`seedance-2-0-fast` 不接受素材，回 `422 this asset's upstream does not serve the requested model`，請直接傳公開網址。各 Seedance 模型的支援情況見 [Seedance](https://atptoken.ai/zh-tw/docs/seedance-2-0/)。

### 真人照片

真人照片用公開網址送出時，可能被拒，回 `400 may contain real person`。被擋時，把同一張圖登記成素材，改傳 `AssetUri`，**不需要核身**。`seedance-2-0-fast` 不能用素材，所以真人照片不要用它。

只有你的產品要求核身時，才走核身流程：

**真人素材核身（選用）**

1. 開始核身 — `POST /omni/media/v1/validate-session` — 回 `h5_link` + `session_ref`；不計費
2. 使用者完成核身 — 把 `h5_link` 給使用者 — 完成後你拿到 `byted_token`
3. 取得群組 — `POST /omni/media/v1/validate-result` — body：`session_ref`、`byted_token`；回 `group_id`
4. 登記素材並建任務 — `POST /omni/media/v1/assets` → `assets/get` → 建立任務 — 用上一步的 `group_id`

核身流程自己會給群組，**不要再去開新群組**。要查群組，用 `GET /omni/media/v1/asset-groups/{id}`（回 `group_type`）。

## 輪詢與下載

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| 狀態 | 終態 | 意思 |
| --- | --- | --- |
| `queued` | | 已入列，繼續輪詢 |
| `running` | | 生成中，繼續輪詢 |
| `succeeded` | ✓ | 有結果；仍要檢查 `video_url` 是不是 `null` |
| `failed` | ✓ | 失敗，原因在 `error: { code, message }` |
| `expired` | ✓ | 結果已不在 |
| `cancelled` | ✓ | 已取消 |

只等 `succeeded` 的迴圈碰到 `failed` 會永遠轉下去，四個終態都要跳出。影片是分鐘級的。

| 方法 | 路徑 | 動作 |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | 建立 |
| GET | /omni/media/v1/contents/generations/tasks/{id} | 輪詢；查不到或不是你的回 `404` |
| GET | /omni/media/v1/contents/generations/tasks | 列出本專案的任務 |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | `queued` → 取消；終態 → 刪紀錄；`running` → `409` |

要最後一幀：建立時送 `return_last_frame: true`，結果在 `content.last_frame_url`。

## Kling 影片模型

Kling 用和 Seedance 相同的端點。**操作與畫質由模型名稱決定，不是由參數決定**：`standard` 輸出 720p、`pro` 輸出 1080p（`-v2v`、`-video-edit` 例外）；後綴決定操作。

| 你要做什麼 | 模型 | 素材 |
| --- | --- | --- |
| 文生影片 | `kling-o3-standard`／`-pro`、`kling-v3-standard`／`-pro` | 只有文字 |
| 圖生影片 | 上述模型加 `-i2v` | 1 張 `first_frame` |
| 參考圖生影片 | `kling-o3-standard-reference`／`kling-o3-pro-reference`（1–6 張圖）、`-reference-7`（7 張圖） | `reference_image` |
| 拿原片當參考生新片 | `kling-o3-standard-v2v`、`kling-o3-pro-v2v` | 放在 `input`，見下方 |
| 修改原片 | `kling-o3-standard-video-edit`、`kling-o3-pro-video-edit` | 放在 `input`，見下方 |

素材用 `content[]` 送就好，gateway 會轉成模型要的格式，不要自己組 `reference_assets`（`-v2v`、`-video-edit` 除外）。尾幀（`last_frame`）請先不要送。

| 欄位 | 可用值 | 預設 |
| --- | --- | --- |
| `prompt`（文字區塊） | 最長 2500 字；`kling-v3-*` 必填 | |
| `ratio` | 只有 `16:9`、`9:16`、`1:1` | `16:9` |
| `duration` | 3–15 秒 | `5` |
| `resolution` | `720p`、`1080p`；**只有 `-i2v` 吃這個欄位** | |
| `generate_audio` | 布林值；`kling-o3-*` 用 | `true` |
| `sound` | 布林值；`kling-v3-standard`、`kling-v3-*-i2v` 用 | `false` |
| `negative_prompt` | 最長 1000 字；`kling-v3-*` | |
| `cfg_scale` | 0–1；`kling-v3-standard`／`-standard-i2v` | `0.5` |
| `guidance_scale` | 0–1；`kling-v3-standard`、`kling-v3-*-i2v` | `0.5` |
| `multi_prompt` | 陣列；`kling-o3-*` | |

和你送的值不一樣的地方：

- **音訊欄位兩群不同。** o3 用 `generate_audio`，**預設是 `true`**，不送就有音軌；要無聲就送 `false`。v3 用 `sound`。`kling-v3-pro` 沒有音訊欄位。
- **`-i2v` 不吃 `ratio`**，長寬比跟著輸入圖。送了不報錯，但不生效。
- **`-reference-7` 也不套用 `ratio`**：要 `16:9`，實際輸出 960×960。
- 要確定就看回來的影片，或比對 `resolved_params`。

### 文生影片

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-job-001" \
  -d '{
    "model": "kling-o3-standard",
    "content": [{ "type": "text", "text": "an orange cat walking slowly along the beach at sunset, steady tracking shot" }],
    "ratio": "16:9",
    "duration": 5,
    "generate_audio": false
  }'
# → 202 { "id": "cgt_..." }
```

### 圖生影片

```
{
  "model": "kling-o3-standard-i2v",
  "content": [
    { "type": "text", "text": "the person slowly turns and smiles; keep the outfit and background unchanged" },
    { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "duration": 5
}
```

選 Pro 時換成 Pro 的模型 ID，並把 `resolution` 改成 `1080p`。

### 參考圖生影片

```
{
  "model": "kling-o3-standard-reference",
  "content": [
    { "type": "text", "text": "the figure turns and walks away" },
    { "type": "image_url", "image_url": { "url": "https://example.com/figure.jpg" }, "role": "reference_image" }
  ],
  "ratio": "16:9",
  "duration": 3,
  "generate_audio": false
}
```

### 影片轉影片與影片編輯

先選操作：要**改這支原片**（換背景、換物件、改風格，其餘保留）選 `-video-edit`；要**拿原片當動作或內容參考，生一支新片**選 `-v2v`。

這兩類的請求放在 **`input`**，不是 `content[]`。來源影片要放在公開 `https://` 網址：

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-edit-001" \
  -d '{
    "model": "kling-o3-standard-video-edit",
    "input": {
      "prompt": "Replace the cat in the video with a Shiba Inu. Keep the motion, camera and everything else unchanged.",
      "reference_assets": [
        { "role": "source_video", "asset_type": "video", "url": "https://example.com/source.mp4" }
      ],
      "keep_original_sound": false
    }
  }'
# → 202 { "id": "cgt_..." }
```

| 欄位（都在 `input` 裡） | 可用值 | 說明 |
| --- | --- | --- |
| `prompt` | 最長 2500 字 | 必填 |
| `reference_assets` | 陣列 | 必填。恰好一個 `source_video`；參考圖 0–4 張 |
| `keep_original_sound` | 布林值 | 預設 `false`。要保留原片聲音送 `true` |
| `duration` | 3–15 秒 | 只有 `-v2v`；不送時 `5` |

要指定新主體的長相，再加參考圖，每張一個項目，在 prompt 裡用「the dog in Image 1」指名它：

```
{ "role": "reference", "asset_type": "image", "url": "https://example.com/dog.jpg" }
```

**輸出跟著原片，不照 standard／pro 的 720p／1080p 規則。** 給一支 1280×720、3 秒的原片：`-video-edit` 輸出 1280×720、3 秒（pro 也一樣）；`-v2v` 不送 `duration` 時輸出 1280×720、5 秒。

**prompt 第一句寫要改什麼。** 點名目標、說出新狀態，保留只用一句帶過。逐項列出要保留的東西，或要求新主體符合舊主體的外觀，模型可能判斷成「什麼都不改」：任務照樣 `succeeded`，回來的還是原片。`succeeded` 不代表修改生效，要看回來的影片。

這兩類寫錯時在建立就被拒，不建立任務、不收費：

- 影片放在 `content[]`（不論 `role` 是 `source_video` 還是 `reference_video`）→ `422 The parameter combination is not supported.`
- 參考圖的 `role` 寫成 `reference_image` 或 `image` → 同上。這裡要寫 `reference`。

## 阿里影片模型

`wan-2-7-t2v`／`wan-2-7-i2v` 與 HappyHorse 的文生／圖生／參考圖模型用同一個端點與 `content[]` 寫法，以下只列各模型特有之處。**`happyhorse-1.0-video-edit` 是例外：它用另一個端點**（見下）。

| 模型 | 輸入 | 時長 | 計費解析度 | 端點 |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | 文字 | 2–15 秒 | **一律 1080P**（見注意事項） | 統一 |
| `wan-2-7-i2v` | 文字 + 1 張 `first_frame` | 2–15 秒 | **一律 1080P**（見注意事項） | 統一 |
| `happyhorse-1.1-t2v` | 文字 | 3–15 秒 | 依請求 720p／1080p | 統一 |
| `happyhorse-1.1-i2v` | 文字 + 1 張 `first_frame` | 3–15 秒 | 依請求 720p／1080p | 統一 |
| `happyhorse-1.1-r2v` | 文字 + 1–9 張 `reference_image` | 3–15 秒 | 依請求 720p／1080p | 統一 |
| `happyhorse-1.0-video-edit` | 1 支來源影片（3–60 秒）+ 最多 5 張參考圖 | 依來源影片長度 | 依請求 720P／1080P | **video-synthesis** |

| 欄位 | 可用值 | 說明 |
| --- | --- | --- |
| `resolution` | `720p`、`1080p`（小寫） | 只有這兩階 |
| `ratio` | `16:9` 等 | 與 `resolution` 搭配使用 |
| `duration` | 整數秒 | 範圍見上表 |
| `watermark` | 布林值 | |
| `seed` | 整數 | |
| `audio_setting` | | 只有 `-video-edit` |

> **有些模型可能暫時無法服務**
>
> `wan-2-7-t2v`、`wan-2-7-i2v`、`happyhorse-1.1-t2v` 可能在建立時就回 `404 not_found_error — upstream returned 404`。這是模型暫時無法服務，不是寫錯；不會建立任務，也不收費。要文字生影片可改用 `wan-2-7-video`（同樣的 `content[]` 寫法），或稍後再試。

> **wan-2-7 不論請求解析度皆輸出 1080P**
>
> `wan-2-7-t2v`／`wan-2-7-i2v` 即使請求 `720p` 仍回傳 1080P 影片，且計費依實際產出計算——5 秒影片會以 1080P 費率計價。請以 1080P 估算預算；若需要 720P 價位請改用 `happyhorse-1.1-*`。

> **HappyHorse 只支援 720p 與 1080p**
>
> 送 `480p` 等於沒送，會用模型自己的預設：約 1080P 產出、按 1080P 費率計費。需要 720P 價位請明確送 `720p`。

### 文生影片

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: hh-job-001" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "a horse galloping across a green field" }],
    "resolution": "720p", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
# → 202 { "id": "cgt_..." }
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

### 影片編輯

`happyhorse-1.0-video-edit` **要用 video-synthesis 端點，不是統一端點。** 送到統一端點會在建立時回 `400`，訊息要你改用這個端點、把影片放在 `input.media[]`。建立後輪詢 `GET /omni/media/v1/tasks/{id}`：

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
- **寫錯時建立仍回 `202`**，錯誤要等輪詢才以 `InvalidParameter` 出現，例如 `InvalidParameter: Field required: input.media`。建立成功不代表內容正確。
- 來源影片與每一張參考圖都必須能免登入直接下載；任一個抓不到時任務會以 `FAILED`＋`Failed to download …` 結束且不計費。
- 這個端點回自己的格式（`output.task_status`、`output.video_url`）；過期後是 `SUCCEEDED` + `video_url: null`。輸出長度依來源影片，不是 `parameters.duration`。
- 這個模型也可能在建立時回 `404 not_found_error — upstream returned 404`，意思同上：暫時無法服務，不收費。
- 權限、餘額與計費規則跟統一端點完全相同。

### 其他模型特性

- **浮水印**：HappyHorse 浮水印**預設開啟**——需傳 `watermark: false` 關閉；Wan 2.7 預設關閉。
- **畫面比例**：HappyHorse 在共用清單之外另支援 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 長度**：5,000 字元（HappyHorse 中文 2,500 字）。
- 這些模型尚未支援 `generate_audio`。

## Wan 3.0 與 spicy：扁平請求

`wan-3-0-video`、`wan-3-0-video-pro`、`wan-3-0-video-prime`、`wan-2-2-i2v-spicy`、`wan-2-7-i2v-spicy` **不吃 `content[]`**，`prompt` 和素材都放在頂層。`content` 陣列會被丟掉；丟掉後內容變空，會回 `missing_prompt_or_image`。

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: wan3-job-001" \
  -d '{
    "model": "wan-3-0-video",
    "prompt": "a paper boat drifting on still water",
    "first_frame": "https://example.com/first-frame.png",
    "resolution": "480P",
    "ratio": "16:9",
    "duration": 4,
    "audio": false,
    "prompt_extend": false
  }'
# → 202 { "id": "cgt_..." }
```

**最容易寫錯的兩處：音訊欄位叫 `audio`，不是 `generate_audio`；`resolution` 要大寫。**

| 欄位 | 可用值 | 預設 |
| --- | --- | --- |
| `prompt` | 字串 | 必填 |
| `first_frame`、`last_frame` | 圖片 URL | 首尾幀模式 |
| `reference_images` | 最多 10 個 URL | 參考素材模式 |
| `reference_videos`、`reference_audios` | 各最多 5 個 URL | 參考素材模式 |
| `resolution` | `480P`、`720P`、`1080P`；`-pro` 另有 `2K`、`4K` | `480P` |
| `duration` | `-1`（用模型預設長度，有輸入影片時通常跟著影片），或 2–30 秒 | `4` |
| `ratio` | `16:9`、`9:16`、`4:3`、`3:4`、`1:1`、`adaptive` | `16:9` |
| `audio` | 布林值 | `false` |
| `prompt_extend` | 布林值 | `false` |

- 支援文生影片、首幀、首尾幀、參考圖＋參考音訊、參考影片。
- 同一個請求只能用首尾幀模式**或**參考素材模式，不能混用。
- 送 `aspect_ratio`、`generate_audio`、`watermark` 或 `media` 會回 `400 Extra inputs are not permitted`。`content` 會被丟掉，`input` 會被拆開併到頂層，都不要用。
- 兩個 spicy 模型跟 `wan-3-0-video*` 同一種扁平格式，欄位名規則相同。

## MiniMax H3

`minimax-h3` 用 `content[]` 寫法：

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: minimax-job-001" \
  -d '{
    "model": "minimax-h3",
    "content": [{ "type": "text", "text": "a paper boat drifting on still water" }],
    "resolution": "768P",
    "duration": 6
  }'
# → 202 { "id": "cgt_..." }
```

- `resolution` 只有 `768P` 與 `2K` 兩階；送 `480p`、`720p`、`1080p`、`4k` 會對映到這兩階。
- **不要送 `watermark`。** 不論 `false` 或 `"false"`，都會在建立時回 `400 invalid params, watermark is invalid (2013)`。

## 計費

任務進入終態後才結算，依**實際**用量扣款：

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` 是輸入影片秒數、`out_dur` 是輸出秒數、`W × H` 是輸出的寬高。有些模型會自己回報用量，這時以回報的為準。輪詢結果的 `usage` 是 token 用量，影片的 input 永遠是 0。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

- **建立時只做輕量預留**：只要餘額還是正的就放行；餘額耗盡（`credit − inflight ≤ 0`）才回 `402`。
- 結算時餘額不足會扣成負值，**下一個請求會被擋住**。
- 受控與否只決定誰能用，不影響計價；不受控的模型照樣計費。
- 在建立時就被拒的請求不建立任務、不收費。任務失敗不計費。
- 帶輸入影片的模型（例如 `-r2v`、`-video-edit`）**輸入秒數一併計費**：以 5 秒來源影片產出 5 秒成品，計 10 秒。

## 錯誤

**4xx 要讀訊息，不要只看狀態碼。** 模型自己的 4xx 會原樣轉給你，訊息通常直接指名欄位與合法值。回報問題時帶上回應的 `x-request-id`。

- 400 — 請求格式錯：缺 `model` 或 prompt、混用不同來源的素材、`asset_not_ready`、`asset_failed`。讀訊息後修正。
- 401 — `token_revoked`：金鑰無效，或**根本沒送金鑰**。先確認 header 有送出。
- 402 — `insufficient_quota`：專案餘額耗盡。不是暫時性限流，**不要重試**，加值後再送。
- 403 — `permission_denied`：這個模型受控，專案不在白名單。換模型或請管理者授權。
- 404 — 建立時回 `upstream returned 404`：模型暫時無法服務，換模型或稍後再試。輪詢時回 404：任務不存在或不是你的。
- 409 — 這把 `Idempotency-Key` 已用在另一個媒體介面；或想取消 `running` 的任務。
- 422 — 請求外層或素材角色不是這個模型要的；或素材不能給這個模型用；或模型目前沒有可用容量。
- 429 — 限流。退避後重試。
- 502 — 建立失敗。可以重試（冪等保留會釋放）。
- 503 — 入列失敗，或 `balance_check_unavailable`（**讀不到餘額，不是餘額不足**；沒有扣款）。依 `Retry-After` 重試。

常見訊息（都在建立時就被拒，不建立任務、不收費）：

| 訊息 | 原因 | 怎麼辦 |
| --- | --- | --- |
| `422 The parameter combination is not supported.` | 外層或素材角色不對，最常見是 Kling `-v2v`／`-video-edit` 把影片放進 `content[]` | 照該模型的範例寫 |
| `422 this asset's upstream does not serve the requested model` | 素材不能給這個模型用（例如 `seedance-2-0-fast`） | 改傳公開網址 |
| `400 may contain real person` | 公開網址的圖含真人 | 登記成素材，傳 `AssetUri` |
| `400 The parameter content[1].image_url specified in the request is not valid` | `url` 不是可下載的網址，例如 `/v1/files` 的 `an_…` | 放公開網址或 `AssetUri` |
| `400 missing content[1].image_url` | 網址放在區塊頂層 | 放進 `image_url: { "url": … }` |
| `400 Extra inputs are not permitted` | 扁平模型收到不認得的欄位 | 用該模型自己的欄位名 |
| `400 invalid params, watermark is invalid (2013)` | 這個模型不收 `watermark` | 拿掉 `watermark` |

任務本身失敗時，狀態是 `failed`，原因在 `error`。

## 下一步

- [Seedance](https://atptoken.ai/zh-tw/docs/seedance-2-0/) — Seedance 2.0 與 2.5 的模型選擇、素材組合、參數與範例。
- [/v1/files](https://atptoken.ai/zh-tw/docs/files/) — 上傳給 chat 與 messages 請求使用的檔案。媒體任務無法使用。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
