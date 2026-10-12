# 语音生成 (TTS)

> Source: https://atptoken.ai/zh-cn/docs/media-audio/

`POST /omni/media/v1/audio/generations`

文字转语音是**同步**的——文字进、一个音档以签章 URL 回。base URL 与 `atp-` 密钥同上。Gateway 把 unified `model` 路由到音讯供应商（例如 `fish-s2-pro`）并说对应方言。没有非同步任务；`GET /omni/media/v1/audio/tasks/{id}` 一律回 `404`。

- **输出写入物件储存、以带签章的边缘 URL（`https://media-<env>.atptoken.ai/v/...`）回传，**TTL 30 分钟**——不会内嵌 base64。请尽快取用。**
- 当项目（project）余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

## 生成语音

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
```

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | 统一语音模型 ID （`audio` 供应商池） |
| text | string · 必填 | 要转成语音的文字 |
| reference_id | string | 语音 ID（多人对话时传阵列） |
| format | string | `mp3` （默认） / `wav` / `pcm` / `opus` |
| sample_rate | integer | Hz （依格式默认） |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }` |
| temperature | number | 表现力，0–1（默认 `0.7`） |

**OpenAI 风格 client：**OpenAI TTS 模型也接受 OpenAI 格式——`input`、`voice`、`response_format`——由 Gateway 转换。

## 回应

#### `200`

```
{
  "created": 1781776187,
  "data": [
    { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
  ]
}
```

## 错误

- 400 — 缺 `model` 或 `text`，或 `format` 无效。
- 402 — `insufficient_quota`：项目余额 ≤ 0；充值后再送（不要重试轰炸）。
- 422 — 该模型没有音讯供应商。

## 下一步

- [媒体模型](https://atptoken.ai/zh-cn/docs/media/) — 目录里有哪些图像、影片与语音模型。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 用同一组 base URL 与密钥生成图片。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
