# 模型目录与访问控制：GET /v1/models 列出菜单，项目白名单决定能不能用（2026）

> 来源: https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control/
> 发表于: 2026-08-28 · 作者: hung-chien (AI 增长与品牌经理)

GET /v1/models 列出 LLM 平台提供哪些模型；模型白名单决定密钥能调用哪些。附请求与响应示例、403 的含义与白名单设计。

## 重点摘要

- 在 ATP Token，GET /v1/models 返回的是平台目录。密钥能调用什么由项目的允许模型清单决定，清单外的模型在接触任何供应商之前就会收到 403。
- OpenAI 用每个项目的 Model usage 设置做同一件事；OpenRouter 则用 guardrail 里的模型白名单。
- 白名单按工作负载设计，写明模型与标价，例如客服机器人只允许 claude-haiku-4-5 与 gemini-3-5-flash。

模型目录是平台能提供的模型 ID 清单，模型访问控制则是决定某个密钥能调用其中哪些 ID 的规则。在 ATP Token，`GET /v1/models` 返回目录，而项目的允许模型清单会在每次请求时检查，不符合的请求在联系任何供应商之前就返回 403。本文列出请求与响应、说明 403 的含义、对比 OpenAI 与 OpenRouter 的做法，并提供四份附标价的白名单模板。

## 两个不同的问题

| 问题 | ATP Token 在哪里回答 | 答案为否时 |
|---|---|---|
| 这个密钥有效吗？ | 认证 | 401 |
| 平台上有这个模型吗？ | [GET /v1/models](https://atptoken.ai/zh-cn/docs/models) | 清单里找不到这个 ID |
| 这个密钥的项目可以调用它吗？ | 项目的允许模型 | 403，在接触任何供应商之前 |
| 项目付得起吗？ | 项目的点数余额 | 402 |

顺序很重要。网关先验证密钥，再拿模型比对项目的允许清单，然后路由到供应商，最后按项目余额计量 token（[工作原理](https://atptoken.ai/zh-cn/docs/how-it-works)）。一个模型可能通过第二行，却卡在第三行。

## GET /v1/models 返回什么

请求使用你的项目密钥和 OpenAI 格式的 base URL：

```
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer atp-..."
```

响应是 OpenAI 风格的列表。每个 `id` 就是请求中 `model` 字段要填的字符串：

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

[模型发现文档](https://atptoken.ai/zh-cn/docs/models)写明这份列表不会按你的项目筛选。用它获取最新的 ID，不要从供应商仪表盘或博客文章里抄模型名称。也不要把它当成权限清单来读。

## 403 意味着什么

ATP Token 返回 403，表示密钥有效、模型 ID 也存在，但这个模型没有在密钥所属的项目中启用。[常见响应](https://atptoken.ai/zh-cn/docs/errors)页面只用一行描述：模型未在此项目启用。请求停在授权步骤，不会发到任何供应商。和所有 ATP 错误一样，响应带有 `request_id`，并采用你所调用 SDK 的错误格式。

典型情况：一位开发者在目录里看到 `claude-opus-4-8`，在功能分支把客服机器人换成它。客服机器人的项目只允许 claude-haiku-4-5 与 gemini-3-5-flash，所以 staging 第一笔请求就返回 403。这正是白名单该做的事。按 ATP 标价计算，2,000 token 的提示加 300 token 的回复，在 [claude-opus-4-8](https://atptoken.ai/zh-cn/models/claude-opus-4-8/)（每百万 token 输入 USD 5、输出 USD 25）需要 1.75 点，在 [claude-haiku-4-5](https://atptoken.ai/zh-cn/models/claude-haiku-4-5/)（USD 1 与 USD 5）只需 0.35 点，每条回复相差五倍。

由此得出两条客户端规则。不要重试 403，它每次都会以同样方式失败。把它连同请求 ID 记录下来，交给项目负责人，由对方修改代码里的模型，或请 Admin 放宽清单。

## OpenAI 与 OpenRouter 如何做同一件事

| 平台 | 模型规则放在哪里 | 粒度 |
|---|---|---|
| OpenAI API | 项目设置的 Limits 中的 Model usage（[Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)） | 每个项目 |
| OpenRouter | Guardrail 中的模型白名单（[guardrails](https://openrouter.ai/docs/guides/features/guardrails)） | 每位成员或每个密钥；多个 guardrail 同时适用时，只有所有 guardrail 都允许的模型可用 |
| ATP Token | 项目的允许模型（[工作区与项目](https://atptoken.ai/zh-cn/docs/resources)） | 每个项目，从不按密钥设置；每个项目至少一个模型 |

在 OpenAI，Model usage 设置和项目的每月花费上限、通知阈值放在一起。在 OpenRouter，同一个 guardrail 还能放花费上限与供应商白名单，以最严格的适用规则为准。在 ATP Token，允许清单和项目的点数分配放在一起，项目里的每个密钥两者都继承。

## 白名单设计：四个项目模板

| 项目 | 允许的模型 | ATP 标价，每百万 token（输入 / 输出） | 分配建议 |
|---|---|---|---|
| support-bot-prod | [claude-haiku-4-5](https://atptoken.ai/zh-cn/models/claude-haiku-4-5/)、[gemini-3-5-flash](https://atptoken.ai/zh-cn/models/gemini-3-5-flash/) | USD 1 / 5；USD 1.5 / 9 | 按回复量推算 |
| coding-agent | [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/)、[gpt-5.4](https://atptoken.ai/zh-cn/models/gpt-5.4/) | USD 3 / 15；USD 2.5 / 15 | 按团队分配，每周复核 |
| batch-classification | [deepseek-v4-flash](https://atptoken.ai/zh-cn/models/deepseek-v4-flash/)、qwen-3-7-flash | USD 0.2 / 0.4；USD 0.03 / 0.13（提示 32K 以内） | 按任务推算 |
| research-sandbox | claude-opus-4-8、[gpt-5.5](https://atptoken.ai/zh-cn/models/gpt-5.5/) | USD 5 / 25；USD 5 / 30 | 小额、固定 |

1. **从通过评测的最便宜模型开始**，再加一个来自第二家厂商的备选。同一个模型 ID 在不同供应商之间的故障切换，网关已经处理（[供应商路由](https://atptoken.ai/zh-cn/docs/provider-routing)）；第二个模型是给你想在代码里换模型时用的。在 Gemini 与 GPT 之间做选择，见 [Gemini vs GPT](https://atptoken.ai/zh-cn/compare/gemini-vs-gpt/)。
2. 前沿模型放在单独的项目，给小额分配。研究团队能用 Opus 与 GPT-5.5，客服机器人则不会只差一行配置就切过去。
3. 把放宽清单当作变更申请处理。管理资源是 Admin 的权限，Activity 日志会记录资源更新（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。
4. 每份白名单都搭配预算。允许的模型配上无上限的余额，账单一样会吓人（[AI API 花费上限对比](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)）。

## 在 ATP Token 上怎么设置

1. 在 Resources 页面创建项目并选择允许的模型（[工作区与项目](https://atptoken.ai/zh-cn/docs/resources)）。
2. 给项目拨点数，再从项目发密钥（[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys)）。
3. 调用 `GET /v1/models`，把精确的 ID 复制到配置文件。
4. 在 staging 对每个配置中的模型各发一笔测试请求。200 表示有权限；403 表示项目清单里没有这个模型。
5. 部署后在请求日志中按状态筛选，找出 403。

[快速开始：列出模型并发出第一笔请求](https://atptoken.ai/zh-cn/docs/quickstart)

## 延伸阅读

- [一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)
- [AI API 花费上限对比](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)
- [LLM 网关对比 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026)

## 常见问题

### GET /v1/models 只会显示我的密钥能用的模型吗？

在 ATP Token 不是这样。GET /v1/models 列出平台上所有可用的模型，不会按你的项目筛选。密钥能调用哪些模型，由项目的允许清单决定，并在每次请求时检查。

### 为什么 /v1/models 里有的模型，调用时却返回 403？

这个模型存在于平台上，但没有在你密钥所属的项目中启用。ATP Token 在验证密钥之后检查项目的允许清单，并在联系供应商之前以 403 拒绝。请改用允许的模型，或请项目 Admin 添加。

### 什么是模型白名单？

模型白名单是一个项目、密钥或成员被允许调用的模型 ID 清单。无论应用代码请求什么，其他模型的请求都会被平台拒绝。

### 可以限制 OpenAI 项目能用哪些模型吗？

可以。在 OpenAI API 平台，项目的 Limits 设置里有 Model usage，可选择该项目能用哪些模型，旁边就是每月花费上限与通知阈值。

### ATP Token 的模型权限是按密钥还是按项目设置？

按项目。同一个项目的每个密钥都继承相同的允许模型，而且每个项目至少要允许一个模型。

---

Tags: 模型白名单, LLM 访问控制, AI 网关, ATP
