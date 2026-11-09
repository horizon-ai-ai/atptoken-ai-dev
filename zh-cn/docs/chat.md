# /v1/chat/completions

> Source: https://atptoken.ai/zh-cn/docs/chat/

`POST /v1/chat/completions`

用官方 `openai` SDK（Python 或 Node）呼叫这个端点，只要换 base URL。Request body 沿用 OpenAI 的 chat completions schema。`model` 必须是这个端点有服务的模型；[GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 列出的就是这些。

> **这里的 stream 默认是 true**
>
> 在 `/v1/chat/completions`，`stream` 默认是 `true`，和 OpenAI 官方 API 相反。不送的话，你会收到以 `data: [DONE]` 结尾的 SSE，而不是一个 JSON。请一律明确送 `stream`；下面的范例都送 `false`。

## 请求

把 `MODEL_ID` 换成 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的模型 ID。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
r = client.chat.completions.create(
    model="MODEL_ID",
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const r = await client.chat.completions.create({
  model: "MODEL_ID",
  stream: false,
  messages: [{ role: "user", content: "hi" }],
});
console.log(r.choices[0].message.content);
```

## 参数

必填只有 `model` 和 `messages`。下表是 OpenAI chat completions schema 常用的选填栏位。Gateway 会原样转送栏位，所以同一个栏位可能 A 模型收、B 模型拒，不要假设每个栏位每个模型都吃。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 来自 GET /v1/models 的模型 ID。 |
| messages | array · 必填 | 对话消息，每则为 { role, content }。`role` 可用 `system`、`developer`、`user`、`assistant`、`tool`。`content` 可以是字串，或 part 阵列（`text`、`image_url`、`input_audio`）。 |
| max_completion_tokens | integer | 最大输出 token 数。`max_tokens` 是旧名，仍可用。reasoning 模型的思考也吃这个额度——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| stream | boolean | 这个端点默认 `true`。送 `false` 会拿到一个 JSON。 |
| stream_options | object | 例如在串流结尾带 usage。见 [Server-Sent Events](https://atptoken.ai/zh-cn/docs/sse-openai/)。 |
| temperature / top_p | number | 取样。`temperature` 范围 0–2。 |
| stop | string or array | 停止序列。 |
| n | integer | 产生几个候选。 |
| seed | integer | 尽量重现同样结果。 |
| tools / tool_choice | array / object | 工具定义（`tools[].function.parameters`，JSON Schema）与模型怎么使用它们。 |
| parallel_tool_calls | boolean | 允许一次呼叫多个工具。 |
| response_format | object | JSON mode 或 JSON schema。 |
| reasoning_effort | string | 思考强度。 |
| logprobs / top_logprobs | boolean / integer | 输出 token 机率。 |
| frequency_penalty / presence_penalty | number | 重复惩罚，-2.0 到 2.0。 |
| logit_bias | object | 逐 token 偏置。 |
| metadata / user | object / string | 你自己的标记。 |
| audio / modalities | object / array | 语音输出。 |
| prompt_cache_key | string | 快取分组提示。每个模型都接受，但多数不生效，也没有回应栏位能告诉你有没有生效。 |

能不能吃多模态输入，由各模型决定。这个端点上的模型大多拒绝 `file` 型别的 content part；要传文件，见[文件](https://atptoken.ai/zh-cn/docs/files/)。

## 工具呼叫

Gateway 不会替你执行工具。一轮工具呼叫分三步：

1. 你送 `messages` 和 `tools`，模型回 `tool_calls`。
2. 你在自己的程式里执行工具。
3. 用 `role: "tool"` 的消息把结果送回去，以 `tool_call_id` 对应。

```
"messages": [
  {"role": "user", "content": "What is 2+2? Use the calc tool."},
  {"role": "assistant", "tool_calls": [
    {"id": "call_1", "type": "function",
     "function": {"name": "calc", "arguments": "{\"expr\":\"2+2\"}"}}
  ]},
  {"role": "tool", "tool_call_id": "call_1", "content": "4"}
]
```

`arguments` 是 JSON **字串**，不是物件，使用前要先解析。

## 回应

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

## /v1/responses

`POST /v1/responses` 是同一个 SDK 的另一个入口（OpenAI Responses API），不是另一种模型。body 和 chat completions 不同：

- 用 `input` 取代 `messages`。
- 系统提示放 `instructions`。
- 输出上限是 `max_output_tokens`。
- function tool 是扁平结构：`{type:"function", name, parameters}`。
- 不保存对话状态：`store` 和 `previous_response_id` 会被忽略，所以每一轮都要送完整的 `input`。

`/v1/responses` 的 `stream` 默认是 **`false`**，和 `/v1/chat/completions` 相反。程式在两者之间搬动时，串流行为会不声不响地反过来，所以两边都要明确送 `stream`。

## 最先会遇到的错误

开始输出前，请求依序检查：模型不在项目允许清单 → `403`；余额用完 → `402`；此刻没有可用容量 → `429`。

- 403 — 模型不在项目的允许清单内。不是密钥或余额的问题。
- 402 — `insufficient_quota`：余额用完。不要重试，先充值。
- 422 — 这个模型不在这个端点服务。消息会指名正确的端点。
- 429 — 限流，或这个模型此刻没有可用容量。依 `Retry-After` 等待。

拿到 `200` 不代表模型看到了你送的全部内容：少一则消息的请求依然合法、依然 `200`。要确认内容真的送到，在消息里放一个模型猜不到的值，再请它回答出来。

## 下一步

- [Server-Sent Events](https://atptoken.ai/zh-cn/docs/sse-openai/) — 用 `stream: true` 串流这个端点的回应。
- [OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai/) — 从官方 OpenAI SDK 呼叫这个端点。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么，包括内容为空的 `200`。
