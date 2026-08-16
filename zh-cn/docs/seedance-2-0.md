# Seedance 2.0 视频生成

> Source: https://atptoken.ai/zh-cn/docs/seedance-2-0/

`POST /v1/media/v1/contents/generations/tasks`

Seedance 2.0 是目前 ATP 对外开放的视频生成模型。它支持文生视频、图生视频、首帧与尾帧控制、参考图、可选生成音频，以及异步任务轮询。

> **模型 ID**
>
> `model` 字段请使用 `seedance-2-0`。其他 Seedance 变体可能存在于内部价格数据，但目前尚未公开显示在模型目录。

### 参数

| 字段 | 可用值 | 说明 |
| --- | --- | --- |
| `model` | `seedance-2-0` | 必填。 |
| `resolution` | `480p`, `720p`, `1080p`, `4k` | `480p` 适合低成本测试；4K 使用独立计费档位。 |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `21:9`, `adaptive` | 费用跟实际渲染像素有关，同分辨率下正方形视频会比 16:9 便宜。 |
| `duration` | 4 到 15 的整数秒 | 最便宜的功能测试可用 `4` 秒。 |
| `generate_audio` | `true`, `false` | 要求模型同时生成视频音频。 |
| `return_last_frame` | `true`, `false` | 启用后，完成任务的输出可包含尾帧 URL。 |
| `content` | 文本加上可选媒体 parts | 对图片、视频、音频 part 使用 `role` 说明素材用途。 |

### 媒体 roles

| Role | 用途 |
| --- | --- |
| `first_frame` | 图生视频的起始画面。 |
| `last_frame` | 用于控制转场结尾的尾帧。 |
| `reference_image` | 视觉、风格或角色参考图。这不是首帧或尾帧。 |
| `reference_video` | 动作或风格参考视频。 |
| `reference_audio` | 所选流程支持时的音频参考。 |

### 文生视频

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

创建任务后会返回 `cgt_...` 形式的 task id。

### 图生视频

图片可以使用 HTTPS URL、base64 image URL，或已上传的 `asset://...` 引用。

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

### 轮询任务

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks/cgt_xxx" \
  -H "Authorization: Bearer $ATP_API_KEY"
```

持续轮询直到任务状态变成 `succeeded`、`failed` 或 `canceled`。成功时会返回视频 URL 与 usage metadata。

### 计费

视频按 video tokens 计费：

```text
video_tokens = width × height × seconds × 24 ÷ 1024
cost = video_tokens × resolution_rate
```

任务失败不计费。最便宜的端到端 smoke test 可用 `480p`、`duration: 4`、`generate_audio: false`。
