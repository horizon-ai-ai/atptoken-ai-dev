# 媒體模型（preview）

> Source: https://atptoken.ai/zh-tw/docs/media/

除了文字之外，目錄還包含**圖像、影片、語音（text-to-speech）與 embedding** 模型。它們與文字模型共用同一套帳號、點數與專案（project）控管，但每種模態有自己的計費單位，不是 input + output tokens。模型與定價見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

> **Preview 狀態**
>
> 媒體生成正以 preview 形式陸續開放。價格頁上標示 **Preview** 的模型已在測試中上線，但價格尚未公布。若你的團隊想要規模化搶先使用，[告訴我們你的使用情境](https://atptoken.ai/zh-tw/enterprise-plan/)。

## 先確認能用哪些模型

用你的金鑰呼叫 `GET https://api.atptoken.ai/v1/project/models`，這是專案能用的完整清單，文字、圖像、影片、語音、embedding 都在裡面。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，媒體模型不在上面。清單上沒有不代表不能用；沒有權限時，建立任務會回 `403`，不收費。

## 圖像、影片、語音都是非同步的

三種媒體都沒有同步版本，流程一樣：建立任務 → 輪詢到終態 → 在簽章 URL 過期前下載。**只有拿結果的欄位不同：**

| 模態 | 端點 | task id | 結果在哪 |
| --- | --- | --- | --- |
| 影片 | `/omni/media/v1/contents/generations/tasks` | `cgt_…` | `content.video_url` |
| 圖像 | `/omni/media/v1/images/generations/tasks` | `img_…` | `data[].url`（陣列） |
| 語音 | `/omni/media/v1/audio/generations/tasks` | `aud_…` | `audio_url`（頂層） |

- 狀態都是 `queued`、`running`、`succeeded`、`failed`、`expired`、`cancelled`，後四個是終態。
- **簽章 URL 24 小時後失效。** 之後狀態仍是 `succeeded`，但網址變成 `null`、另有 `expired: true`。
- 沒有 webhook，`callback_url` 不會被使用，必須輪詢。
- `Idempotency-Key` 每種媒體各用各的；同一把 key 用在兩種媒體會回 `409`。

## 影片

影片模型包含 Seedance（`seedance-2-0`、`-fast`、`-mini`、`seedance-2-5`）、Kling、Wan、HappyHorse 與 MiniMax 系列。不同系列的請求格式不一樣，完整清單與寫法見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)。各模型費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

影片生成按 **video tokens** 計費，任務結束後依實際用量結算：

```
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

`in_dur` 是輸入影片秒數、`out_dur` 是輸出秒數、`W × H` 是輸出寬高。模型自己回報用量時，以回報的為準。

每秒單價速查（牌價，16:9、無影片輸入）：

| 解析度 | 約略單價 / 秒 |
| --- | --- |
| 480p（草稿） | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

下單前值得知道的事：

- **長寬比會影響價格。** 費用按實際的寬 × 高計算——同為 720p，1:1 比 16:9 便宜約 44%。
- **時長交給模型決定時，按實際秒數計費**，不是按請求上的數字。
- **帶參考影片會切換費率檔。** 加入輸入影片後改按 with-input 檔計費，且輸入秒數會進公式。
- **可用解析度依模型而定**，見[影片生成](https://atptoken.ai/zh-tw/docs/media-video/)各系列的說明；費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。
- **餘額耗盡時建立任務回 `402`。** 結算時餘額不足會扣成負值，下一個請求會被擋住。
- **任務失敗不計費。**

Seedance 的參數與範例見 [Seedance](https://atptoken.ai/zh-tw/docs/seedance-2-0/)。

## 圖像

文生圖也是非同步任務：建立任務後輪詢，結果在 `data[].url`。價格將於正式上線時公布；在那之前模型在價格頁標示為 **Preview**。

## 語音（text-to-speech）

TTS 是非同步任務，結果在 `audio_url`。按輸入文字的**字元數**計費，不是 token。價格將於正式上線時公布。

## Embeddings

Embedding 是同步的一步呼叫（`POST /v1/embeddings`），只按 **input tokens** 計費——沒有 output 計量。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

## 下一步

- [Seedance](https://atptoken.ai/zh-tw/docs/seedance-2-0/) — Seedance 的參數、範例與限制。
- [影片生成](https://atptoken.ai/zh-tw/docs/media-video/) — 建立影片任務並輪詢結果。
- [圖像生成](https://atptoken.ai/zh-tw/docs/media-image/) — 用 prompt 生成圖片。
- [語音生成 (TTS)](https://atptoken.ai/zh-tw/docs/media-audio/) — 把文字轉成語音。
