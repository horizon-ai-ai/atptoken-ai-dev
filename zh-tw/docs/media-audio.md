# 語音生成 (TTS)

> Source: https://atptoken.ai/zh-tw/docs/media-audio/

`POST /omni/media/v1/audio/generations`

文字轉語音是**同步**的——文字進、一個音檔以簽章 URL 回。base URL 與 `atp-` key 同上。gateway 把 unified `model` 路由到音訊 provider（例如 `fish-s2-pro`）並說對應方言。沒有非同步任務；`GET /omni/media/v1/audio/tasks/{id}` 一律回 `404`。

- **輸出寫入物件儲存、以帶簽章的邊緣 URL（`https://media-<env>.atptoken.ai/v/...`）回傳，**TTL 30 分鐘**——不會內嵌 base64。請盡快取用。**
- 當 project 餘額 ≤ 0，請求會以 `402 insufficient_quota` 拒絕。

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
```

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | unified audio model (`audio` pool) |
| text | string · 必填 | text to speak |
| reference_id | string | voice id (string, or array for multi-speaker) |
| format | string | `mp3` (default) / `wav` / `pcm` / `opus` |
| sample_rate | integer | Hz (format default) |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }` |
| temperature | number | expressiveness 0–1 (default `0.7`) |

#### 回應 `200`

```
{
  "created": 1781776187,
  "data": [
    { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
  ]
}
```

**OpenAI 風格 client：**OpenAI TTS 模型也接受 OpenAI 格式——`input`、`voice`、`response_format`——由 gateway 轉換。

### 錯誤

- 400 — missing `model` / `text`, or an invalid `format`.
- 402 insufficient_quota — project balance ≤ 0; top up and retry (don't hammer).
- 422 — the model has no audio provider.
