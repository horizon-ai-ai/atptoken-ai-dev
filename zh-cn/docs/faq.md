# 常见问题

> Source: https://atptoken.ai/zh-cn/docs/faq/

连接 Gateway、可呼叫哪些模型，以及用量如何计费的常见问题与简短解答。

## 连接 Gateway

### 我需要特别的 SDK 吗？

不用。Gateway 相容 OpenAI、Anthropic 与 Google GenAI SDK——把它们指向 Gateway base URL 并用项目（project） API 密钥即可。见 [Integrations](https://atptoken.ai/zh-cn/docs/agents/)。

### base URL 是什么？

Anthropic 与 Gemini 格式用 `https://api.atptoken.ai`,OpenAI 格式用 `https://api.atptoken.ai/v1`。各 SDK 页会列出确切值。

### 可以串流回应吗？

可以。设 `stream: true`,Gateway 会以对应你 SDK 的格式串流 SSE。见 [OpenAI SSE](https://atptoken.ai/zh-cn/docs/sse-openai/) 与 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)。

## 模型与可用性

### 我的密钥能呼叫哪些模型？

只有它所属项目的 allowed list 上的模型。[GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 列出平台提供的清单；存取权在 request time 依项目强制检查——所以清单是选单，不是密钥的权限。

### 某个供应商挂掉会怎样？

每个模型由一个供应商池 服务，Gateway 会自动切换。若某模型的所有供应商都不可用，你会收到带 `Retry-After` 的 `503`。见 [供应商路由与备援](https://atptoken.ai/zh-cn/docs/provider-routing/)。

### 为什么 reasoning 模型回传 200 但内容是空的？

`max_tokens` 设太低了。推理模型（extended thinking）的思考会吃同一个额度；额度在产生可见输出前就用完，你会拿到空的 `200`——通常用量为零、也不会扣点数。把 `max_tokens` 调高到「思考+预期输出」都够用。见[常见回应](https://atptoken.ai/zh-cn/docs/errors/)。

### ATP Token 只有文字模型吗？

不是。目录还包含图像、影片、语音(TTS)与 embedding 模型。各模态的用途与计费方式见[媒体模型](https://atptoken.ai/zh-cn/docs/media/)。

## 计费与用量

### 怎么计费？点数可以退款吗？

用量以 input + output tokens 计量，并以点数支付(1 点数 = USD 0.01)。充值与点数皆不可退款。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) 与 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

### 我怎么看花了多少？

用量页依模型与密钥汇整点数与 tokens；请求记录提供每笔请求的稽核轨迹。见 [用量与记录](https://atptoken.ai/zh-cn/docs/monitoring/) 与 [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/)。

## 下一步

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 建立一把项目密钥，送出第一个请求。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 用量怎么换算成点数、点数花在哪里。
