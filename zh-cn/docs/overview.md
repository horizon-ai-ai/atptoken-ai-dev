# 总览

> Source: https://atptoken.ai/zh-cn/docs/overview/

ATP 是一个统一 API，让你通过单一 endpoint 存取多种 AI 模型，同时把 provider fallback 与计费集中在一处处理。把任何 OpenAI、Anthropic 或 Gemini 风格的 client 指向 Gateway，再以 credits 支付用量即可。

#### 你会得到什么

- **一个 endpoint、多种模型。** 用 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 查询，呼叫你的 project 允许的任一模型。
- **三种 wire format。** OpenAI、Anthropic 或 Google GenAI 格式原样可用 — 只换 base URL。
- **自动 fallback。** 每个模型由一个 provider pool 服务，某个 provider 降级时同一个 model id 仍能运作。见 [Provider routing](https://atptoken.ai/zh-cn/docs/provider-routing/)。
- **单一帐单。** 跨所有模型与 provider 的用量都以 credits 计量。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

#### 三种接入方式

| 方式 | 适合 |
|---|---|
| API | 完整控制、任何语言、零相依 |
| SDKs | 用你既有的 OpenAI / Anthropic / Google SDK，型别安全 |
| Coding agents | Claude Code、Codex 等会说 wire format 的 agent |

#### 从这里开始

第一次用 ATP？先跑一遍 [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/)，再读 [How it works](https://atptoken.ai/zh-cn/docs/how-it-works/) 了解请求生命周期。准备好整理 key 与预算时，见 [设定你的 organization](https://atptoken.ai/zh-cn/docs/console-setup/)。

#### 延伸阅读

- [企业 AI 成本管理完整指南](https://atptoken.ai/zh-cn/blog/enterprise-ai-cost-management-guide/)
- [AI 闸道选型 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026/)
- [上线后 AI 账单为什么会炸](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live/)

## 后续步骤

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 创建一把 project key，四个步骤发出第一个请求。
- [How it works](https://atptoken.ai/zh-cn/docs/how-it-works/) — 跟着一个请求走完验证、模型授权、路由与计量。
- [价格](https://atptoken.ai/zh-cn/docs/pricing-model/) — 了解 input 与 output tokens 如何换算成 credits，而且没有月费。
