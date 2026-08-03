# 语音生成 (TTS)

> Source: https://atptoken.ai/zh-cn/docs/media-audio/

`POST /omni/media/v1/audio/generations`

文字转语音是**同步**的——文字进、一个音频文件以签名 URL 回。base URL 与 `atp-` key 同上。gateway 把 unified `model` 路由到音频 provider（例如 `fish-s2-pro`）并说对应方言。没有异步任务；`GET /omni/media/v1/audio/tasks/{id}` 一律回 `404`。

- **输出写入对象存储、以带签名的边缘 URL（`https://media-<env>.atptoken.ai/v/...`）回传，**TTL 30 分钟**——不会内嵌 base64。请尽快取用。**
- 当 project 余额 ≤ 0，请求会以 `402 insufficient_quota` 拒绝。

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
```

| 字段 | 类型 | 说明 |
|---|---|---|
| model | string · 必填 | unified audio model (`audio` pool) |
| text | string · 必填 | text to speak |
| reference_id | string | voice id (string, or array for multi-speaker) |
| format | string | `mp3` (default) / `wav` / `pcm` / `opus` |
| sample_rate | integer | Hz (format default) |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }` |
| temperature | number | expressiveness 0–1 (default `0.7`) |

#### 响应 `200`

```
{
  "created": 1781776187,
  "data": [
    { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
  ]
}
```

**OpenAI 风格 client：**OpenAI TTS 模型也接受 OpenAI 格式——`input`、`voice`、`response_format`——由 gateway 转换。

### 错误

- 400 — missing `model` / `text`, or an invalid `format`.
- 402 insufficient_quota — project balance ≤ 0; top up and retry (don't hammer).
- 422 — the model has no audio provider.
