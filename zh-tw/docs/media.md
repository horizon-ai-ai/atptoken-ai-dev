# 媒體模型（preview）

> Source: https://atptoken.ai/zh-tw/docs/media/

除了文字之外，目錄還包含**圖像、影片、語音（text-to-speech）與 embedding** 模型。它們與文字模型共用同一套帳號、credits 與 project 控管，但每種模態有自己的計費單位，不是 input + output tokens。目前的模型與定價見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

> **Preview 狀態**
>
> 媒體生成正以 preview 形式陸續開放。價格頁上標示 **Preview** 的模型已在測試中上線，但價格尚未公布。若你的團隊想要規模化搶先使用，[告訴我們你的使用情境](https://atptoken.ai/zh-tw/enterprise-plan/)。

### 影片

影片模型：**seedance-2-0**（標準）、**seedance-2-0-mini**（輕量、較省）與 **seedance-2-0-fast**（加速）。各模型費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

影片生成按 **video tokens** 計費，由渲染的像素與秒數計算：

```
video_tokens = width × height × (input seconds + output seconds) × 24 ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

每秒單價速查（牌價，16:9、無影片輸入）：

| 解析度 | 約略單價 / 秒 |
| --- | --- |
| 480p（草稿） | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

下單前值得知道的事：

- **長寬比會影響價格。** 費用按實際的寬 × 高計算——同為 720p，1:1 比 16:9 便宜約 44%。
- **duration 設 auto 時按實際秒數計費**，不是按請求上的數字。
- **帶參考影片會切換費率檔。** 加入輸入影片後改按 with-input 檔計費，且輸入秒數會進公式。
- **4K 尚未開放**；超過 1080p 的請求會在建立任務前被拒絕。
- **任務失敗不計費。**

### 圖像

文生圖為同步生成——送出 prompt、回傳圖片 URL。價格將於正式上線時公布；在那之前模型在價格頁標示為 **Preview**。

### 語音（text-to-speech）

TTS 按輸入文字的**字元數**計費，不是 token。價格將於正式上線時公布。

### Embeddings

Embedding 模型只按 **input tokens** 計費——沒有 output 計量。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。
