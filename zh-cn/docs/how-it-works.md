# 运作方式

> Source: https://atptoken.ai/zh-cn/docs/how-it-works/

Gateway 位在你的 client 与上游模型 provider 之间。不论你用哪种 SDK 格式，每个请求都会经过相同的四个阶段。

## 1. 验证

Project API key 会先被验证，并在转送上游前移除 — provider 永远看不到你的 ATP key。缺失、被停用或过期的 key 会以 `401` 拒绝。见 [验证方式](https://atptoken.ai/zh-cn/docs/auth/)。

## 2. 授权模型

请求的模型必须在该 project 的 allowed list 上。若不在，会在送到任何 provider 前以 `403` 拒绝 — 模型存取权是设在 project、不是设在 key。见 [模型查询](https://atptoken.ai/zh-cn/docs/models/)。

## 3. 路由到 provider

Gateway 会从该模型设定的 provider pool 挑一个，遇到 provider 错误或逾时就 fail over 到另一个，因此同一个 model id 能跨 provider 保持稳定。见 [Provider routing & fallbacks](https://atptoken.ai/zh-cn/docs/provider-routing/)。

## 4. 计量与计费

Input 与 output tokens 会被计量，并以 credits 从该 project 余额扣款。余额耗尽时请求会以 `402` 拒绝。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

### Gateway 改变什么、又不改变什么

Gateway 转译验证与路由，但把你的 request 与 response body 维持在 SDK 本来就预期的形状。

| 帮你处理 | 维持不变 |
|---|---|
| Key 验证与 provider 验证 | Request body schema（依 SDK 格式） |
| 模型存取检查 | Response body schema |
| Provider 挑选与 fallback | 串流事件序列 |
| 计量与 credit 扣款 | 模型行为与输出 |

因为 wire format 原样通过，把既有的 OpenAI、Anthropic 或 Gemini 整合搬过来，通常只是改 base URL 与 key。

### 四个阶段再往下看

- [验证方式](https://atptoken.ai/zh-cn/docs/auth/)
  三种可接受的 key 放置位置，以及 `401` 到底代表什么。
- [模型查询](https://atptoken.ai/zh-cn/docs/models/)
  把 model id 写死之前，先列出这把 project key 能调用哪些模型。
- [Provider routing](https://atptoken.ai/zh-cn/docs/provider-routing/)
  pool 怎么排序，以及 Gateway 什么时候会切到下一个 provider。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)
  哪些东西会被计量，以及 project 余额用完时会发生什么事。

#### 延伸阅读

- [OpenAI API vs 企业 AI 闸道](https://atptoken.ai/zh-cn/blog/openai-api-vs-enterprise-ai-gateway/)
- [AI 闸道选型 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026/)
