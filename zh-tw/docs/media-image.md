# 圖像生成

> Source: https://atptoken.ai/zh-tw/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

圖像生成是**非同步**的，沒有同步版本。流程是三步：建立任務（回 `202` + `img_…` 任務 id）→ 輪詢到終態 → 在 24 小時內下載 `data[].url`。把 client 指向媒體 base URL `https://api.atptoken.ai/omni/media/v1`，用專案（project）的 `atp-` 金鑰驗證。流程與影片生成一致。

- **輸出是簽章 URL（`https://media-<env>.atptoken.ai/v/...`），效期 24 小時**，不會內嵌 base64。要留存就下載，不要把 URL 當永久連結存起來。
- 專案餘額 ≤ 0 時，請求會以 `402 insufficient_quota` 拒絕。
- `callback_url` 會被接受，但**不會有 webhook**。一定要輪詢。

> **先確認這把金鑰能用哪些模型**
>
> 完整清單是 `GET https://api.atptoken.ai/v1/project/models`：列出這個專案放行的所有模型，不分文字、圖像、影片、語音。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，**圖像模型不在裡面**。清單上沒有不代表不能用；沒有授權的模型會在建立任務時回 `403`，不收費。

## 建立任務

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "nano-banana-pro", "prompt": "an isometric paper-craft city at golden hour", "aspect_ratio": "16:9", "image_size": "2K" }'
# → 202 { "id": "img_..." }
```

回 `202` 時**圖還沒生出來**，拿到的是任務 id。不確定用哪個模型，就先用 `nano-banana-pro`。

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | 圖像模型名稱，例如 `nano-banana-pro`、`qwen-image-3.0`、`gpt-image-2` |
| prompt | string | 文字提示。大多數模型必填。只靠影像輸入的模型（例如帶 `face_image` 的 `face-swap`）可以不帶。prompt 和輸入圖都沒有時回 `400` |
| 其他欄位 | 依模型而定 | 除了 `model`，其餘欄位都**原名原值轉發**給模型。各模型的欄位見下一節 |

> **填錯的欄位不會報錯，只會被忽略**
>
> 模型不認得的欄位會被**安靜忽略**：請求照樣回 `202`、照樣生出一張圖，只是不是你要的那張。最常見的三個：
>
> - `size: "1024x1024"` 送給 `nano-banana*`：被忽略。要用 `image_size` + `aspect_ratio`。
> - `size` 放在頂層送給 `qwen-image-3.0`：被忽略。它只讀 `parameters.size`。
> - `n: 4` 送給 `nano-banana*`：被忽略。要用 `num_images`。
>
> 要確認參數有沒有生效，請比對輸出，不要只看狀態碼。反過來，模型**認得但不接受**的值會回 4xx，訊息會指名欄位與合法值，照著改就好。

**冪等鍵：** 網路失敗重試建立時，沿用同一個 `Idempotency-Key`；真正的新任務用新的鍵。圖像、影片、語音各用各的鍵：同一把鍵先用在影片、再用在圖像，會回 `409`。

## 各模型的參數

### nano-banana 系列

適用 `nano-banana`、`nano-banana-2`、`nano-banana-pro`，以及改圖用的 `nano-banana-edit`、`nano-banana-2-edit`、`nano-banana-pro-edit`。

| 欄位 | 型別 | 說明 |
|---|---|---|
| prompt | string · 必填 | 文字提示，`-edit` 系列也要帶 |
| aspect_ratio | string | `auto` `21:9` `16:9` `3:2` `4:3` `5:4` `1:1` `4:5` `3:4` `2:3` `9:16` `4:1` `1:4` `8:1` `1:8` |
| image_size | string | `1K` / `2K` / `4K`。**只有 `-pro` 與 `-2` 支援**，也是計費檔位 |
| num_images | integer | 1–4。**只有 `-pro` 與 `-2` 支援** |
| output_format | string | `jpeg` / `png` / `webp` |
| seed | number | `-1` 為隨機 |
| safety_tolerance | string | `1`–`6`，預設 `6` |
| enable_web_search | boolean | **只有 `-pro` 與 `-2` 支援** |
| thinking_level | string | `minimal` / `high`。**只有 `-2` 支援** |
| reference_assets | array | 輸入圖，`[{ "asset_type": "image", "url": "…" }]`，`nano-banana-2` 系列最多 14 張，`nano-banana`、`nano-banana-pro` 系列最多 10 張。**`-edit` 系列必填**，見下方「改圖」一節 |

這個系列不讀 `size`、`quality`、`n`。

### qwen-image-3.0 / qwen-image-3.0-pro

這兩個是**唯一參數不放頂層**的模型：只讀巢狀的 `parameters` 物件，頂層的同名欄位會被安靜忽略。`{"size": "1024*1024"}` 沒有作用，要寫成 `{"parameters": {"size": "1024*1024"}}`。

| 欄位（放在 `parameters` 內） | 型別 | 說明 |
|---|---|---|
| size | string | **星號**格式 `寬*高`，例如 `1024*1024`，不是 `1024x1024`。面積要在 512×512 到 2560×2560 之間，超出會失敗並指名實際面積。也決定計費檔位（1k/2k/4k）。不填預設 2048×2048 |
| n | integer | 張數，**每張都計費** |
| prompt_extend | boolean | **預設 `true`**：模型會自動改寫你的 prompt（回應的 `rewrite_status` 會是 `success`）。要照原文送，明確給 `false` |
| watermark | boolean | 浮水印 |

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-image-3.0",
    "prompt": "a red square on a white background",
    "parameters": { "size": "1024*1024", "n": 1, "prompt_extend": false }
  }'
# → 202 { "id": "img_..." }
```

### gpt-image-2 / gpt-image-2-edit

這兩個讀 OpenAI Images 的欄位：

| 欄位 | 型別 | 說明 |
|---|---|---|
| prompt | string · 必填 | 文字提示 |
| size | string | **叉號**格式，例如 `1024x1024` |
| quality | string | 畫質 |
| n | integer | 張數，預設 `1` |
| images | array | **只有 `gpt-image-2-edit`，必填**：輸入圖 1–4 張，形狀 `[{ "image_url": "…" }]`，可放公開 https 網址或 data URI |
| output_format | string | `png`（預設）、`jpeg`、`webp` |

### face-swap

這個模型**不吃文字**，參數只有三個：

| 欄位 | 型別 | 說明 |
|---|---|---|
| image | string | 要被換臉的底圖 |
| face_image | string · 必填 | 要換上去的臉。有它就不需要 `prompt` |
| seed | number | 隨機種子 |

只送 `image`、沒有 `face_image` 時，不會免除 `prompt`，會得到「prompt is required」。

### 其他圖像模型

`qwen-image-edit-spicy`、`wan-2-7-image`、`wan-2-7-pro-image`、`z-image-spicy` 沒有可查的參數表。做法是：先送 `model` + `prompt`（加上你的輸入圖），再讀回應。模型認得但不接受的欄位會回 4xx 並指名欄位與合法值；請求成功不代表欄位生效，要比對輸出。

## 改圖：輸入圖放哪裡

同一個端點、同一個流程，但**不同模型放輸入圖的位置完全不同**：

| 模型 | 輸入圖放哪裡 | 形狀 |
| --- | --- | --- |
| `nano-banana-edit`、`nano-banana-2-edit`、`nano-banana-pro-edit` | 頂層 `reference_assets` | `[{ "asset_type": "image", "url": "…" }]`，`nano-banana-2-edit` 最多 14 張、另兩個最多 10 張，必填 |
| `qwen-image-3.0`、`qwen-image-3.0-pro` | `messages` 裡的 content block | `{ "type": "image", "image": "<data URI 或 URL>" }`，**不是** `image_url` |
| `gpt-image-2-edit` | 頂層 `images` | `[{ "image_url": "…" }]`，1–4 張，必填。**不要用 `reference_assets`**：建立會成功，但輪詢時才失敗 |
| `face-swap` | `image` 與 `face_image` | 見上一節 |

### nano-banana 的 `-edit` 系列

> **輸入圖要放在頂層 `reference_assets`**
>
> 輸入圖要放在**頂層 `reference_assets` 陣列、元素是物件**：`[{ "asset_type": "image", "url": "…" }]`。
>
> - `content[]`、`image`、`image_url` 三種寫法都會被擋 `422 Invalid input.reference_assets: required.`
> - 給一個純字串陣列也會被擋 `Invalid input.reference_assets`。

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-edit-001" \
  -d '{
    "model": "nano-banana-pro-edit",
    "prompt": "Background: a sunlit marble kitchen counter. Preserve the product exactly — same shape, label text, colors and proportions as the reference.",
    "reference_assets": [
      { "asset_type": "image", "url": "https://example.com/product.png" }
    ],
    "aspect_ratio": "16:9",
    "image_size": "2K",
    "output_format": "png"
  }'
# → 202 { "id": "img_..." }
```

這個系列改圖時仍然必填 `prompt`。帶一句簡短指示就夠。

**`url` 接受哪些形式**（圖片端點）：

| 形式 | 圖片端點 | 說明 |
| --- | --- | --- |
| 公開 `https://…` URL | 可用 | 上游必須能**免驗證**抓取 |
| `data:image/png;base64,…` | 可用 | 整段內容都塞在 request body，base64 請控制在 2 MB 以內，過大可能在上游失敗 |
| `asset://<id>`／`asset://<pid>.<id>` | **不支援** | 每次都在生成階段失敗，回 `provider_error / generation_failed` |

`/v1/files` 上傳的檔案不能用在這裡：它回的 `an_<ulid>` 是 chat 用的檔案 id，不是媒體引用，`GET /v1/files/{id}` 回傳的也是檔案內容，不是 URL。要用本機圖片，請放到公開 `https://` URL，或把小圖片編碼成 `data:` URI 傳入。見 [/v1/files](https://atptoken.ai/zh-tw/docs/files/)。

### qwen-image 改圖

qwen-image 改圖走 `messages`，參數照樣放在 `parameters`：

```
{"model": "qwen-image-3.0",
 "parameters": {"size": "1024*1024", "n": 1, "prompt_extend": false},
 "messages": [{"role": "user", "content": [
   {"type": "image", "image": "data:image/png;base64,…"},
   {"type": "text",  "text": "make the square blue"}]}]}
```

- 輸入圖的 block 是 `{"type": "image", "image": …}`，這兩個模型不收 `image_url` 的形狀。
- 送了 `messages` 就以你的為準。若同時送 `prompt`，`prompt` 會接在最後成為另一則 user 訊息，兩者都不會被丟掉。

## 輪詢至終態

每 3–8 秒輪詢一次。任務一建立就查得到：

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

狀態只有六個，其中四個是終態：

| 狀態 | 終態 | 意思 |
| --- | --- | --- |
| `queued` | 否 | 已入列，繼續輪詢 |
| `running` | 否 | 正在生成，繼續輪詢 |
| `succeeded` | 是 | 有結果，在 `data[].url` |
| `failed` | 是 | 失敗，原因在 `error` |
| `expired` | 是 | 結果已經不在了 |
| `cancelled` | 是 | 被取消 |

- **四個終態都要跳出迴圈。** 只等 `succeeded` 的迴圈遇到 `failed` 會永遠轉下去。
- **`succeeded` 不保證拿得到檔案。** 超過 24 小時後，狀態仍是 `succeeded`，但 `data[].url` 變成 `null`，另外多一個 `expired: true`。判完 `succeeded` 還要檢查 URL 是不是 `null`。要重拿只能重新生成。
- `data` 是陣列，一次生多張時每張一個 URL，要全部就走完整個陣列。
- `usage` 回報 token 用量；`meters` 說明這次任務實際依什麼計量（按張計價的模型沒有 token，看 `meters`）。
- `failed` 任務帶 `error` 物件（`code`、`message`；若失敗帶有 HTTP 狀態碼，另有 `upstream_status`）。
- **參數值的錯誤可能在輪詢時才出現。** `nano-banana` 系列、`gpt-image-2`、`qwen-image` 系列在建立時只檢查請求形狀，參數值不合法會在輪詢時變成 `failed`，例如 qwen-image 尺寸超界會是 `{"code":"upstream_400","upstream_status":400,"message":"Image area must be between …"}`。`kling-*` 系列則在建立當下就回錯誤，狀態碼原樣轉給你。
- **`data[].url` 的副檔名不能當格式依據**：結尾寫 `.png` 的 URL 實際位元組可能是 JPEG。若格式會影響後續處理（例如把結果再上傳、或做轉檔），請用位元組（magic number）判斷，不要相信檔名。

| Method | Path | 動作 |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | 建立 |
| GET | /omni/media/v1/images/generations/tasks/{id} | 輪詢；查不到或不屬於你的專案回 `404` |
| GET | /omni/media/v1/images/generations/tasks | 列出這個專案的任務 |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | `queued` 會取消；已終態會刪除紀錄；`running` 回 `409`，不能取消 |

## Python 範例

最小的建立＋輪詢流程：

```python
import os, time, requests

BASE = "https://api.atptoken.ai/omni/media/v1"
HEADERS = {
    "Authorization": f"Bearer {os.environ['ATP_API_KEY']}",
    "Content-Type": "application/json",
}

resp = requests.post(
    f"{BASE}/images/generations/tasks",
    headers={**HEADERS, "Idempotency-Key": "img-job-001"},
    json={
        "model": "gpt-image-2",
        "prompt": "a watercolor cat",
        "size": "1024x1024",
        "quality": "high",
        "n": 1,
    },
    timeout=60,
)
resp.raise_for_status()
task_id = resp.json()["id"]

while True:
    task = requests.get(
        f"{BASE}/images/generations/tasks/{task_id}", headers=HEADERS, timeout=60
    ).json()
    if task["status"] in ("succeeded", "failed", "cancelled", "expired"):
        break
    time.sleep(5)

if task["status"] != "succeeded":
    raise RuntimeError(task.get("error"))

for i, item in enumerate(task["data"]):
    if item.get("url") is None:  # signed URL expired after 24h (expired: true)
        raise RuntimeError("result expired; generate again")
    image = requests.get(item["url"], timeout=120).content  # signed URL, 24h TTL
    with open(f"result_{i}.png", "wb") as f:
        f.write(image)
```

## 按張計費怎麼判尺寸檔位

計費檔位依模型而定：

- **`nano-banana-pro`、`nano-banana-2`**：檔位就是你送的 `image_size`（`1K`／`2K`／`4K`）。
- **`qwen-image-3.0` 系列**：檔位由 `parameters.size` 決定（1k／2k／4k），`n` 每張都計費。
- **其他按張計費的模型**：依**我們實際交付的圖片**、以其**最長邊**判定檔位：

| 最長邊 | 檔位 |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| 更大 | `4K` |

估算成本前有兩點要知道：

- **模型的預設輸出可能比你以為的寬。** 例如 1408×768 的結果（約 1.1 百萬像素）最長邊是 1408，因此依 `2K` 檔計費——即使它的總像素更接近 1K 圖。
- **部分模型會忽略請求中的 `size`**，一律回傳原生解析度。若檔位會影響你的成本，請讀取回傳圖片的實際尺寸，不要假設請求一定被採用。

只有實際交付的圖片才計費——生成失敗或上傳未完成的不收費。若某模型多個檔位同價（Nano Banana、Nano Banana Pro），檔位就不影響你付的金額。價格見[計價方式](https://atptoken.ai/zh-tw/docs/pricing-model/)。

## 錯誤

4xx 要讀訊息，不要只看狀態碼：模型自己的 4xx 會原樣轉給你，訊息通常已經指名欄位與合法值。回報問題時附上回應的 `x-request-id`。

- 400 — 缺 `model`，或 prompt 與輸入圖都沒有。讀訊息修正。
- 401 — `token_revoked`：金鑰無效，**完全沒送金鑰也會得到這個**。先確認 header 有送出去。
- 402 — 兩種來源：專案餘額耗盡（`insufficient_quota`，不是暫時性限流，**不要重試**，儲值後再送）；或模型自己回的 402，原樣轉回。
- 403 — `permission_denied`：這個模型受控，你的專案不在白名單。不是金鑰也不是餘額問題；換模型或請管理者授權。不收費。
- 404 — 輪詢時：任務不存在或不屬於此專案。
- 409 — 建立時：這把 `Idempotency-Key` 已用在另一個媒體介面的任務上，請換一把。取消時：任務正在 `running`，不能取消。
- 422 — 這個模型沒有可用容量（換模型）；或模型自己回的 `validation_error`，會指名欄位與合法值。
- 429 — 模型限流。回應的 `retryable` 會告訴你能不能重試；可以就退避重試。
- 500 — 模型自己回的 5xx，原樣轉給你。
- 502 — 沒有收到模型的回應（逾時、連線失敗、無法解析）。可重試。
- 503 — 任務無法入列，或 `balance_check_unavailable`（**餘額讀取失敗，不是餘額不足**，請求沒有開始、沒有扣款）。兩種都可重試。

## 下一步

- [/v1/files](https://atptoken.ai/zh-tw/docs/files/) — 上傳給 chat 與 messages 請求使用的檔案。媒體任務無法使用。
- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 影片模型用的是同一套任務流程。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
