# Seedance 影片生成

> Source: https://atptoken.ai/zh-cn/docs/seedance-2-0/

`POST /omni/media/v1/contents/generations/tasks`

Seedance 系列支持文生影片、图生影片、首帧与尾帧控制、参考图、参考影片与参考音讯，以及可选的生成音讯。所有 Seedance 模型共用[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)的端点与 `content[]` 格式：建立任务、轮询到终态、下载 `content.video_url`。不确定用哪个，就用 `seedance-2-0`。

## 选模型

| 模型 ID | 适合 | 解析度 | 时长 | 素材怎么传 |
| --- | --- | --- | --- | --- |
| `seedance-2-0` | 一般用途 | `480p`、`720p`、`1080p`、`4k` | 4–15 秒 | 公开网址或素材 |
| `seedance-2-0-fast` | 要快 | `480p`、`720p` | 4–15 秒 | **只能公开网址** |
| `seedance-2-0-mini` | 要省 | `480p`、`720p` | 4–15 秒 | 依组合而定，见下方 |
| `seedance-2-5` | 素材较多、片长较长 | `480p`、`720p`、`1080p` | `-1`，或 4–30 秒 | 公开网址或素材 |

> **先确认这把密钥能用哪些模型**
>
> 用建立任务时的同一把密钥呼叫 `GET https://api.atptoken.ai/v1/project/models`，这是项目能用的完整清单（`/v1/models` 只列 chat 模型）。清单上没有不代表不能用；没有权限时，建立任务会回 `403`，不收费。
>
> 模型 ID 是 `seedance-2-0-mini`。`seedance-2-mini` 不是它的别名，送出会回 `400 InvalidParameter`。

## 支持的生成模式

| 模式 | 要送什么 |
| --- | --- |
| 文生影片 | 只有文字 part |
| 图生影片 | 一个 `role: "first_frame"` 的图片 part |
| 首帧与尾帧 | 分别带 `first_frame` 与 `last_frame` 的图片 parts |
| 参考素材 | 一或多个 `reference_image`、`reference_video` 或 `reference_audio` parts |
| 生成音讯 | `generate_audio: true` |

首帧／尾帧模式和参考素材模式是两种不同的操作：首帧会成为影片的第一个画面；参考图只提供外观、风格或角色，不会被当成第一个画面。

### 各模型支持的素材组合

| 模型 | 支持的组合（另外都支持纯文字） |
| --- | --- |
| `seedance-2-0` | 首帧；首帧＋尾帧；参考图；参考图＋参考音讯；参考影片；图＋影片＋音讯全模态 |
| `seedance-2-0-fast` | 首帧；首帧＋尾帧；参考图（全部走公开网址） |
| `seedance-2-0-mini` | 首帧（公开网址）；首帧＋尾帧（素材）；最多 3 张参考图（公开网址） |
| `seedance-2-5` | 只给参考音讯；首帧＋尾帧；参考图；参考图＋参考音讯；参考影片 |

### 素材数量上限

| 模型 | 图 | 影片 | 音讯 |
| --- | --- | --- | --- |
| `seedance-2-0`、`-fast`、`-mini` | 9 | 3 | 3，**不能单独使用** |
| `seedance-2-5` | 30 | 10 | 10，**可以只有音讯** |

### 媒体 roles

| Role | part 类型 | 用途 |
| --- | --- | --- |
| `first_frame` | `image_url` | 影片的起始画面。 |
| `last_frame` | `image_url` | 影片的结尾画面。 |
| `reference_image` | `image_url` | 外观、风格或角色参考。 |
| `reference_video` | `video_url` | 动作或风格参考。 |
| `reference_audio` | `audio_url` | 声音参考。只有 `seedance-2-5` 可以单独送参考音讯。 |

## 参数

| 栏位 | 可用值 | 默认 | 说明 |
| --- | --- | --- | --- |
| `model` | 见上方「选模型」 | | 必填。 |
| `content` | 文字加上可选媒体 parts | | 必填。 |
| `resolution` | 依模型，见上方「选模型」 | `480p` | `480p` 适合低成本测试。`4k` 只有 `seedance-2-0`；`-fast`、`-mini` 最高 `720p`。 |
| `ratio` | `16:9`、`9:16`、`4:3`、`3:4`、`1:1`、`21:9`、`adaptive` | `16:9` | 有首帧时的用法见下方。 |
| `duration` | 整数秒，见上方「选模型」 | `4` | 最便宜的功能测试可用 `4` 秒。`seedance-2-5` 可送 `-1`：交给模型用默认长度，有输入影片时通常跟著影片长度；依实际输出秒数计费。 |
| `generate_audio` | `true`、`false` | `false` | 要求模型同时生成音轨。 |
| `return_last_frame` | `true`、`false` | | 启用后，完成的任务会多带 `content.last_frame_url`。 |
| `output_format` | `mp4`、`mov` | `mp4` | 仅 `seedance-2-5`。 |

### 有首帧时，画面比例怎么决定

- **`seedance-2-0` 系列（含 fast、mini）：输出比例由 `ratio` 决定，不是由首帧决定。** `ratio` 默认 `16:9`，所以直式首帧不指定比例，会得到横式影片（480p 时 864×496），画面被重新构图。送 `ratio: "adaptive"`，输出就跟著首帧（直式首帧 → 496×864）。
- **`seedance-2-5`：** 带首尾帧时**不要送 `ratio`**。没有首尾帧时可以送，例如 `ratio: "16:9"`。

## 素材怎么传

`content[].image_url.url` 可以放公开 `https://` URL、base64，或素材 API 回传的 `asset://…`（`AssetUri`）。登记素材的做法、常见错误与排队规则，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)的「素材怎么传」。

| 模型 | 公开网址 | 素材（`asset://`） |
| --- | --- | --- |
| `seedance-2-0` | 可以 | 可以 |
| `seedance-2-0-mini` | 首帧、参考图用这个 | 首帧＋尾帧用这个 |
| `seedance-2-0-fast` | 只能用这个 | 回 `422 this asset's upstream does not serve the requested model` |
| `seedance-2-5` | 可以 | 可以 |

`/v1/files` 的文件 ID（`an_…`）不是素材网址，放进来会回 `400`。

> **素材名称最多 64 个字元**
>
> 在 `seedance-2-0`、`seedance-2-0-mini` 上登记素材时，`name` 超过 64 个字元，登记照样回 200，但 `assets/get` 会回失败（`InvalidParameter.Name`），建任务得到 `ATP_ASSET_FAILED`。这不是偶发，缩短 `name` 即可，不必改用公开网址。

### 真人照片

真人照片用公开 URL 送出时，可能被拒并回 `400 … may contain real person`。被挡时把同一张图登记成素材，改传 `AssetUri`，不需要核身。`seedance-2-0-fast` 不能用素材，所以**真人照片和 `-fast` 不能一起用**，请改用 `seedance-2-0` 或 `seedance-2-5`。产品要求核身时，流程见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)的「真人照片」。

## 范例

以下范例都送到同一个端点：

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-video-job-001" \
  --data-binary @request.json
# → 202 { "id": "cgt_..." }
```

把下列任一段存成 `request.json`。网络中断后重送同一个请求时，沿用同一个 `Idempotency-Key`；新的作品换新的 key。

### 文生影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "A cinematic tracking shot of Taipei at night, neon reflections, smooth camera motion" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

### 图生影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "Animate this product shot with a slow premium studio push-in." },
    { "type": "image_url", "image_url": { "url": "https://example.com/product.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "ratio": "adaptive",
  "duration": 4,
  "generate_audio": false,
  "return_last_frame": true
}
```

`"ratio": "adaptive"` 不要拿掉，原因见上方「画面比例怎么决定」。

### 首帧与尾帧（Seedance 2.5）

```json
{
  "model": "seedance-2-5",
  "content": [
    { "type": "text", "text": "Create a smooth transition from morning to night with consistent camera framing." },
    { "type": "image_url", "image_url": { "url": "https://example.com/morning.jpg" }, "role": "first_frame" },
    { "type": "image_url", "image_url": { "url": "https://example.com/night.jpg" }, "role": "last_frame" }
  ],
  "resolution": "720p",
  "duration": 6,
  "generate_audio": false,
  "output_format": "mp4"
}
```

这里刻意不送 `ratio`，原因见上方「画面比例怎么决定」。

### 参考图加参考影片

```json
{
  "model": "seedance-2-0",
  "content": [
    { "type": "text", "text": "The character from the reference image dances with the motion of the reference video." },
    { "type": "image_url", "image_url": { "url": "https://example.com/character.jpg" }, "role": "reference_image" },
    { "type": "video_url", "video_url": { "url": "https://example.com/motion.mp4" }, "role": "reference_video" }
  ],
  "resolution": "480p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false
}
```

## 取得结果

```bash
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_xxx \
  -H "Authorization: Bearer $ATP_API_KEY"
```

持续轮询，直到 `status` 变成 `succeeded`、`failed`、`cancelled` 或 `expired`。成功时从 `content.video_url` 下载影片。这个网址 **24 小时**后失效：状态仍是 `succeeded`，但 `video_url` 变成 `null`、另有 `expired: true`。请在期限内存到自己的储存空间。

## 计费

影片按 video tokens 计费，任务进入终态后依实际用量结算：

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` 是输入影片秒数、`out_dur` 是输出秒数。模型自己回报用量时，以回报的为准。任务失败不计费。最便宜的端到端 smoke test 可用 `480p`、`duration: 4`、`generate_audio: false`。

**每秒输出价格 · 480p**

| 项目 | USD / s |
|---|---:|
| seedance-2-0 | $0.07 |
| seedance-2-0-fast | $0.0538 |

## 下一步

- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 端点参考，含 `url` 接受的形式、素材 API 与错误码。
- [价格](https://atptoken.ai/zh-cn/docs/pricing-model/) — 用量计费与各模型费率怎么运作。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 用量怎么从点数扣款。
