# 运作方式

> Source: https://atptoken.ai/zh-cn/docs/how-it-works/

Gateway 位在你的程式 与上游模型供应商之间。不论你用哪种 SDK 格式，每个请求都会经过相同的四个阶段。

## 请求经过的路径

**一个请求经过 Gateway**

1. 你的程式 — `atp-…` 密钥 — OpenAI、Anthropic 或 Gemini 格式
2. 验证 — 密钥检查 — 缺失、停用或过期回 `401`
3. 授权模型 — 项目 allowed list — 模型不在清单上回 `403`
4. 路由到供应商 — 自动备援 — 遇到供应商错误或逾时就切换
5. 计量与计费 — 点数 — 余额耗尽回 `402`
6. 上游供应商 — 看不到你的 ATP 密钥

## 1. 验证

项目（project） API 密钥会先被验证，并在转送上游前移除——供应商永远看不到你的 ATP 密钥。缺失、被停用或过期的密钥会以 `401` 拒绝。见 [验证方式](https://atptoken.ai/zh-cn/docs/auth/)。

## 2. 授权模型

请求的模型必须在该项目的 allowed list 上。若不在，会在送到任何供应商前以 `403` 拒绝——模型存取权是设在项目、不是设在密钥。见 [模型查询](https://atptoken.ai/zh-cn/docs/models/)。

## 3. 路由到供应商

Gateway 会从该模型设定的供应商池 挑一个，遇到供应商错误或逾时就切换到另一个，因此同一个模型 ID 能跨供应商保持稳定。见 [供应商路由与备援](https://atptoken.ai/zh-cn/docs/provider-routing/)。

## 4. 计量与计费

Input 与 output tokens 会被计量，并以点数从该项目余额扣款。余额耗尽时请求会以 `402` 拒绝。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## Gateway 改变什么、又不改变什么

Gateway 转译验证与路由，但把你的 request 与 response body 维持在 SDK 本来就预期的形状。

| 帮你处理 | 维持不变 |
|---|---|
| 密钥验证与供应商验证 | Request body schema（依 SDK 格式） |
| 模型存取检查 | Response body schema |
| 供应商挑选与自动备援（fallback） | 串流事件序列 |
| 计量与点数扣款 | 模型行为与输出 |

因为 wire format 原样通过，把既有的 OpenAI、Anthropic 或 Gemini 整合搬过来，通常只是改 base URL 与密钥。

## 四个阶段再往下看

- [验证方式](https://atptoken.ai/zh-cn/docs/auth/)
  三种可接受的密钥放置位置，以及 `401` 到底代表什么。
- [模型查询](https://atptoken.ai/zh-cn/docs/models/)
  把模型 ID 写死之前，先列出这把项目密钥能呼叫哪些模型。
- [供应商路由与备援](https://atptoken.ai/zh-cn/docs/provider-routing/)
  供应商池怎么排序，以及 Gateway 什么时候会切到下一个供应商。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)
  哪些东西会被计量，以及项目余额用完时会发生什么事。

## 下一步

- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 通过 Gateway 送出第一个请求。
- [OpenAI API vs 企业 AI 闸道](https://atptoken.ai/zh-cn/blog/openai-api-vs-enterprise-ai-gateway/) — 直接呼叫供应商与经过闸道的差别。
- [AI 闸道选型 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026/) — 各家 AI 闸道的比较。
