# /v1/embeddings

> Source: https://atptoken.ai/zh-tw/docs/embeddings/

`POST /v1/embeddings`

一次同步呼叫把文字、圖片、音訊或影片轉成向量。請求格式沿用 OpenAI 的 embeddings 結構，官方 `openai` SDK 只要改 base URL 就能用。Embedding 只按 **input tokens** 計費——沒有 output 計量。費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

## 請求

`input` 是一個字串或一個陣列；每個元素各回一個向量，順序與送出時相同。字串以文字處理。圖片、音訊或影片改送物件而不是字串，見「輸入類型」。

```curl
curl https://api.atptoken.ai/v1/embeddings \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-embedding-2-text",
    "input": ["first passage", "second passage"]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.embeddings.create(
    model="gemini-embedding-2-text",
    input=["first passage", "second passage"],
)
print(len(r.data), len(r.data[0].embedding))
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.embeddings.create({
  model: "gemini-embedding-2-text",
  input: ["first passage", "second passage"],
});
console.log(r.data.length, r.data[0].embedding.length);
```

## 參數

只有 `model` 與 `input` 必填。

| Field | Type | Description |
|---|---|---|
| model | string · required | 下方表格裡的向量模型 id，必須在專案的允許清單上。 |
| input | string, object, or array of either · required | 要轉成向量的內容。字串是文字；物件是一個內容片段（`inlineData` 或 `fileData`），或帶 `parts` 陣列的完整內容。陣列會依序各回一個向量。 |
| dimensions | integer | 向量長度。送模型支援的值（見表格）可取得較短的向量；不送就用模型原生長度。 |
| encoding_format | string | 只回傳 `float`。 |
| user | string | 你自己追蹤用的識別字串，不影響結果。 |

## 回應

```
{
  "object": "list",
  "model": "gemini-embedding-2-text",
  "data": [
    { "object": "embedding", "index": 0, "embedding": [0.0123, -0.0456, ...] },
    { "object": "embedding", "index": 1, "embedding": [0.0078, 0.0211, ...] }
  ],
  "usage": { "prompt_tokens": 11, "total_tokens": 11 }
}
```

- `data[].index` 是該元素在 `input` 裡的位置。
- `usage.prompt_tokens` 是計費數量，為整個請求所有元素的加總。
- 批次是全有或全無：任一元素失敗，整個請求回錯誤、不計費。

## 模型

| Model | Native size | `dimensions` | Input per element |
|---|---|---|---|
| gemini-embedding-2-text | 3072 | 128 到 3072 | 文字，最多 8,192 tokens |
| gemini-embedding-2-image | 3072 | 128 到 3072 | 圖片（PNG、JPEG、WebP、BMP、HEIC、HEIF、AVIF），最多 6 張 |
| gemini-embedding-2-audio | 3072 | 128 到 3072 | 音訊（MP3、WAV），最長 180 秒 |
| gemini-embedding-2-video | 3072 | 128 到 3072 | 影片（MP4、MPEG），最長 120 秒 |
| text-embedding-3-large | 3072 | 3072 以內任意值 | 文字，最多 8,191 tokens |
| text-embedding-3-small | 1536 | 1536 以內任意值 | 文字，最多 8,191 tokens |

四個 Gemini id 是同一個模型、依內容類型各一個計量。它們寫進同一個 3072 維空間，所以不同 id 產生的向量可以互相比較——文字對圖片、查詢對影片都行。各 id 的費率見[價格頁](https://atptoken.ai/zh-tw/pricing/)。

## 輸入類型

`input` 的每個元素是下列其中一種：

| Element | Shape | What it becomes |
|---|---|---|
| 字串 | `"a passage of text"` | 一個文字片段 |
| 內嵌資料 | `{ "inlineData": { "mimeType": "image/png", "data": "<base64>" } }` | 一個帶著位元組的片段 |
| 檔案參照 | `{ "fileData": { "mimeType": "image/png", "fileUri": "https://…" } }` | 一個由模型自行抓取的片段 |
| 完整內容 | `{ "parts": [ { "text": "…" }, { "inlineData": { … } } ] }` | 多個片段，合成一個向量 |

物件原樣轉送。模型用不了的片段——未知的欄位、超過限制的檔案、抓不到的網址——會回 `400`，訊息是模型自己的說法。

#### 帶圖片的請求

```
curl https://api.atptoken.ai/v1/embeddings \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-embedding-2-image",
    "input": [
      { "inlineData": { "mimeType": "image/png", "data": "iVBORw0KGgo..." } }
    ]
  }'
```

> **id 決定費率**
>
> 每個 Gemini id 都收所有元素類型，請求按你呼叫的 id 費率計費。圖片請走 `gemini-embedding-2-image`、音訊走 `-audio`、影片走 `-video`、文字走 `-text`。

## 計費

Embedding 只按 input tokens 計費。Gemini 各 id 的 token 數依內容而定：文字照 tokens 計、圖片每張 258 tokens、音訊每秒 25 tokens、影片每幀 66 tokens（每秒一幀）。含多個片段的元素，計費是各片段的加總。所有元素共用一個 8,192 tokens 的視窗，超過的內容會被截掉而不是拒收。tokens 如何換算成點數見[點數](https://atptoken.ai/zh-tw/docs/credits/)。

## 錯誤

- 400 — `input` 缺少或為空，或模型拒收某個元素：未知的欄位、超過限制的檔案、抓不到的網址。訊息是模型自己的說法。
- 402 — `insufficient_quota`：餘額用完。不要重試，先加值。
- 403 — 模型不在專案的允許清單上，不是金鑰或餘額的問題。
- 422 — `embedding_error`：這個 id 對你的專案不是以向量模型提供。用 `GET /v1/project/models` 核對。
- 429 — 被限流，或這個模型現在沒有容量。依 `Retry-After` 重試。

## 下一步

- [模型探索](https://atptoken.ai/zh-tw/docs/models/) — 列出專案可呼叫的所有模型 id，含向量模型。
- [媒體模型](https://atptoken.ai/zh-tw/docs/media/) — 同一把金鑰的圖像、影片與語音生成。
- [點數](https://atptoken.ai/zh-tw/docs/credits/) — 計費 tokens 如何換算成點數。
