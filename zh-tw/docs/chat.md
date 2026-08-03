# /v1/chat/completions

> Source: https://atptoken.ai/zh-tw/docs/chat/

`POST /v1/chat/completions`

用任何 OpenAI SDK client 呼叫這個 endpoint。Request body 完全沿用 OpenAI 的 chat completions schema。`model` 欄位必須是 `GET /v1/models` 回傳的值。

| Field | Type | Description |
|---|---|---|
| model | string · required | 來自 GET /v1/models 的 model id。 |
| messages | array · required | 對話訊息，每則為 { role, content }。 |
| max_tokens | integer | 最大輸出 token 數。reasoning 模型的思考也吃這個額度——設太低會拿到內容為空的 `200`（見[錯誤](https://atptoken.ai/zh-tw/docs/errors/)）。 |
| temperature | number | 取樣溫度，0–2。 |
| stream | boolean | 以 SSE chunk 串流回應。 |
| tools | array | Tool/function 定義（OpenAI tool schema）。 |

#### Response

```
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "model": "<model>",
  "choices": [
    {
      "index": 0,
      "message": { "role": "assistant", "content": "..." },
      "finish_reason": "stop"
    }
  ],
  "usage": { "prompt_tokens": 9, "completion_tokens": 12, "total_tokens": 21 }
}
```
