# 語音生成 (TTS)

> Source: https://atptoken.ai/zh-tw/docs/media-audio/

`POST /omni/media/v1/audio/generations/tasks`

文字轉語音是**非同步**的，沒有同步版本。流程和圖像、影片一樣是三步：建立任務（回 `202` + `aud_…` 任務 id）→ 輪詢到終態 → 在 24 小時內下載**頂層的 `audio_url`**。base URL 與 `atp-` 金鑰同圖像生成。

- **輸出是簽章 URL（`https://media-<env>.atptoken.ai/v/...`），效期 24 小時**，不會內嵌 base64。要留存就下載。
- 專案（project）餘額 ≤ 0 時，請求會以 `402 insufficient_quota` 拒絕。
- `callback_url` 會被接受，但**不會有 webhook**。一定要輪詢。

為什麼是非同步：語音要整段算完才會送出第一個位元組，長文本撐不過連線的閒置斷線。改成入列＋輪詢，長文本才服務得了。

## 建立任務

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: tts-job-001" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
# → 202 { "id": "aud_..." }
```

回 `202` 時**還沒開始合成**，拿到的是任務 id。

可用模型：`fish-s2-pro`、`gemini-3-1-flash-tts`。這把金鑰實際放行哪些模型，以 `GET /v1/project/models` 為準；`GET /v1/models` 只列 chat 模型，語音模型不在裡面。沒有授權的模型會在建立時回 `403`，不收費。

**必填只有兩個：`model` 和 `text`。** 欄位名是 `text`，不是 `input`，也不是 `prompt`。

下表是完整參數集。不同模型取用其中能對應的部分，其餘套用模型自己的預設。**送了不報錯不代表有讀到**，要確認就比對輸出。

| 欄位 | 型別 | 說明 |
|---|---|---|
| model | string · 必填 | 語音模型名稱 |
| text | string · 必填 | 要轉成語音的文字 |
| format | string | `mp3`（預設）／ `wav` ／ `pcm` ／ `opus`。決定副檔名與 content-type，無效值回 `400` |
| reference_id | string / array | 語音模型 ID；多說話者可傳陣列 |
| references | array | 直接內嵌的聲音樣本 `{audio, text}`（音檔＋逐字稿）；多說話者可為巢狀陣列 |
| sample_rate | integer | 取樣率 Hz；不填用格式預設 |
| mp3_bitrate | integer | `64` ／ `128`（預設）／ `192`，只用於 `format=mp3` |
| opus_bitrate | integer | `-1000`（自動，預設）／ `24000` ／ `32000` ／ `48000` ／ `64000`，只用於 `format=opus` |
| temperature | number | 表現力，0–1（預設 `0.7`） |
| top_p | number | 多樣性，0–1（預設 `0.7`） |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }`：語速倍率 0.5–2.0、音量調整 dB、響度正規化 |
| chunk_length | integer | 文字分段大小，100–300（預設 `300`） |
| min_chunk_length | integer | 分新段前最少字元，0–100（預設 `50`） |
| max_new_tokens | integer | 每段最多生成的音訊 token（預設 `1024`） |
| normalize | boolean | 文字正規化，讓數字唸法穩定（預設 `true`） |
| condition_on_previous_chunks | boolean | 參考前段音訊，維持聲音一致（預設 `true`） |
| latency | string | `low` ／ `balanced` ／ `normal`（預設），延遲與品質的取捨 |
| repetition_penalty | number | 大於 1 降低重複（預設 `1.2`） |
| early_stop_threshold | number | 批次早停門檻，0–1（預設 `1`） |

**想用特定聲音**有兩種做法：`reference_id`（已註冊的語音模型 ID），或 `references`（直接內嵌樣本音檔和它的逐字稿）。多說話者時兩者都可以傳陣列。

**冪等鍵：** 網路失敗重試建立時沿用同一個 `Idempotency-Key`。圖像、影片、語音要各用各的鍵：同一把鍵已用在別的媒體介面，會回 `409`。

## 輪詢至終態

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/aud_... \
  -H "Authorization: Bearer atp-..."
# → { "id": "aud_...", "status": "succeeded", "audio_url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
```

- 狀態：`queued`、`running`、`succeeded`、`failed`、`expired`、`cancelled`。後四個是終態，**四個都要跳出迴圈**。
- **結果在頂層 `audio_url`**，不是 `content.audio_url`，也不是 `data[].url`。
- **`succeeded` 不保證拿得到檔案。** 超過 24 小時後，狀態仍是 `succeeded`，但 `audio_url` 變成 `null`，另外多一個 `expired: true`。判完 `succeeded` 還要檢查 `audio_url` 是不是 `null`。
- `failed` 任務帶 `error: { code, message }`。
- 任務一建立就查得到；查不到或不屬於你的專案回 `404`。

完整的建立＋輪詢＋下載：

```
TASK=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer $ATPTOKEN_KEY" -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }' | jq -r '.id')

while true; do
  RESP=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/$TASK \
    -H "Authorization: Bearer $ATPTOKEN_KEY")
  S=$(echo "$RESP" | jq -r '.status')
  case "$S" in
    succeeded) break ;;
    failed|expired|cancelled) echo "$RESP" | jq '.error'; exit 1 ;;
  esac
  sleep 3
done

URL=$(echo "$RESP" | jq -r '.audio_url')
[ "$URL" = "null" ] && { echo "expired"; exit 1; }
curl -s -o out.mp3 "$URL"
```

| Method | Path | 動作 |
| --- | --- | --- |
| POST | /omni/media/v1/audio/generations/tasks | 建立 |
| GET | /omni/media/v1/audio/generations/tasks/{id} | 輪詢 |
| GET | /omni/media/v1/audio/generations/tasks | 列出這個專案的任務 |
| DELETE | /omni/media/v1/audio/generations/tasks/{id} | `queued` 會取消；已終態會刪除紀錄；`running` 回 `409` |

取消時若回 `503`，代表取消**沒有送達**：任務會照常生成並計費。請重試取消，不要當成已取消。

## 錯誤

- 400 — 缺 `model` 或 `text`，或 `format` 無效。讀訊息修正。
- 401 — `token_revoked`：金鑰無效，**完全沒送金鑰也會得到這個**。先確認 header 有送出去。
- 402 — `insufficient_quota`：專案餘額耗盡。不是暫時性限流，**不要重試**；儲值後再送。
- 403 — `permission_denied`：這個模型受控，你的專案不在白名單。不是金鑰也不是餘額問題。不收費。
- 404 — 輪詢時：任務不存在或不屬於此專案。
- 409 — 這把 `Idempotency-Key` 已用在另一個媒體介面的任務上，請換一把；或取消 `running` 中的任務。
- 422 — 這個模型沒有可用容量。換模型。
- 503 — 任務無法入列，或 `balance_check_unavailable`（**餘額讀取失敗，不是餘額不足**，請求沒有開始、沒有扣款）。兩種都可重試。

## 下一步

- [媒體模型](https://atptoken.ai/zh-tw/docs/media/) — 目錄裡有哪些圖像、影片與語音模型。
- [圖像生成](https://atptoken.ai/zh-tw/docs/media-image/) — 用同一組 base URL 與金鑰生成圖片。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼代表什麼、先檢查什麼。
