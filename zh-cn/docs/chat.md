# /v1/chat/completions

> Source: https://atptoken.ai/zh-cn/docs/chat/

`POST /v1/chat/completions`

用任何 OpenAI SDK client 呼叫这个 endpoint。Request body 完全沿用 OpenAI 的 chat completions schema。`model` 栏位必须是 `GET /v1/models` 回传的值。

| Field | Type | Description |
|---|---|---|
| model | string · required | 来自 GET /v1/models 的 model id。 |
| messages | array · required | 对话讯息，每则为 { role, content }。 |
| max_tokens | integer | 最大输出 token 数。reasoning 模型的思考也吃这个额度——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| temperature | number | 取样温度，0–2。 |
| stream | boolean | 以 SSE chunk 串流回应。 |
| tools | array | Tool/function 定义（OpenAI tool schema）。 |

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
