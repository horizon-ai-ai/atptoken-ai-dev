# /v1/embeddings

> Source: https://atptoken.ai/zh-cn/docs/embeddings/

`POST /v1/embeddings`

一次同步呼叫把文字、图片、音讯或影片转成向量。请求格式沿用 OpenAI 的 embeddings 结构，官方 `openai` SDK 只要改 base URL 就能用。Embedding 只按 **input tokens** 计费——没有 output 计量。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

## 请求

`input` 是一个字串或一个阵列；每个元素各回一个向量，顺序与送出时相同。字串以文字处理。图片、音讯或影片改送物件而不是字串，见「输入类型」。

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

## 参数

只有 `model` 与 `input` 必填。

| Field | Type | Description |
|---|---|---|
| model | string · required | 下方表格里的向量模型 id，必须在项目的允许清单上。 |
| input | string, object, or array of either · required | 要转成向量的内容。字串是文字；物件是一个内容片段（`inlineData` 或 `fileData`），或带 `parts` 阵列的完整内容。阵列会依序各回一个向量。 |
| dimensions | integer | 向量长度。送模型支持的值（见表格）可取得较短的向量；不送就用模型原生长度。 |
| encoding_format | string | 只回传 `float`。 |
| user | string | 你自己追踪用的识别字串，不影响结果。 |

## 回应

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

- `data[].index` 是该元素在 `input` 里的位置。
- `usage.prompt_tokens` 是计费数量，为整个请求所有元素的加总。
- 批次是全有或全无：任一元素失败，整个请求回错误、不计费。

## 模型

| Model | Native size | `dimensions` | Input per element |
|---|---|---|---|
| gemini-embedding-2-text | 3072 | 128 到 3072 | 文字，最多 8,192 tokens |
| gemini-embedding-2-image | 3072 | 128 到 3072 | 图片（PNG、JPEG、WebP、BMP、HEIC、HEIF、AVIF），最多 6 张 |
| gemini-embedding-2-audio | 3072 | 128 到 3072 | 音讯（MP3、WAV），最长 180 秒 |
| gemini-embedding-2-video | 3072 | 128 到 3072 | 影片（MP4、MPEG），最长 120 秒 |
| text-embedding-3-large | 3072 | 3072 以内任意值 | 文字，最多 8,191 tokens |
| text-embedding-3-small | 1536 | 1536 以内任意值 | 文字，最多 8,191 tokens |

四个 Gemini id 是同一个模型、依内容类型各一个计量。它们写进同一个 3072 维空间，所以不同 id 产生的向量可以互相比较——文字对图片、查询对影片都行。各 id 的费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

## 输入类型

`input` 的每个元素是下列其中一种：

| Element | Shape | What it becomes |
|---|---|---|
| 字串 | `"a passage of text"` | 一个文字片段 |
| 内嵌数据 | `{ "inlineData": { "mimeType": "image/png", "data": "<base64>" } }` | 一个带着字节的片段 |
| 文件参照 | `{ "fileData": { "mimeType": "image/png", "fileUri": "https://…" } }` | 一个由模型自行抓取的片段 |
| 完整内容 | `{ "parts": [ { "text": "…" }, { "inlineData": { … } } ] }` | 多个片段，合成一个向量 |

物件原样转送。模型用不了的片段——未知的栏位、超过限制的文件、抓不到的网址——会回 `400`，消息是模型自己的说法。

#### 带图片的请求

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

> **id 决定费率**
>
> 每个 Gemini id 都收所有元素类型，请求按你呼叫的 id 费率计费。图片请走 `gemini-embedding-2-image`、音讯走 `-audio`、影片走 `-video`、文字走 `-text`。

## 计费

Embedding 只按 input tokens 计费。Gemini 各 id 的 token 数依内容而定：文字照 tokens 计、图片每张 258 tokens、音讯每秒 25 tokens、影片每帧 66 tokens（每秒一帧）。含多个片段的元素，计费是各片段的加总。所有元素共用一个 8,192 tokens 的视窗，超过的内容会被截掉而不是拒收。tokens 如何换算成点数见[点数](https://atptoken.ai/zh-cn/docs/credits/)。

## 错误

- 400 — `input` 缺少或为空，或模型拒收某个元素：未知的栏位、超过限制的文件、抓不到的网址。消息是模型自己的说法。
- 402 — `insufficient_quota`：余额用完。不要重试，先加值。
- 403 — 模型不在项目的允许清单上，不是密钥或余额的问题。
- 422 — `embedding_error`：这个 id 对你的项目不是以向量模型提供。用 `GET /v1/project/models` 核对。
- 429 — 被限流，或这个模型现在没有容量。依 `Retry-After` 重试。

## 下一步

- [模型探索](https://atptoken.ai/zh-cn/docs/models/) — 列出项目可呼叫的所有模型 id，含向量模型。
- [媒体模型](https://atptoken.ai/zh-cn/docs/media/) — 同一把密钥的图像、影片与语音生成。
- [点数](https://atptoken.ai/zh-cn/docs/credits/) — 计费 tokens 如何换算成点数。
