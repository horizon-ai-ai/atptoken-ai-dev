# 图像生成

> Source: https://atptoken.ai/zh-cn/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

图像生成分**两个步骤**：先建立任务（回 `202` + task id），再轮询到终态、下载签章 URL。把 client 指向媒体 base URL `https://api.atptoken.ai/omni/media/v1`，用项目（project） `atp-` 密钥验证。Gateway 会把你的 unified `model` 路由到图像供应商（例如 `gpt-image-2`）；名称用 `GET /v1/models` 确认。流程与影片生成一致。

- **输出写入物件储存、以带签章的边缘 URL（`https://media-<env>.atptoken.ai/v/...`）回传，**TTL 30 分钟**——不会内嵌 base64。请尽快取用。**
- 当项目余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

> **先用同一把密钥确认模型**
>
> 媒体模型依环境与项目开放。请先呼叫 `GET https://api.atptoken.ai/v1/models`；未出现在回应中的模型，代表这把密钥不能使用。

## 建立任务

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "gpt-image-2", "prompt": "a watercolor cat", "size": "1024x1024", "quality": "high", "n": 1 }'
# → 202 { "id": "img_..." }
```

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | unified 图像模型（`image` 池） |
| prompt | string · 必填 | 文字提示——**每次图片请求都必填，编辑类模型也一样**（若模型主要由输入图片驱动，仍请带一句简短指示，例如 `"edit this image"`） |
| size | string | 依模型而异；OpenAI 图像常用 `1024x1024` |
| quality | string | 转发给 OpenAI 方言上游（如 `high`／`medium`） |
| n | integer | 张数 1–4（默认 `1`） |
| reference_assets | array | 编辑类模型的输入图，放在**顶层**——`[{ "url": "…" }]`。见下。 |

网络失败重试建立时沿用同一个 `Idempotency-Key`；真正的新任务用新的幂等键。

### 编辑类模型的输入图——`reference_assets`

> **编辑类模型的输入图要放在 `reference_assets`**
>
> 编辑类模型（`nano-banana-pro-edit`、`qwen-image-edit-max` …）的输入图要放在**顶层 `reference_assets` 阵列、元素是物件**。必须是 `[{ "url": "…" }]`。
>
> - `content[]`、`image`、`image_url` 三种写法都会被挡 `422 Invalid input.reference_assets: required.`
> - 给一个纯字串阵列也会被挡 `Invalid input.reference_assets`。

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

**`url` 接受哪些形式**（图片端点）：

| 形式 | 图片端点 | 说明 |
| --- | --- | --- |
| 公开 `https://…` URL | 可用 | 上游必须能**免验证**抓取 |
| `data:image/png;base64,…` | 可用 | 整段内容都塞在 request body，别放太大的档 |
| `asset://<id>`／`asset://<pid>.<id>` | **不支持** | 每次都在生成阶段失败，回 `provider_error / generation_failed` |

把上传文件换成可用 URL 的最简做法：`POST /v1/files`（回应的密钥是 **`id`**），再对 `GET /v1/files/{id}` **不跟随重导**、取 `Location` header——那是物件储存的 presigned URL，免验证、时效约 15 分钟。见 [/v1/files](https://atptoken.ai/zh-cn/docs/files/)。

编辑呼叫仍然必填 `prompt`。带一句简短指示就够，但这个栏位不能省略。

## 轮询至终态

每 3–8 秒轮询一次：

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

- `status` 流转：`queued` → `running` → `succeeded`／`failed`／`cancelled`／`expired`。
- 成功任务的 `data[].url` 是 **30 分钟时效**的签章 URL；过期后任务仍显示 `succeeded` 但 `expired: true`、`url` 为 null——请立即下载（要重拿只能重新生成）。
- `usage` 回报 token 用量供帐务核对；`failed` 任务带结构化 `error` 物件。
- **`data[].url` 的副档名不能当格式依据**：结尾写 `.png` 的 URL 实际字节可能是 JPEG。若格式会影响后续处理（例如把结果再上传、或做转档），请用字节（magic number）判断，不要相信档名。

| Method | Path | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | 建立 |
| GET | /omni/media/v1/images/generations/tasks/{id} | 轮询 |
| GET | /omni/media/v1/images/generations/tasks | 列表 |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | 取消 |

## Python 范例

最小的建立＋轮询流程：

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

## 按张计费怎么判尺寸档位

按张计费的模型，是依**我们实际交付的图片**、以其**最长边**判定档位：

| 最长边 | 档位 |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| 更大 | `4K` |

估算成本前有两点要知道：

- **模型的默认输出可能比你以为的宽。** 例如 1408×768 的结果（约 1.1 百万像素）最长边是 1408，因此依 `2K` 档计费——即使它的总像素更接近 1K 图。
- **部分模型会忽略请求中的 `size`**，一律回传原生解析度。若档位会影响你的成本，请读取回传图片的实际尺寸，不要假设请求一定被采用。

只有实际交付的图片才计费——生成失败或上传未完成的不收费。若某模型多个档位同价（Nano Banana、Nano Banana Pro），档位就不影响你付的金额。

## 错误

- 400 — 缺 `model` 或 `prompt`。
- 402 — `insufficient_quota`：项目余额 ≤ 0；充值后再送（不要重试轰炸）。
- 404 — 任务不存在或不属于此项目（轮询时）。
- 422 — 该模型没有图像供应商。
- 502 — 上游生成失败。

## 下一步

- [/v1/files](https://atptoken.ai/zh-cn/docs/files/) — 上传输入图并换成可引用的 URL。
- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 影片模型用的是同一套任务流程。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
