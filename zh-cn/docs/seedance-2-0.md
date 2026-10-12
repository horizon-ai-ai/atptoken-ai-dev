# Seedance 2.0 影片生成

> Source: https://atptoken.ai/zh-cn/docs/seedance-2-0/

`POST /v1/media/v1/contents/generations/tasks`

Seedance 2.0 是 ATP 对外开放的影片生成模型。它支持文生影片、图生影片、首帧与尾帧控制、参考图、可选生成音讯，以及非同步任务轮询。

> **模型 ID**
>
> `model` 栏位请使用 `seedance-2-0`。其他 Seedance 变体可能存在于内部价格数据，但尚未公开显示在模型目录。

## 支持的生成模式

| 模式 | 要送什么 |
| --- | --- |
| 文生影片 | 只有文字 part |
| 图生影片 | 一个 `role: "first_frame"` 的图片 part |
| 首帧与尾帧 | 分别带 `first_frame` 与 `last_frame` 的图片 parts |
| 参考图 | 一个 `role: "reference_image"` 的图片 part |
| 生成音讯 | `generate_audio: true` |

### 媒体 roles

| Role | 用途 |
| --- | --- |
| `first_frame` | 图生影片的起始画面。 |
| `last_frame` | 用于控制转场结尾的尾帧。 |
| `reference_image` | 视觉、风格或角色参考图。这不是首帧或尾帧。 |
| `reference_video` | 动作或风格参考影片。 |
| `reference_audio` | 所选流程支持时的音讯参考。 |

## 参数

| 栏位 | 可用值 | 说明 |
| --- | --- | --- |
| `model` | `seedance-2-0` | 必填。 |
| `resolution` | `480p`, `720p`, `1080p`, `4k` | `480p` 适合低成本测试；4K 使用独立计费档位。 |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `21:9`, `adaptive` | 费用跟实际渲染像素有关，同解析度下正方形影片会比 16:9 便宜。 |
| `duration` | 4 到 15 的整数秒 | 最便宜的功能测试可用 `4` 秒。 |
| `generate_audio` | `true`, `false` | 要求模型同时生成影片音讯。 |
| `return_last_frame` | `true`, `false` | 启用后，完成任务的输出可包含尾帧 URL。 |
| `content` | 文字加上可选媒体 parts | 对图片、影片、音讯 part 使用 `role` 说明素材用途。 |

## 图片输入

图片可以使用 HTTPS URL、base64 image URL，或素材 API 回传的 `asset://…` URI（`AssetUri` 请原样使用）。要取得素材 URI，先通过素材 API 登记图片、等到状态为 `Completed`，步骤见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。URI 只放在 `image_url.url`，part 没有顶层 `url`。

## 范例

### 文生影片

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks" \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "seedance-2-0",
    "content": [
      {
        "type": "text",
        "text": "A cinematic tracking shot of Taipei at night, neon reflections, smooth camera motion"
      }
    ],
    "resolution": "480p",
    "ratio": "16:9",
    "duration": 4,
    "generate_audio": false
  }'
```

建立任务后会回传 `cgt_...` 形式的 task id。

### 图生影片

```json
{
  "model": "seedance-2-0",
  "content": [
    {
      "type": "text",
      "text": "Animate this product shot with a slow premium studio push-in."
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "https://example.com/product.jpg"
      },
      "role": "first_frame"
    }
  ],
  "resolution": "720p",
  "ratio": "16:9",
  "duration": 4,
  "generate_audio": false,
  "return_last_frame": true
}
```

### 首帧与尾帧

```json
{
  "model": "seedance-2-0",
  "content": [
    {
      "type": "text",
      "text": "Create a smooth transition from morning to night with consistent camera framing."
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "asset://tya_first_frame"
      },
      "role": "first_frame"
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "asset://tya_last_frame"
      },
      "role": "last_frame"
    }
  ],
  "resolution": "720p",
  "ratio": "16:9",
  "duration": 6,
  "return_last_frame": true
}
```

## 取得结果

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks/cgt_xxx" \
  -H "Authorization: Bearer $ATP_API_KEY"
```

持续轮询直到任务状态变成 `succeeded`、`failed` 或 `canceled`。成功时会回传影片 URL 与用量 metadata。

## 计费

影片按 video tokens 计费：

```text
video_tokens = width × height × seconds × 24 ÷ 1024
cost = video_tokens × resolution_rate
```

任务失败不计费。最便宜的端到端 smoke test 可用 `480p`、`duration: 4`、`generate_audio: false`。

**每秒输出价格 · 480p**

| 项目 | USD / s |
|---|---:|
| seedance-2-0 | $0.07 |
| seedance-2-0-fast | $0.0538 |

## 下一步

- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 端点参考，含 `url` 接受的形式与素材 API。
- [价格](https://atptoken.ai/zh-cn/docs/pricing-model/) — 用量计费与各模型费率怎么运作。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 用量怎么从点数扣款。
