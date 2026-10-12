# Seedance 2.0 影片生成

> Source: https://atptoken.ai/zh-tw/docs/seedance-2-0/

`POST /v1/media/v1/contents/generations/tasks`

Seedance 2.0 是 ATP 對外開放的影片生成模型。它支援文生影片、圖生影片、首幀與尾幀控制、參考圖、可選生成音訊，以及非同步任務輪詢。

> **模型 ID**
>
> `model` 欄位請使用 `seedance-2-0`。其他 Seedance 變體可能存在於內部價格資料，但尚未公開顯示在模型目錄。

## 支援的生成模式

| 模式 | 要送什麼 |
| --- | --- |
| 文生影片 | 只有文字 part |
| 圖生影片 | 一個 `role: "first_frame"` 的圖片 part |
| 首幀與尾幀 | 分別帶 `first_frame` 與 `last_frame` 的圖片 parts |
| 參考圖 | 一個 `role: "reference_image"` 的圖片 part |
| 生成音訊 | `generate_audio: true` |

### 媒體 roles

| Role | 用途 |
| --- | --- |
| `first_frame` | 圖生影片的起始畫面。 |
| `last_frame` | 用於控制轉場結尾的尾幀。 |
| `reference_image` | 視覺、風格或角色參考圖。這不是首幀或尾幀。 |
| `reference_video` | 動作或風格參考影片。 |
| `reference_audio` | 所選流程支援時的音訊參考。 |

## 參數

| 欄位 | 可用值 | 說明 |
| --- | --- | --- |
| `model` | `seedance-2-0` | 必填。 |
| `resolution` | `480p`, `720p`, `1080p`, `4k` | `480p` 適合低成本測試；4K 使用獨立計費檔位。 |
| `ratio` | `16:9`, `9:16`, `4:3`, `3:4`, `1:1`, `21:9`, `adaptive` | 費用跟實際渲染像素有關，同解析度下正方形影片會比 16:9 便宜。 |
| `duration` | 4 到 15 的整數秒 | 最便宜的功能測試可用 `4` 秒。 |
| `generate_audio` | `true`, `false` | 要求模型同時生成影片音訊。 |
| `return_last_frame` | `true`, `false` | 啟用後，完成任務的輸出可包含尾幀 URL。 |
| `content` | 文字加上可選媒體 parts | 對圖片、影片、音訊 part 使用 `role` 說明素材用途。 |

## 圖片輸入

圖片可以使用 HTTPS URL、base64 image URL，或素材 API 回傳的 `asset://…` URI（`AssetUri` 請原樣使用）。要取得素材 URI，先透過素材 API 登記圖片、等到狀態為 `Completed`，步驟見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。URI 只放在 `image_url.url`，part 沒有頂層 `url`。

## 範例

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

建立任務後會回傳 `cgt_...` 形式的 task id。

### 圖生影片

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

### 首幀與尾幀

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

## 取得結果

```bash
curl "$ATP_BASE_URL/v1/media/v1/contents/generations/tasks/cgt_xxx" \
  -H "Authorization: Bearer $ATP_API_KEY"
```

持續輪詢直到任務狀態變成 `succeeded`、`failed` 或 `canceled`。成功時會回傳影片 URL 與用量 metadata。

## 計費

影片按 video tokens 計費：

```text
video_tokens = width × height × seconds × 24 ÷ 1024
cost = video_tokens × resolution_rate
```

任務失敗不計費。最便宜的端到端 smoke test 可用 `480p`、`duration: 4`、`generate_audio: false`。

**每秒輸出價格 · 480p**

| 項目 | USD / s |
|---|---:|
| seedance-2-0 | $0.07 |
| seedance-2-0-fast | $0.0538 |

## 下一步

- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 端點參考，含 `url` 接受的形式與素材 API。
- [價格](https://atptoken.ai/zh-tw/docs/pricing-model/) — 用量計費與各模型費率怎麼運作。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 用量怎麼從點數扣款。
