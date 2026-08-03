# 视频生成

> Source: https://atptoken.ai/zh-cn/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

视频生成是**异步**的：先创建任务（`202` + task id），轮询到终态后再读签名 URL。base URL 与 `atp-` key 同图像。gateway 把 unified `model` 路由到视频 provider，同名可容错切换。可用视频模型：`seedance-2-0`（标准）、`seedance-2-0-mini`（轻量／较省）、`seedance-2-0-fast`（加速），及 Kling 系列（preview）：`kling-v3-standard`/`-pro`、`kling-o3-standard`/`-pro`（含 `-i2v`／`-reference`／`-reference-7`／`-v2v`／`-video-edit` 变体）——均按秒×分辨率计费（Kling 音频生成暂未开放）；以及阿里系列（preview）：`wan-2-7-t2v`、`wan-2-7-i2v`、`happyhorse-1.1-t2v`、`happyhorse-1.1-i2v`、`happyhorse-1.1-r2v`（最多 9 张参考图）与 `happyhorse-1.0-video-edit`（源视频 3–60 秒＋最多 5 张参考图）。HappyHorse 时长 3–15 秒、水印默认开启（可传 `watermark: false` 关闭）；`wan-2-7-*` 目前不论请求分辨率均输出并按 1080P 计费。名称以 `GET /v1/models` 确认。

- **成功的任务带 `content.video_url`——带签名的边缘 URL，**TTL 30 分钟**。逾期后任务仍回 `succeeded` 但 `video_url` 为 `null` 且 `expired: true`（需重建重生）。**
- 当 project 余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

> **先确认模型与 project 权限**
>
> 请使用创建任务时的同一把 key 调用 `GET https://api.atptoken.ai/v1/models`。模型未出现在响应中，就不能由该 project 使用；安装 Skill 或知道模型名称不会绕过 allowed models。

#### 创建任务

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

| 字段 | 类型 | 说明 |
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

**`content[]` 区块** — 每个区块是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。只有文字 → 文生视频；含图片 → 图生视频。`image_url`/`video_url` 带 `{ "url": "<https | base64 | asset://pid.id>" }`；`role` 为 `first_frame` / `last_frame` / `reference_image` / `reference_video`。

#### 轮询至终态

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/task_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| 方法 | 路径 | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | create |
| GET | /omni/media/v1/contents/generations/tasks/{id} | poll |
| GET | /omni/media/v1/contents/generations/tasks | list |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | cancel |

### 阿里视频模型 — 模型指南

`wan-2-7-t2v`／`wan-2-7-i2v` 与 HappyHorse 的文生／图生／参考图模型与其他视频模型共用同一组端点与 `content[]` 形状，以下只列各模型特有之处。**`happyhorse-1.0-video-edit` 是例外：它服务于另一组 DashScope 兼容端点**（见下）。

| 模型 | 输入 | 时长 | 计费分辨率 | 端点 |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | 文本 | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `wan-2-7-i2v` | 文本 + 1 张首帧图 | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `happyhorse-1.1-t2v` | 文本 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.1-i2v` | 文本 + 1 张首帧图 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.1-r2v` | 文本 + 1–9 张参考图 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.0-video-edit` | 1 支源视频（3–60 秒）+ 最多 5 张参考图 | 依源视频长度 | 依请求 720P／1080P | **DashScope** |

> **wan-2-7 不論请求分辨率皆输出 1080P**
>
> `wan-2-7-t2v`／`wan-2-7-i2v` 目前即使请求 `720P` 仍返回 1080P 视频，且计费依实际产出计算——5 秒视频會以 1080P 费率计价。请以 1080P 估算预算；若需要 720P 价位请改用 `happyhorse-1.1-*`。

> **HappyHorse 只支持 720P 与 1080P**
>
> 这些模型支持 `720P` 与 `1080P`。请求 `480P` **不会**被拒绝——会以约 1080P 产出并按 1080P 费率计费。需要 720P 价位请明确送 `720P`。

**文生视频**

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "一匹马奔驰过绿色草原" }],
    "resolution": "720P", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
```

**图生视频** — 加一个 `role: "first_frame"` 的图片区块：

```
"content": [
  { "type": "text", "text": "主体缓缓转向镜头" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

**参考图生视频**（`happyhorse-1.1-r2v`）— 1 至 9 张参考图，每张带 `role: "reference_image"`，在 prompt 中以 `[Image 1]`、`[Image 2]` 指代：

```
"content": [
  { "type": "text", "text": "[Image 1] 走进 [Image 2] 的房间" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

**视频编辑**（`happyhorse-1.0-video-edit`）— **请使用 DashScope 兼容端点，不是统一端点。** 统一端点会以 `400 video-edit requires a source video` 拒绝此模型。改以 `input.media[]` 建立任务，并轮询 `GET /omni/media/v1/tasks/{id}`：

```
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "happyhorse-1.0-video-edit",
    "input": {
      "prompt": "把背景换成下雪的街道",
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

`input.media[].type` 只接受 `video` 與 `reference_image`，网址字段名为 `url`（不是 `video_url`）。源视频与每一张参考图都必須是公网免鉴权可直接下载的文件；任一个抓不到时任务会以 `FAILED`＋`Failed to download …` 结束且不计费。此端点返回 DashScope 形状（`output.task_status`、`output.video_url`），且目前输出长度依源视频长度，而非 `parameters.duration`。

**计费** — 按输出秒数 × 分辨率计费，以 video tokens 计量（`宽 × 高 × 秒数 × 24 fps ÷ 1024`）。`-r2v` 与 `-video-edit` 的**输入视频秒数一并计费**，例如以 5 秒源视频产出 5 秒成品，计 10 秒。任务失败不计费。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

**其他模型特性**

- **水印**：HappyHorse 水印**默认开启**——需传 `watermark: false` 关闭；Wan 2.7 預設关闭。
- **画面比例**：HappyHorse 在共用清单之外另支持 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 長度**：5,000 字符（HappyHorse 中文 2,500 字）。
- 这些模型目前不支持 `generate_audio`。

### 错误

- 400 — invalid request body.
- 402 — `insufficient_quota`：project balance ≤ 0（仅阻挡 create；poll / list / cancel 仍可用）。
- 403 — `permission_denied`：gated model 尚未对此 project 开放。
- 422 — the model has no video provider.
- 502 — upstream generation failed.
