# 語音生成 (TTS)

> Source: https://atptoken.ai/zh-tw/docs/media-audio/

`POST /omni/media/v1/audio/generations`

文字轉語音是**同步**的——文字進、一個音檔以簽章 URL 回。base URL 與 `atp-` 金鑰同上。Gateway 把 unified `model` 路由到音訊供應商（例如 `fish-s2-pro`）並說對應方言。沒有非同步任務；`GET /omni/media/v1/audio/tasks/{id}` 一律回 `404`。

- **輸出寫入物件儲存、以帶簽章的邊緣 URL（`https://media-<env>.atptoken.ai/v/...`）回傳，**TTL 30 分鐘**——不會內嵌 base64。請盡快取用。**
- 當專案（project）餘額 ≤ 0，請求會以 `402 insufficient_quota` 拒絕。

## 生成語音

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
```

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | 統一語音模型 ID （`audio` 供應商池） |
| text | string · 必填 | 要轉成語音的文字 |
| reference_id | string | 語音 ID（多人對話時傳陣列） |
| format | string | `mp3` （預設） / `wav` / `pcm` / `opus` |
| sample_rate | integer | Hz （依格式預設） |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }` |
| temperature | number | 表現力，0–1（預設 `0.7`） |

**OpenAI 風格 client：**OpenAI TTS 模型也接受 OpenAI 格式——`input`、`voice`、`response_format`——由 Gateway 轉換。

## 回應

#### `200`

```
{
  "created": 1781776187,
  "data": [
    { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
  ]
}
```

## 錯誤

- 400 — 缺 `model` 或 `text`，或 `format` 無效。
- 402 — `insufficient_quota`：專案餘額 ≤ 0；儲值後再送（不要重試轟炸）。
- 422 — 該模型沒有音訊供應商。

## 下一步

- [媒體模型](https://atptoken.ai/zh-tw/docs/media/) — 目錄裡有哪些圖像、影片與語音模型。
- [圖像生成](https://atptoken.ai/zh-tw/docs/media-image/) — 用同一組 base URL 與金鑰生成圖片。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
