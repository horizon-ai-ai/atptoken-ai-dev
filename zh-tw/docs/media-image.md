# 圖像生成

> Source: https://atptoken.ai/zh-tw/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

圖像生成分**兩個步驟**：先建立任務（回 `202` + task id），再輪詢到終態、下載簽章 URL。把 client 指向媒體 base URL `https://api.atptoken.ai/omni/media/v1`，用專案 `atp-` key 驗證。gateway 會把你的 unified `model` 路由到圖像 provider（例如 `gpt-image-2`）；名稱用 `GET /v1/models` 確認。流程與影片生成一致。

- **輸出寫入物件儲存、以帶簽章的邊緣 URL（`https://media-<env>.atptoken.ai/v/...`）回傳，**TTL 30 分鐘**——不會內嵌 base64。請盡快取用。**
- 當 project 餘額 ≤ 0，請求會以 `402 insufficient_quota` 拒絕。

> **先用同一把 key 確認模型**
>
> 媒體模型依環境與 project 開放。請先呼叫 `GET https://api.atptoken.ai/v1/models`；未出現在回應中的模型，代表這把 key 目前不能使用。

#### 建立任務

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "quality": "high", "n": 1 }'
# → 202 { "id": "img_..." }
```

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | unified 圖像模型（`image` 池） |
| prompt | string · 必填 | 文字提示——**每次圖片請求都必填，編輯類模型也一樣**（若模型主要由輸入圖片驅動，仍請帶一句簡短指示，例如 `"edit this image"`） |
| size | string | 依模型而異；OpenAI 圖像常用 `1024x1024` |
| quality | string | 轉發給 OpenAI 方言上游（如 `high`／`medium`） |
| n | integer | 張數 1–4（預設 `1`） |
| reference_assets | array | 編輯類模型的輸入圖，放在**頂層**——`[{ "url": "…" }]`。見下。 |

網路失敗重試建立時沿用同一個 `Idempotency-Key`；真正的新任務用新 key。

#### 編輯類模型的輸入圖——`reference_assets`

> **2026-08-04 對 production 實測**
>
> 編輯類模型（`nano-banana-pro-edit`、`qwen-image-edit-max` …）的輸入圖要放在**頂層 `reference_assets` 陣列、元素是物件**。`content[]`、`image`、`image_url` 三種寫法都會被擋 `422 Invalid input.reference_assets: required.`；給一個純字串陣列也會被擋 `Invalid input.reference_assets`。必須是 `[{ "url": "…" }]`。

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-edit-001" \
  -d '{
    "model": "nano-banana-pro-edit",
    "prompt": "Background: a sunlit marble kitchen counter. Preserve the product exactly — same shape, label text, colors and proportions as the reference.",
    "n": 1,
    "reference_assets": [
      { "url": "https://example.com/product.png" }
    ]
  }'
# → 202 { "id": "img_..." }
```

**`url` 接受哪些形式**（圖片端點，2026-08-04 實測）：

| 形式 | 圖片端點 | 說明 |
| --- | --- | --- |
| 公開 `https://…` URL | 可用 | 上游必須能**免驗證**抓取 |
| `data:image/png;base64,…` | 可用 | 整段內容都塞在 request body，別放太大的檔 |
| `asset://<id>`／`asset://<pid>.<id>` | **不支援** | 每次都在生成階段失敗，回 `provider_error / generation_failed` |

把上傳檔案換成可用 URL 的最簡做法：`POST /v1/files`（回應的 key 是 **`id`**），再對 `GET /v1/files/{id}` **不跟隨重導**、取 `Location` header——那是物件儲存的 presigned URL，免驗證、時效約 15 分鐘。見 [/v1/files](https://atptoken.ai/zh-tw/docs/files/)。

編輯呼叫仍然必填 `prompt`。帶一句簡短指示就夠，但這個欄位不能省略。

#### 按張計費怎麼判尺寸檔位

按張計費的模型，是依**我們實際交付的圖片**、以其**最長邊**判定檔位：

| 最長邊 | 檔位 |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| 更大 | `4K` |

估算成本前有兩點要知道：

- **模型的預設輸出可能比你以為的寬。** 例如 1408×768 的結果（約 1.1 百萬像素）最長邊是 1408，因此依 `2K` 檔計費——即使它的總像素更接近 1K 圖。
- **部分模型會忽略請求中的 `size`**，一律回傳原生解析度。若檔位會影響你的成本，請讀取回傳圖片的實際尺寸，不要假設請求一定被採用。

只有實際交付的圖片才計費——生成失敗或上傳未完成的不收費。若某模型多個檔位同價（Nano Banana、Nano Banana Pro），檔位就不影響你付的金額。

#### 輪詢至終態

每 3–8 秒輪詢一次：

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

- `status` 流轉：`queued` → `running` → `succeeded`／`failed`／`cancelled`／`expired`。
- 成功任務的 `data[].url` 是 **30 分鐘時效**的簽章 URL；過期後任務仍顯示 `succeeded` 但 `expired: true`、`url` 為 null——請立即下載（要重拿只能重新生成）。
- `usage` 回報 token 用量供帳務核對；`failed` 任務帶結構化 `error` 物件。
- **`data[].url` 的副檔名不能當格式依據**（2026-08-04 實測）：結尾寫 `.png` 的 URL 實際位元組可能是 JPEG。若格式會影響後續處理（例如把結果再上傳、或做轉檔），請用位元組（magic number）判斷，不要相信檔名。

| Method | Path | 動作 |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | 建立 |
| GET | /omni/media/v1/images/generations/tasks/{id} | 輪詢 |
| GET | /omni/media/v1/images/generations/tasks | 列表 |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | 取消 |

### Python 範例

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

if task["status"] == "succeeded":
    for i, item in enumerate(task["data"]):
        image = requests.get(item["url"], timeout=120).content  # signed URL, 30-min TTL
        with open(f"result_{i}.png", "wb") as f:
            f.write(image)
else:
    raise RuntimeError(task.get("error"))
```

### 錯誤

- 400 — 缺 `model` 或 `prompt`。
- 402 — `insufficient_quota`：project 餘額 ≤ 0；儲值後再送（不要重試轟炸）。
- 404 — 任務不存在或不屬於此 project（輪詢時）。
- 422 — 該模型沒有圖像 provider。
- 502 — 上游生成失敗。
