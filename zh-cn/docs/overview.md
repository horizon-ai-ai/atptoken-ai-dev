# 总览

> Source: https://atptoken.ai/zh-cn/docs/overview/

ATP 是一个统一 API，让你通过单一端点存取多种 AI 模型，同时把供应商自动备援与计费集中在一处处理。

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/)
  六个步骤，从充值到在控制台看到第一笔请求。
- [API 参考](https://atptoken.ai/zh-cn/docs/chat/)
  端点、参数、回应与错误码。
- [SDK 与 coding agent](https://atptoken.ai/zh-cn/docs/agents/)
  把 OpenAI、Anthropic、Google SDK，或 Claude Code、Codex 指向 Gateway。
- [使用控制台](https://atptoken.ai/zh-cn/docs/console-setup/)
  设定组织、项目与密钥，再追踪用量与账单。

## 送出第一笔请求

把 `MODEL_ID` 换成 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的模型 ID，或从范例上方的模型选单挑一个。先把项目 API 密钥放进 `$ATP_API_KEY`；[快速开始](https://atptoken.ai/zh-cn/docs/quickstart/)有完整步骤。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

## 你会得到什么

- **一个端点、多种模型。** 用 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 查询，呼叫你的项目（project）允许的任一模型。
- **三种 wire format（请求格式）。** OpenAI、Anthropic 或 Google GenAI 格式原样可用——只换 base URL。
- **自动备援（fallback）。** 每个模型由一个供应商池服务，某个供应商降级时同一个模型 ID 仍能运作。见 [供应商路由与备援](https://atptoken.ai/zh-cn/docs/provider-routing/)。
- **单一账单。** 跨所有模型与供应商的用量都以点数计量。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## 三种接入方式

| 方式 | 适合 |
|---|---|
| API | 完整控制、任何语言、零相依 |
| SDK | 用你既有的 OpenAI / Anthropic / Google SDK，型别安全 |
| Coding agent | Claude Code、Codex 等支持上述格式的开发代理工具 |

## AI 成本与闸道相关文章

- [企业 AI 成本管理完整指南](https://atptoken.ai/zh-cn/blog/enterprise-ai-cost-management-guide/)
- [AI 闸道选型 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026/)
- [上线后 AI 账单为什么会炸](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live/)

## 下一步

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 建立一把项目密钥，六个步骤送出第一个请求。
- [运作方式](https://atptoken.ai/zh-cn/docs/how-it-works/) — 跟著一个请求走过验证、模型授权、路由与计量。
- [价格](https://atptoken.ai/zh-cn/docs/pricing-model/) — 看 input 与 output tokens 怎么换算成点数，而且没有月费。
