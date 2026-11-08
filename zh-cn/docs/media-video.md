# 影片生成

> Source: https://atptoken.ai/zh-cn/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

影片生成是**非同步**的：先建立任务（`202` + task id），轮询到终态后再读签章 URL。base URL 与 `atp-` 密钥同图像。Gateway 把 unified `model` 路由到影片供应商，同名可容错切换。

**每一个影片任务**

1. 建立任务 — `POST …/contents/generations/tasks` — 回 `202` + task id；余额 ≤ 0 时回 `402`
2. 轮询到终态 — `GET …/contents/generations/tasks/{id}`
3. 下载 `content.video_url` — 签章 URL — TTL 30 分钟
   - succeeded
   - failed
   - 30 分钟后 `expired: true` · 需重建重生

- **成功的任务带 `content.video_url`——带签章的边缘 URL，**TTL 30 分钟**。逾期后任务仍回 `succeeded` 但 `video_url` 为 `null` 且 `expired: true`（需重建重生）。**
- 当项目（project）余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

## 可用的影片模型

名称以 `GET /v1/models` 确认。

| 系列 | 模型 | 说明 |
| --- | --- | --- |
| Seedance | `seedance-2-0` | 标准 |
| Seedance | `seedance-2-0-mini` | 轻量／较省 |
| Seedance | `seedance-2-0-fast` | 加速 |
| Kling（preview） | `kling-v3-standard`、`kling-v3-pro`、`kling-o3-standard`、`kling-o3-pro` | 按秒×解析度计费；Kling 音讯生成暂未开放 |
| Kling（preview） | `-i2v`、`-reference`、`-reference-7`、`-v2v`、`-video-edit` | 上列 Kling 模型的变体 |
| 阿里（preview） | `wan-2-7-t2v`、`wan-2-7-i2v` | 不论请求解析度皆输出并依 1080P 计费 |
| 阿里（preview） | `happyhorse-1.1-t2v`、`happyhorse-1.1-i2v` | 3–15 秒；浮水印默认开启（可传 `watermark: false` 关闭） |
| 阿里（preview） | `happyhorse-1.1-r2v` | 最多 9 张参考图；3–15 秒；浮水印默认开启 |
| 阿里（preview） | `happyhorse-1.0-video-edit` | 来源影片 3–60 秒＋最多 5 张参考图；浮水印默认开启 |
| 阿里（preview） | `wan-3-0-video`、`wan-3-0-video-pro` | 扁平请求，不用 `content[]`，见下方 Wan 3.0 |

> **先确认模型与项目权限**
>
> 请使用建立任务时的同一把密钥呼叫 `GET https://api.atptoken.ai/v1/models`。模型未出现在回应中，就不能由该项目使用；安装 Skill 或知道模型名称不会绕过 allowed models。

## 建立任务

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

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | 统一影片模型 ID（`video` 供应商池） |
| content | array · 必填 | 多模态输入区块（见下方） |
| resolution | string | `480p` / `720p` / `1080p` / `4k` |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive` （别名 `aspect_ratio`） |
| duration | integer | 秒数（与 `frames` 择一） |
| frames | integer | 影格数（`duration` 的替代） |
| generate_audio | boolean | 加上配乐（别名 `add_audio`） |
| seed | integer | |
| watermark | boolean | |

**`content[]` 区块**——每个区块是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。

- 只有文字 → 文生影片；含图片 → 图生影片。
- `image_url`/`video_url` 带 `{ "url": "…" }`。
- `role` 为 `first_frame` / `last_frame` / `reference_image` / `reference_video`。

### `url` 接受哪些形式

> **影片端点接受公开 https URL、base64 或素材 URI**
>
> **影片端点接受公开 `https://` URL 和 base64 `data:` URI；Seedance 另外接受素材 API 产生的 `asset://` URI。**
>
> | 形式 | 影片端点 | 图片端点 |
> | --- | --- | --- |
> | 公开 `https://…` URL | 可用 | 可用 |
> | `data:image/…;base64,…` | 可用，请控制在 2 MB 内 | 可用 |
> | 素材 API 回传的 `asset://…`（`AssetUri`） | 可用（Seedance） | **不支持** |
>
> 图片端点收到 `asset://` 引用时，会在生成阶段回 `provider_error / generation_failed`。
>
> Wan 3.0 用 base64 送首帧或参考图时，影片生成后任务状态可能一直停在 `running`，所以 Wan 3.0 请改用公开 `https://` URL。

### 使用本机文件

本机文件有两种送法：

- **转成 base64：** 把文件编码成 `data:` URI 直接放进 `url`，请控制在 2 MB 内。
- **放到公开网址：** 把文件放到供应商免验证就能抓取的公开 `https://` URL，再传入那个 URL。

```
{
  "type": "image_url",
  "image_url": { "url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." },
  "role": "first_frame"
}
```

`/v1/files` 上传的文件不能当 `url`：它的 `id` 不是媒体引用，`GET /v1/files/{id}` 回传的是文件内容，不是 URL。

在 Seedance 上，也可以把公开 URL 登记成素材，改传 `asset://` URI，做法见下一节。

### 引用登记的素材

Seedance 也接受通过素材 API 登记的图片。登记图片、等到状态为 `Completed`，再把回传的 `AssetUri`（`asset://…`，请原样使用）当图片区块的 `url`：

**把图片登记成素材**

1. 建立素材群组 — `POST /omni/media/v1/asset-groups`
2. 登记图片 — `POST /omni/media/v1/assets`
3. 轮询到 `Completed` — `POST /omni/media/v1/assets/get` — 回传 `AssetUri`
4. 建立影片任务 — `POST …/contents/generations/tasks` — URI 放在 `content[].image_url.url`

```
{ "type": "image_url", "image_url": { "url": "asset://…" }, "role": "reference_image" }
```

URI 只放在 `image_url.url`，区块没有顶层 `url`。`/v1/files` 的 id 不是素材 URI。

真人照片的公开 URL 可能被拒，回 `400 may contain real person`。请把图片登记成素材，改传 `AssetUri`。`seedance-2-0-fast` 只接受直接网址，所以不要用它处理真人照片。

## 轮询至终态

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

## 阿里影片模型

`wan-2-7-t2v`／`wan-2-7-i2v` 与 HappyHorse 的文生／图生／参考图模型与其他影片模型共用同一组端点与 `content[]` 形状，以下只列各模型特有之处。**`happyhorse-1.0-video-edit` 是例外：它服务于另一组 DashScope 相容端点**（见下）。

| 模型 | 输入 | 时长 | 计费解析度 | 端点 |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | 文字 | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `wan-2-7-i2v` | 文字 + 1 张首帧图 | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `happyhorse-1.1-t2v` | 文字 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.1-i2v` | 文字 + 1 张首帧图 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.1-r2v` | 文字 + 1–9 张参考图 | 3–15 秒 | 依请求 720P／1080P | 统一 |
| `happyhorse-1.0-video-edit` | 1 支来源影片（3–60 秒）+ 最多 5 张参考图 | 依来源影片长度 | 依请求 720P／1080P | **DashScope** |

> **wan-2-7 不论请求解析度皆输出 1080P**
>
> `wan-2-7-t2v`／`wan-2-7-i2v` 即使请求 `720P` 仍回传 1080P 影片，且计费依实际产出计算——5 秒影片会以 1080P 费率计价。请以 1080P 估算预算；若需要 720P 价位请改用 `happyhorse-1.1-*`。

> **HappyHorse 只支持 720P 与 1080P**
>
> 这些模型支持 `720P` 与 `1080P`。请求 `480P` **不会**被拒绝——会以约 1080P 产出并按 1080P 费率计费。需要 720P 价位请明确送 `720P`。

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

### 图生影片

加一个 `role: "first_frame"` 的图片区块：

```
"content": [
  { "type": "text", "text": "the subject turns slowly toward the camera" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

### 参考图生影片

`happyhorse-1.1-r2v` 接受 1 至 9 张参考图，每张带 `role: "reference_image"`，在 prompt 中以 `[Image 1]`、`[Image 2]` 指代：

```
"content": [
  { "type": "text", "text": "[Image 1] walks into the room shown in [Image 2]" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

> **多图合成请先小量验证**
>
> `kling-o3-pro-reference` 带多张 `reference_image`、在 prompt 写「把 [Image 1] 放进 [Image 2] 的场景」时，跨图合成指示不一定会执行，任务仍会出片并计费。批量生成前，先跑一支短的低解析度影片确认。

### 影片编辑

`happyhorse-1.0-video-edit` **请使用 DashScope 相容端点，不是统一端点。** 统一端点会以 `400 video-edit requires a source video` 拒绝此模型。改以 `input.media[]` 建立任务，并轮询 `GET /omni/media/v1/tasks/{id}`：

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

- `input.media[].type` 只接受 `video` 与 `reference_image`，网址栏位名为 `url`（不是 `video_url`）。
- 来源影片与每一张参考图都必须是公网免鉴权可直接下载的文件；任一个抓不到时任务会以 `FAILED`＋`Failed to download …` 结束且不计费。
- 此端点回传 DashScope 形状（`output.task_status`、`output.video_url`），且输出长度依来源影片长度，而非 `parameters.duration`。

### 计费

按输出秒数 × 解析度计费，以 video tokens 计量（`宽 × 高 × 秒数 × 24 fps ÷ 1024`）。`-r2v` 与 `-video-edit` 的**输入影片秒数一并计费**，例如以 5 秒来源影片产出 5 秒成品，计 10 秒。任务失败不计费。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

### 其他模型特性

- **浮水印**：HappyHorse 浮水印**默认开启**——需传 `watermark: false` 关闭；Wan 2.7 默认关闭。
- **画面比例**：HappyHorse 在共用清单之外另支持 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 长度**：5,000 字元（HappyHorse 中文 2,500 字）。
- 这些模型尚未支持 `generate_audio`。

### Wan 3.0 使用扁平请求

`wan-3-0-video` 和 `wan-3-0-video-pro` 不吃 `content[]`，提示词和素材都放在顶层栏位。`content` 阵列会被丢掉，内容因此变空时回 `missing_prompt_or_image`。

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{
    "model": "wan-3-0-video",
    "prompt": "a paper boat drifting on still water",
    "first_frame": "https://example.com/first-frame.png",
    "resolution": "720P",
    "ratio": "16:9",
    "duration": 5,
    "audio": false
  }'
# → 202 { "id": "task_..." }
```

| 栏位 | 可用值 | 说明 |
| --- | --- | --- |
| `prompt` | 字串 | 必填 |
| `first_frame`、`last_frame` | 图片 URL | 首尾帧模式 |
| `reference_images` | 最多 10 个 URL | 参考素材模式 |
| `reference_videos`、`reference_audios` | 各最多 5 个 URL | 参考素材模式 |
| `resolution` | 480P、720P、1080P；`-pro` 另有 2K、4K | 要大写 |
| `duration` | 2–30 秒 | |
| `ratio` | 16:9、9:16、4:3、3:4、1:1、adaptive | |
| `audio` | 布林值 | 不是 `generate_audio` |

同一个请求只能用首尾帧模式或参考素材模式，不能混用。送 `aspect_ratio`、`generate_audio`、`watermark` 或 `media` 会回 `400 Extra inputs are not permitted`。

## 错误

- 400 — 请求内容格式错误。
- 402 — `insufficient_quota`：项目余额 ≤ 0（仅阻挡 create；poll / list / cancel 仍可用）。
- 403 — `permission_denied`：gated model 尚未对此项目开放。
- 422 — 该模型没有影片供应商。
- 502 — 上游生成失败。

## 下一步

- [Seedance 2.0](https://atptoken.ai/zh-cn/docs/seedance-2-0/) — `seedance-2-0` 的参数、媒体 role 与请求范例。
- [/v1/files](https://atptoken.ai/zh-cn/docs/files/) — 上传给 chat 与 messages 请求使用的文件。媒体任务无法使用。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
