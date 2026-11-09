# /v1/messages

> Source: https://atptoken.ai/zh-cn/docs/messages/

`POST /v1/messages`

`POST /v1/messages` 接受 Anthropic Messages 请求。官方 `anthropic` SDK（Python 或 Node）不用改：把 `base_url` 设成 `https://api.atptoken.ai`，`api_key` 直接填 ATP 密钥。SDK 会用 `x-api-key` 送出，Gateway 接受这个 header。

> **这个端点有三件事一定要对**
>
> 1. `max_tokens` 在这里是**必填**，`/v1/chat/completions` 不是。从 OpenAI SDK 搬过来最常漏这个。
> 2. 要带 `anthropic-version` header，值照下面 curl 范例。用 SDK 会自动带。
> 3. `stream` 默认是 **`true`**，和 Anthropic 官方 API 相反。不送的话会收到 SSE，而不是一个 JSON。请一律明确送 `stream`。

## 请求

用项目开放的模型 ID。大部分 `claude-*` 模型在这里服务，**不在** `GET /v1/models` 里；完整清单请用 [GET /v1/project/models](https://atptoken.ai/zh-cn/docs/models/)。

```curl
curl https://api.atptoken.ai/v1/messages \
  -H "x-api-key: $ATP_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model from GET /v1/project/models>",
    "max_tokens": 256,
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
import os
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key=os.environ["ATP_API_KEY"])
msg = client.messages.create(
    model="<model from GET /v1/project/models>",
    max_tokens=256,
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

```Node.js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ baseURL: "https://api.atptoken.ai", apiKey: process.env.ATP_API_KEY });
const msg = await client.messages.create({
  model: "<model from GET /v1/project/models>",
  max_tokens: 256,
  stream: false,
  messages: [{ role: "user", content: "hi" }],
});
console.log(msg.content[0].text);
```

Anthropic SDK 的 `models.list()` 会去打 `/v1/models`。格式相容，所以不会报错，只是清单比较短：大部分 `claude-*` 模型不在里面。请改用 `GET /v1/project/models`。

## 参数

必填：`model`、`max_tokens`、`messages`。Gateway 会原样转送栏位，所以同一个栏位可能 A 模型收、B 模型拒。

| Field | Type | Description |
|---|---|---|
| model | string · 必填 | 项目开放的模型 ID（见 GET /v1/project/models）。 |
| max_tokens | integer · 必填 | 最大输出 token 数。开 extended thinking 时思考预算也算在内——设太低会拿到内容为空的 `200`（见[错误](https://atptoken.ai/zh-cn/docs/errors/)）。 |
| messages | array · 必填 | 对话轮次，每则为 { role, content }。`content` 可以是字串，或内容区块阵列（`text`、`image` 等）。 |
| system | string or array | 系统提示，字串或文字区块阵列皆可。放在最上层，不放在 `messages` 里。 |
| stream | boolean | 这个端点默认 `true`。送 `false` 会拿到一个 JSON。 |
| temperature / top_p / top_k | number | 取样。`temperature` 范围 0–1。 |
| stop_sequences | array of strings | 停止序列。 |
| tools / tool_choice | array / object | 工具定义用 `input_schema`，不是 OpenAI 的 `function.parameters`。 |
| thinking | object | 延伸思考（extended thinking）。 |
| output_config | object | 例如 `{"effort": "high"}`。 |
| cache_control | object | 放在最上层时，会自动落在最后一个可快取的区块上。 |
| metadata | object | 你自己的标记。 |
| container | object | 执行环境（程式码执行 / Skills）。 |
| diagnostics | object | 快取诊断。 |
| inference_geo | string | 指定推论地区。 |
| service_tier | string | `auto` 或 `standard_only`。 |

## 工具呼叫

工具结果要放在 **`user`** 消息里，用 `tool_result` 区块送回，不是 `role: "tool"`。以 `tool_use_id` 对应。模型回的 `tool_use.input` 是物件，不是字串。

```
{"role": "assistant", "content": [
  {"type": "tool_use", "id": "toolu_abc", "name": "get_weather", "input": {"location": "Paris"}}
]},
{"role": "user", "content": [
  {"type": "tool_result", "tool_use_id": "toolu_abc", "content": "72°F and sunny"}
]}
```

如果在这里送 OpenAI 的 `role: "tool"`，Gateway 会原样转送。有的模型读得到，有的回 `200` 却当作没收到。请用这个端点自己的写法。

## 提示快取

把 `cache_control: {"type": "ephemeral"}` 放在稳定前缀的**最后一个区块**上；或把 `cache_control` 放在 body 最上层，它会自动落在最后一个可快取的区块。要 1 小时 TTL 就用 `{"type": "ephemeral", "ttl": "1h"}`。有没有命中，看 `usage.cache_read_input_tokens` 和 `usage.cache_creation_input_tokens`。

快取是比对前缀，顺序是 `tools` → `system` → `messages`；前缀里任何一个 byte 变了，后面全部失效。稳定的内容放前面，每次都变的（时间戳、逐请求 id）放在最后一个 `cache_control` 之后。

`cache_control` 不能放在 `tool_result.content` 里的区块上，要放就放在 `tool_result` 本身，否则请求会被拒绝。

## 计算 token

`POST /v1/messages/count_tokens` 收 `messages`（可选 `model`、`system`、`tools`），回 `{"input_tokens": <n>}`。不计费，也不串流。

## 下一步

- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — 带 `stream: true` 时收到的事件序列
- [Anthropic SDK](https://atptoken.ai/zh-cn/docs/sdk-anthropic/) — 用官方 SDK 呼叫这个端点
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么
