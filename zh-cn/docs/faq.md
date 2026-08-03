# 常见问题

> Source: https://atptoken.ai/zh-cn/docs/faq/

### 我需要特别的 SDK 吗？

不用。Gateway 相容 OpenAI、Anthropic 与 Google GenAI SDK — 把它们指向 Gateway base URL 并用 project API key 即可。见 [Integrations](https://atptoken.ai/zh-cn/docs/agents/)。

### base URL 是什么？

Anthropic 与 Gemini 格式用 `https://api.atptoken.ai`,OpenAI 格式用 `https://api.atptoken.ai/v1`。各 SDK 页会列出确切值。

### 我的 key 能呼叫哪些模型？

只有它所属 project 的 allowed list 上的模型。[GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 列出平台提供的清单；存取权在 request time 依 project 强制检查 — 所以清单是选单，不是 key 的权限。

### 可以串流回应吗？

可以。设 `stream: true`,Gateway 会以对应你 SDK 的格式串流 SSE。见 [OpenAI SSE](https://atptoken.ai/zh-cn/docs/sse-openai/) 与 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)。

### 某个 provider 挂掉会怎样？

每个模型由一个 provider pool 服务，Gateway 会自动 fail over。若某模型的所有 provider 都不可用，你会收到带 `Retry-After` 的 `503`。见 [Provider routing](https://atptoken.ai/zh-cn/docs/provider-routing/)。

### 怎么计费？credits 可以退款吗？

用量以 input + output tokens 计量，并以 credits 支付(1 credit = USD 0.01)。充值与 credits 皆不可退款。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) 与 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

### 我怎么看花了多少？

Usage 页依模型与 key 汇整 credits 与 tokens；request logs 提供每笔请求的稽核轨迹。见 [用量与纪录](https://atptoken.ai/zh-cn/docs/monitoring/) 与 [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/)。

### 为什么 reasoning 模型回传 200 但内容是空的？

`max_tokens` 设太低了。reasoning(extended thinking)模型的思考会吃同一个额度；额度在产生可见输出前就用完，你会拿到空的 `200`——通常用量为零、也不会扣 credits。把 `max_tokens` 调高到「思考+预期输出」都够用。见[常见响应](https://atptoken.ai/zh-cn/docs/errors/)。

### ATP Token 只有文本模型吗？

不是。目录还包含图像、视频、语音(TTS)与 embedding 模型。各模态的用途与计费方式见[媒体模型](https://atptoken.ai/zh-cn/docs/media/)。
