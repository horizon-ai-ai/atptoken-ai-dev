# 常见问题

> Source: https://atptoken.ai/zh-cn/docs/faq/

连接 Gateway、可呼叫哪些模型，以及用量如何计费的常见问题与简短解答。

## 连接 Gateway

### 有 MCP 伺服器吗？

有：`atptoken-api-docs`，网址 `https://mcp.atptoken.ai/mcp`。它让 Claude Code、Codex 等 agent 有 API 文件、即时查模型、送影片任务前的检查。加上它不需要密钥；只有「即时查模型」要带你的密钥。各工具的设定方式见[加入 ATP MCP 伺服器](https://atptoken.ai/zh-cn/docs/mcp/)。

### 我需要特别的 SDK 吗？

不用。官方 OpenAI、Anthropic 与 Google GenAI（`google-genai`）SDK 原样可用——把它们指向 Gateway base URL 并用项目（project） API 密钥即可。旧的 `google-generativeai` 已弃用。每个模型只走一个 SDK、一个入口；打错会回 `422`，消息会指名正确的入口。见 [Integrations](https://atptoken.ai/zh-cn/docs/agents/)。

### base URL 是什么？

Anthropic 与 Gemini 格式用 `https://api.atptoken.ai`（Gemini 另外要设 `apiVersion: "v1beta"`），OpenAI 格式用 `https://api.atptoken.ai/v1`。各 SDK 页会列出确切值。这个网域只服务 `/v1*` 与 `/omni/*`，打其他路径（例如 `/api`）会回 `404`。

### 可以串流回应吗？

可以，而且 `stream` 一定要明确送。`/v1/chat/completions` 与 `/v1/messages` 默认是 `true`（跟 OpenAI、Anthropic 官方相反）；`/v1/responses` 默认是 `false`。Gemini 没有 `stream` 栏位，要换成 `:streamGenerateContent` 端点。见 [OpenAI SSE](https://atptoken.ai/zh-cn/docs/sse-openai/) 与 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)。

## 模型与可用性

### 我的密钥能呼叫哪些模型？

只有它所属项目允许清单上的模型。完整清单用同一把密钥打 `GET /v1/project/models`，文字、媒体、向量模型都在里面。`GET /v1/models` 只是 OpenAI 的清单：只列 `/v1/chat/completions` 与 `/v1/responses` 收的 chat 模型，所以多数 `claude-*`（走 `/v1/messages`）、Gemini（在 `/v1beta/models`）、媒体与向量模型都不在上面。清单上没有，不代表不能用；项目真的没开权限时，建立请求会回 `403`，不收费。见 [模型查询](https://atptoken.ai/zh-cn/docs/models/)。

### 某个供应商挂掉会怎样？

每个模型由一个供应商池 服务，Gateway 会自动切换。若某模型的所有供应商都不可用，你会收到带 `Retry-After` 的 `503`。见 [供应商路由与备援](https://atptoken.ai/zh-cn/docs/provider-routing/)。

### 为什么 reasoning 模型回传 200 但内容是空的？

`max_tokens` 设太低了。推理模型（extended thinking）的思考会吃同一个额度；额度在产生可见输出前就用完，你会拿到空的 `200`——通常用量为零、也不会扣点数。把 `max_tokens` 调高到「思考+预期输出」都够用。见[常见回应](https://atptoken.ai/zh-cn/docs/errors/)。

### ATP Token 只有文字模型吗？

不是。目录还包含图像、影片、语音(TTS)与 embedding 模型。媒体只有非同步：建立任务、轮询，再在 24 小时内从签章网址下载。各模态的用途与计费方式见[媒体模型](https://atptoken.ai/zh-cn/docs/media/)。

## 计费与用量

### 怎么计费？点数可以退款吗？

用量以 input + output tokens 计量，并以点数支付(1 点数 = USD 0.01)。充值与点数皆不可退款。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) 与 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

### 我怎么看花了多少？

用量页依模型与密钥汇整点数与 tokens；请求记录提供每笔请求的稽核轨迹。计费以「请求」为单位，不是以「尝试」为单位：一个请求在记录里可能有好几列，不要加总。见 [用量与记录](https://atptoken.ai/zh-cn/docs/monitoring/) 与 [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/)。

## 下一步

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 建立一把项目密钥，送出第一个请求。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 用量怎么换算成点数、点数花在哪里。
