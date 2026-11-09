# 图像生成

> Source: https://atptoken.ai/zh-cn/docs/media-image/

`POST /omni/media/v1/images/generations/tasks`

图像生成是**非同步**的，没有同步版本。流程是三步：建立任务（回 `202` + `img_…` 任务 id）→ 轮询到终态 → 在 24 小时内下载 `data[].url`。把 client 指向媒体 base URL `https://api.atptoken.ai/omni/media/v1`，用项目（project）的 `atp-` 密钥验证。流程与影片生成一致。

- **输出是签章 URL（`https://media-<env>.atptoken.ai/v/...`），效期 24 小时**，不会内嵌 base64。要留存就下载，不要把 URL 当永久连结存起来。
- 项目余额 ≤ 0 时，请求会以 `402 insufficient_quota` 拒绝。
- `callback_url` 会被接受，但**不会有 webhook**。一定要轮询。

> **先确认这把密钥能用哪些模型**
>
> 完整清单是 `GET https://api.atptoken.ai/v1/project/models`：列出这个项目放行的所有模型，不分文字、图像、影片、语音。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，**图像模型不在里面**。清单上没有不代表不能用；没有授权的模型会在建立任务时回 `403`，不收费。

## 建立任务

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: img-job-001" \
  -d '{ "model": "nano-banana-pro", "prompt": "an isometric paper-craft city at golden hour", "aspect_ratio": "16:9", "image_size": "2K" }'
# → 202 { "id": "img_..." }
```

回 `202` 时**图还没生出来**，拿到的是任务 id。不确定用哪个模型，就先用 `nano-banana-pro`。

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | 图像模型名称，例如 `nano-banana-pro`、`qwen-image-3.0`、`gpt-image-2` |
| prompt | string | 文字提示。大多数模型必填。只靠影像输入的模型（例如带 `face_image` 的 `face-swap`）可以不带。prompt 和输入图都没有时回 `400` |
| 其他栏位 | 依模型而定 | 除了 `model`，其余栏位都**原名原值转发**给模型。各模型的栏位见下一节 |

> **填错的栏位不会报错，只会被忽略**
>
> 模型不认得的栏位会被**安静忽略**：请求照样回 `202`、照样生出一张图，只是不是你要的那张。最常见的三个：
>
> - `size: "1024x1024"` 送给 `nano-banana*`：被忽略。要用 `image_size` + `aspect_ratio`。
> - `size` 放在顶层送给 `qwen-image-3.0`：被忽略。它只读 `parameters.size`。
> - `n: 4` 送给 `nano-banana*`：被忽略。要用 `num_images`。
>
> 要确认参数有没有生效，请比对输出，不要只看状态码。反过来，模型**认得但不接受**的值会回 4xx，消息会指名栏位与合法值，照著改就好。

**幂等键：** 网络失败重试建立时，沿用同一个 `Idempotency-Key`；真正的新任务用新的键。图像、影片、语音各用各的键：同一把键先用在影片、再用在图像，会回 `409`。

## 各模型的参数

### nano-banana 系列

适用 `nano-banana`、`nano-banana-2`、`nano-banana-pro`，以及改图用的 `nano-banana-edit`、`nano-banana-2-edit`、`nano-banana-pro-edit`。

| 栏位 | 型别 | 说明 |
|---|---|---|
| prompt | string · 必填 | 文字提示，`-edit` 系列也要带 |
| aspect_ratio | string | `auto` `21:9` `16:9` `3:2` `4:3` `5:4` `1:1` `4:5` `3:4` `2:3` `9:16` `4:1` `1:4` `8:1` `1:8` |
| image_size | string | `1K` / `2K` / `4K`。**只有 `-pro` 与 `-2` 支持**，也是计费档位 |
| num_images | integer | 1–4。**只有 `-pro` 与 `-2` 支持** |
| output_format | string | `jpeg` / `png` / `webp` |
| seed | number | `-1` 为随机 |
| safety_tolerance | string | `1`–`6`，默认 `6` |
| enable_web_search | boolean | **只有 `-pro` 与 `-2` 支持** |
| thinking_level | string | `minimal` / `high`。**只有 `-2` 支持** |
| reference_assets | array | 输入图，`[{ "asset_type": "image", "url": "…" }]`，`nano-banana-2` 系列最多 14 张，`nano-banana`、`nano-banana-pro` 系列最多 10 张。**`-edit` 系列必填**，见下方「改图」一节 |

这个系列不读 `size`、`quality`、`n`。

### qwen-image-3.0 / qwen-image-3.0-pro

这两个是**唯一参数不放顶层**的模型：只读巢状的 `parameters` 物件，顶层的同名栏位会被安静忽略。`{"size": "1024*1024"}` 没有作用，要写成 `{"parameters": {"size": "1024*1024"}}`。

| 栏位（放在 `parameters` 内） | 型别 | 说明 |
|---|---|---|
| size | string | **星号**格式 `宽*高`，例如 `1024*1024`，不是 `1024x1024`。面积要在 512×512 到 2560×2560 之间，超出会失败并指名实际面积。也决定计费档位（1k/2k/4k）。不填默认 2048×2048 |
| n | integer | 张数，**每张都计费** |
| prompt_extend | boolean | **默认 `true`**：模型会自动改写你的 prompt（回应的 `rewrite_status` 会是 `success`）。要照原文送，明确给 `false` |
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

这两个读 OpenAI Images 的栏位：

| 栏位 | 型别 | 说明 |
|---|---|---|
| prompt | string · 必填 | 文字提示 |
| size | string | **叉号**格式，例如 `1024x1024` |
| quality | string | 画质 |
| n | integer | 张数，默认 `1` |
| images | array | **只有 `gpt-image-2-edit`，必填**：输入图 1–4 张，形状 `[{ "image_url": "…" }]`，可放公开 https 网址或 data URI |
| output_format | string | `png`（默认）、`jpeg`、`webp` |

### face-swap

这个模型**不吃文字**，参数只有三个：

| 栏位 | 型别 | 说明 |
|---|---|---|
| image | string | 要被换脸的底图 |
| face_image | string · 必填 | 要换上去的脸。有它就不需要 `prompt` |
| seed | number | 随机种子 |

只送 `image`、没有 `face_image` 时，不会免除 `prompt`，会得到「prompt is required」。

### 其他图像模型

`qwen-image-edit-spicy`、`wan-2-7-image`、`wan-2-7-pro-image`、`z-image-spicy` 没有可查的参数表。做法是：先送 `model` + `prompt`（加上你的输入图），再读回应。模型认得但不接受的栏位会回 4xx 并指名栏位与合法值；请求成功不代表栏位生效，要比对输出。

## 改图：输入图放哪里

同一个端点、同一个流程，但**不同模型放输入图的位置完全不同**：

| 模型 | 输入图放哪里 | 形状 |
| --- | --- | --- |
| `nano-banana-edit`、`nano-banana-2-edit`、`nano-banana-pro-edit` | 顶层 `reference_assets` | `[{ "asset_type": "image", "url": "…" }]`，`nano-banana-2-edit` 最多 14 张、另两个最多 10 张，必填 |
| `qwen-image-3.0`、`qwen-image-3.0-pro` | `messages` 里的 content block | `{ "type": "image", "image": "<data URI 或 URL>" }`，**不是** `image_url` |
| `gpt-image-2-edit` | 顶层 `images` | `[{ "image_url": "…" }]`，1–4 张，必填。**不要用 `reference_assets`**：建立会成功，但轮询时才失败 |
| `face-swap` | `image` 与 `face_image` | 见上一节 |

### nano-banana 的 `-edit` 系列

> **输入图要放在顶层 `reference_assets`**
>
> 输入图要放在**顶层 `reference_assets` 阵列、元素是物件**：`[{ "asset_type": "image", "url": "…" }]`。
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
    "reference_assets": [
      { "asset_type": "image", "url": "https://example.com/product.png" }
    ],
    "aspect_ratio": "16:9",
    "image_size": "2K",
    "output_format": "png"
  }'
# → 202 { "id": "img_..." }
```

这个系列改图时仍然必填 `prompt`。带一句简短指示就够。

**`url` 接受哪些形式**（图片端点）：

| 形式 | 图片端点 | 说明 |
| --- | --- | --- |
| 公开 `https://…` URL | 可用 | 上游必须能**免验证**抓取 |
| `data:image/png;base64,…` | 可用 | 整段内容都塞在 request body，base64 请控制在 2 MB 以内，过大可能在上游失败 |
| `asset://<id>`／`asset://<pid>.<id>` | **不支持** | 每次都在生成阶段失败，回 `provider_error / generation_failed` |

`/v1/files` 上传的文件不能用在这里：它回的 `an_<ulid>` 是 chat 用的文件 id，不是媒体引用，`GET /v1/files/{id}` 回传的也是文件内容，不是 URL。要用本机图片，请放到公开 `https://` URL，或把小图片编码成 `data:` URI 传入。见 [/v1/files](https://atptoken.ai/zh-cn/docs/files/)。

### qwen-image 改图

qwen-image 改图走 `messages`，参数照样放在 `parameters`：

```
{"model": "qwen-image-3.0",
 "parameters": {"size": "1024*1024", "n": 1, "prompt_extend": false},
 "messages": [{"role": "user", "content": [
   {"type": "image", "image": "data:image/png;base64,…"},
   {"type": "text",  "text": "make the square blue"}]}]}
```

- 输入图的 block 是 `{"type": "image", "image": …}`，这两个模型不收 `image_url` 的形状。
- 送了 `messages` 就以你的为准。若同时送 `prompt`，`prompt` 会接在最后成为另一则 user 消息，两者都不会被丢掉。

## 轮询至终态

每 3–8 秒轮询一次。任务一建立就查得到：

```
curl https://api.atptoken.ai/omni/media/v1/images/generations/tasks/img_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "data": [ { "url": "https://media-prod.atptoken.ai/v/image/...png?exp=...&sig=..." } ], "usage": { "prompt_tokens": 37, "completion_tokens": 7024, "total_tokens": 7061 } }
```

状态只有六个，其中四个是终态：

| 状态 | 终态 | 意思 |
| --- | --- | --- |
| `queued` | 否 | 已入列，继续轮询 |
| `running` | 否 | 正在生成，继续轮询 |
| `succeeded` | 是 | 有结果，在 `data[].url` |
| `failed` | 是 | 失败，原因在 `error` |
| `expired` | 是 | 结果已经不在了 |
| `cancelled` | 是 | 被取消 |

- **四个终态都要跳出回圈。** 只等 `succeeded` 的回圈遇到 `failed` 会永远转下去。
- **`succeeded` 不保证拿得到文件。** 超过 24 小时后，状态仍是 `succeeded`，但 `data[].url` 变成 `null`，另外多一个 `expired: true`。判完 `succeeded` 还要检查 URL 是不是 `null`。要重拿只能重新生成。
- `data` 是阵列，一次生多张时每张一个 URL，要全部就走完整个阵列。
- `usage` 回报 token 用量；`meters` 说明这次任务实际依什么计量（按张计价的模型没有 token，看 `meters`）。
- `failed` 任务带 `error` 物件（`code`、`message`；若失败带有 HTTP 状态码，另有 `upstream_status`）。
- **参数值的错误可能在轮询时才出现。** `nano-banana` 系列、`gpt-image-2`、`qwen-image` 系列在建立时只检查请求形状，参数值不合法会在轮询时变成 `failed`，例如 qwen-image 尺寸超界会是 `{"code":"upstream_400","upstream_status":400,"message":"Image area must be between …"}`。`kling-*` 系列则在建立当下就回错误，状态码原样转给你。
- **`data[].url` 的副档名不能当格式依据**：结尾写 `.png` 的 URL 实际字节可能是 JPEG。若格式会影响后续处理（例如把结果再上传、或做转档），请用字节（magic number）判断，不要相信档名。

| Method | Path | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/images/generations/tasks | 建立 |
| GET | /omni/media/v1/images/generations/tasks/{id} | 轮询；查不到或不属于你的项目回 `404` |
| GET | /omni/media/v1/images/generations/tasks | 列出这个项目的任务 |
| DELETE | /omni/media/v1/images/generations/tasks/{id} | `queued` 会取消；已终态会删除记录；`running` 回 `409`，不能取消 |

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

if task["status"] != "succeeded":
    raise RuntimeError(task.get("error"))

for i, item in enumerate(task["data"]):
    if item.get("url") is None:  # signed URL expired after 24h (expired: true)
        raise RuntimeError("result expired; generate again")
    image = requests.get(item["url"], timeout=120).content  # signed URL, 24h TTL
    with open(f"result_{i}.png", "wb") as f:
        f.write(image)
```

## 按张计费怎么判尺寸档位

计费档位依模型而定：

- **`nano-banana-pro`、`nano-banana-2`**：档位就是你送的 `image_size`（`1K`／`2K`／`4K`）。
- **`qwen-image-3.0` 系列**：档位由 `parameters.size` 决定（1k／2k／4k），`n` 每张都计费。
- **其他按张计费的模型**：依**我们实际交付的图片**、以其**最长边**判定档位：

| 最长边 | 档位 |
| --- | --- |
| ≤ 1024 px | `1K` |
| ≤ 2048 px | `2K` |
| 更大 | `4K` |

估算成本前有两点要知道：

- **模型的默认输出可能比你以为的宽。** 例如 1408×768 的结果（约 1.1 百万像素）最长边是 1408，因此依 `2K` 档计费——即使它的总像素更接近 1K 图。
- **部分模型会忽略请求中的 `size`**，一律回传原生解析度。若档位会影响你的成本，请读取回传图片的实际尺寸，不要假设请求一定被采用。

只有实际交付的图片才计费——生成失败或上传未完成的不收费。若某模型多个档位同价（Nano Banana、Nano Banana Pro），档位就不影响你付的金额。价格见[计价方式](https://atptoken.ai/zh-cn/docs/pricing-model/)。

## 错误

4xx 要读消息，不要只看状态码：模型自己的 4xx 会原样转给你，消息通常已经指名栏位与合法值。回报问题时附上回应的 `x-request-id`。

- 400 — 缺 `model`，或 prompt 与输入图都没有。读消息修正。
- 401 — `token_revoked`：密钥无效，**完全没送密钥也会得到这个**。先确认 header 有送出去。
- 402 — 两种来源：项目余额耗尽（`insufficient_quota`，不是暂时性限流，**不要重试**，充值后再送）；或模型自己回的 402，原样转回。
- 403 — `permission_denied`：这个模型受控，你的项目不在白名单。不是密钥也不是余额问题；换模型或请管理者授权。不收费。
- 404 — 轮询时：任务不存在或不属于此项目。
- 409 — 建立时：这把 `Idempotency-Key` 已用在另一个媒体介面的任务上，请换一把。取消时：任务正在 `running`，不能取消。
- 422 — 这个模型没有可用容量（换模型）；或模型自己回的 `validation_error`，会指名栏位与合法值。
- 429 — 模型限流。回应的 `retryable` 会告诉你能不能重试；可以就退避重试。
- 500 — 模型自己回的 5xx，原样转给你。
- 502 — 没有收到模型的回应（逾时、连线失败、无法解析）。可重试。
- 503 — 任务无法入列，或 `balance_check_unavailable`（**余额读取失败，不是余额不足**，请求没有开始、没有扣款）。两种都可重试。

## 下一步

- [/v1/files](https://atptoken.ai/zh-cn/docs/files/) — 上传给 chat 与 messages 请求使用的文件。媒体任务无法使用。
- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 影片模型用的是同一套任务流程。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
