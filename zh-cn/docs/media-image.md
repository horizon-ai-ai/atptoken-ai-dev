# 图像生成

> Source: https://atptoken.ai/zh-cn/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

图像生成分**两个步骤**：先创建任务（回 `202` + task id），再轮询到终态、下载签名 URL。把 client 指向媒体 base URL `https://api.atptoken.ai/omni/media/v1`，用项目 `atp-` key 验证。gateway 会把你的 unified `model` 路由到图像 provider（例如 `gpt-image-2`）；名称用 `GET /v1/models` 确认。流程与视频生成一致。

- **输出写入对象存储、以带签名的边缘 URL（`https://media-<env>.atptoken.ai/v/...`）返回，**TTL 30 分钟**——不会内嵌 base64。请尽快取用。**
- 当 project 余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

> **先用同一把 key 确认模型**
>
> 媒体模型依环境与 project 开放。请先调用 `GET https://api.atptoken.ai/v1/models`；未出现在响应中的模型，代表这把 key 目前不能使用。

#### 创建任务

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "quality": "high", "n": 1 }'
# → 202 { "id": "img_..." }
```

| 字段 | 类型 | 说明 |
|---|---|---|
| model | string · 必填 | unified 图像模型（`image` 池） |
| prompt | string · 必填 | 文本提示——**每次图片请求都必填，编辑类模型也一样**（若模型主要由输入图片驱动，仍请带一句简短指示，例如 `"edit this image"`） |
| size | string | 依模型而异；OpenAI 图像常用 `1024x1024` |
| quality | string | 转发给 OpenAI 方言上游（如 `high`／`medium`） |
| n | integer | 张数 1–4（默认 `1`） |
| reference_assets | array | 编辑类模型的输入图，放在**顶层**——`[{ "url": "…" }]`。见下。 |

网络失败重试创建时沿用同一个 `Idempotency-Key`；真正的新任务用新 key。

#### 编辑类模型的输入图——`reference_assets`

> **2026-08-04 对 production 实测**
>
> 编辑类模型（`nano-banana-pro-edit`、`qwen-image-edit-max` …）的输入图要放在**顶层 `reference_assets` 数组、元素是对象**。`content[]`、`image`、`image_url` 三种写法都会被拦 `422 Invalid input.reference_assets: required.`；给一个纯字符串数组也会被拦 `Invalid input.reference_assets`。必须是 `[{ "url": "…" }]`。

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

**`url` 接受哪些形式**（图片端点，2026-08-04 实测）：

| 形式 | 图片端点 | 说明 |
| --- | --- | --- |
| 公开 `https://…` URL | 可用 | 上游必须能**免验证**抓取 |
| `data:image/png;base64,…` | 可用 | 整段内容都塞在 request body，别放太大的档 |
| `asset://<id>`／`asset://<pid>.<id>` | **不支持** | 每次都在生成阶段失败，返回 `provider_error / generation_failed` |

把上传档案换成可用 URL 的最简做法：`POST /v1/files`（响应的 key 是 **`id`**），再对 `GET /v1/files/{id}` **不跟随重导**、取 `Location` header——那是物件储存的 presigned URL，免验证、时效约 15 分钟。见 [/v1/files](https://atptoken.ai/zh-cn/docs/files/)。

编辑调用仍然必填 `prompt`。带一句简短指示就够，但这个字段不能省略。

#### 按张计费如何判定尺寸档位

按张计费的模型，依**我们实际交付的图片**、以其**最长边**判定档位：

| 最长边 | 档位 |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| 更大 | `4K` |

估算成本前有两点要知道：

- **模型的默认输出可能比你以为的宽。** 例如 1408×768 的结果（约 1.1 百万像素）最长边是 1408，因此按 `2K` 档计费——即使其总像素更接近 1K 图。
- **部分模型会忽略请求中的 `size`**，一律返回原生分辨率。若档位会影响你的成本，请读取返回图片的实际尺寸，不要假设请求一定被采用。

只有实际交付的图片才计费——生成失败或上传未完成的不收费。若某模型多个档位同价（Nano Banana、Nano Banana Pro），档位就不影响你付的金额。

#### 轮询至终态

每 3–8 秒轮询一次：

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

- `status` 流转：`queued` → `running` → `succeeded`／`failed`／`cancelled`／`expired`。
- 成功任务的 `data[].url` 是 **30 分钟时效**的签名 URL；过期后任务仍显示 `succeeded` 但 `expired: true`、`url` 为 null——请立即下载（要重拿只能重新生成）。
- `usage` 上报 token 用量供账务核对；`failed` 任务带结构化 `error` 对象。
- **`data[].url` 的扩展名不能当格式依据**（2026-08-04 实测）：结尾写 `.png` 的 URL 实际位元组可能是 JPEG。若格式会影响后续处理（例如把结果再上传、或做转档），请用位元组（magic number）判断，不要相信档名。

| Method | Path | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | 创建 |
| GET | /omni/media/v1/images/generations/tasks/{id} | 轮询 |
| GET | /omni/media/v1/images/generations/tasks | 列表 |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | 取消 |

### Python 示例

最小的创建＋轮询流程：

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

### 错误

- 400 — 缺 `model` 或 `prompt`。
- 402 — `insufficient_quota`：project 余额 ≤ 0；充值后再发（不要重试轰炸）。
- 404 — 任务不存在或不属于此 project（轮询时）。
- 422 — 该模型没有图像 provider。
- 502 — 上游生成失败。
