# AI API 花费上限对比：OpenAI、Anthropic、OpenRouter、Vercel 与 ATP Token（2026）

> 来源: https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work/
> 发表于: 2026-08-12 · 作者: hung-chien (AI 增长与品牌经理)

AI API 花费上限对比：OpenAI 用量限制、Claude 工作区上限、OpenRouter、Vercel 与 ATP Token 达到上限时分别返回什么，附一份实际预算拆分。

## 重点摘要

- 同样叫花费上限，行为各不相同：OpenAI 硬上限返回 429，Anthropic 工作区上限返回 400，Vercel 与 OpenRouter 密钥上限返回 402，OpenRouter guardrail 返回 403。
- 重置周期也不同：OpenAI 与 Anthropic 按月重置，OpenRouter 与 Vercel 可选每日、每周或每月，ATP Token 的项目分配不会重置，直到你再拨点数。
- 按工作负载拆预算：每月 USD 2,000 等于 200,000 点，分给生产环境客服机器人、staging 项目、coding agent 沙箱，并保留一笔未分配的备用额度。

AI API 花费上限，是一个密钥、项目、工作区或组织在平台停止处理其请求之前，最多能花掉的模型用量。上限设在哪一层，和金额本身一样重要：下面对比的五个地方，在范围、重置周期，以及达到上限时代码收到的 HTTP 状态码上都不一样。本文整理截至 2026 年 10 月的情况，最后用 ATP Token 点数拆一份每月 USD 2,000 的预算，算式全部列出。

## AI API 花费上限一览

| 设置位置 | 范围 | 重置 | 达到上限时 | 状态码 |
|---|---|---|---|---|
| [OpenAI API](https://developers.openai.com/api/docs/guides/rate-limits) | 组织或项目 | 每月 | 花费提醒：只通知，流量照常。硬上限：受影响的请求失败 | 429 |
| [Anthropic Console](https://platform.claude.com/docs/en/api/rate-limits) | 组织或工作区（工作区上限不能超过组织上限） | 每月 | 请求被拒，直到调高上限或当月结束 | 自定义上限 400；等级上限 429 |
| [OpenRouter guardrails](https://openrouter.ai/docs/guides/features/guardrails) | 每位成员或每个密钥 | 每日、每周或每月 | 请求被拒 | 403 |
| [OpenRouter 密钥点数上限](https://openrouter.ai/docs/api-reference/limits) | 每个密钥 | 每日、每周、每月或不重置 | 请求被拒 | 402 |
| [Vercel AI Gateway 预算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets) | 团队、项目、密钥或团队成员 | 每日、每周、每月或不重置 | 软上限：跨过上限的那一笔会完成，之后的请求被拒 | 402 |
| [ATP Token](https://atptoken.ai/zh-cn/docs/credits) | 项目，点数由组织、工作区一路拨到项目 | 不重置；分配会一直保留，直到花完或被移走 | 项目余额用尽后请求被拒 | 402 |

工程师最容易忽略的是状态码这一列，而它决定了客户端接下来怎么做。429 看起来像普通的速率限制，多数 SDK 会自动重试。Anthropic 文档特别说明，花费等级上限的 429 不带 `retry-after` 头，在恢复之前重试都会失败。402 或 400 重试也不会成功。客户端应该读取错误内容，然后停下来。

## 各平台如何执行花费上限

### OpenAI：项目花费上限

OpenAI 建议把 staging 与生产环境分成不同项目，并且可以[为每个项目设置自定义的速率与花费上限](https://developers.openai.com/api/docs/guides/production-best-practices)。在项目的 Limits 设置中，可以设置每月花费上限、通知阈值，以及该项目能用哪些模型（[OpenAI Help Center](https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform)）。

花费提醒会发通知，流量照常。硬性花费上限会让受影响的请求返回 429。两者之上还有用量等级：Tier 1 每月 USD 100，Tier 5 每月 USD 200,000。需要注意的是状态码共用。处理速率限制的重试循环，如果不检查错误内容，会一直调用一个预算已经用完的项目。

### Anthropic Console：工作区花费上限

Claude Console 的[工作区](https://platform.claude.com/docs/en/manage-claude/workspaces)各自有每月花费上限与速率上限，只能设得比组织低，不能更高。API 密钥可以限定在单个工作区。Default Workspace 无法设置上限，所以需要被管住的密钥要放在具名的工作区。

达到你自己设置的上限时，请求返回 HTTP 400（`invalid_request_error`），信息里会写明何时恢复。等级上限（Start 每月 USD 500、Build USD 1,000、Scale USD 200,000）则返回 429，用量暂停到下个月 1 日 00:00 UTC。Console 自动创建的 Claude Code 工作区，是唯一支持每位用户每月花费上限的工作区。

### OpenRouter：guardrails 与单个密钥点数上限

OpenRouter 有两套机制。Guardrails 由组织管理员针对成员或密钥设置，可以带一个每日、每周或每月重置的美元花费上限；超出的请求收到 403。Guardrail 也能放模型白名单与供应商白名单，多个 guardrail 同时适用时，以最严格的规则为准。

单个密钥点数上限所有套餐都能用。每个密钥有 `limit` 与 `limit_reset`（每日、每周、每月或不重置），在 UTC 午夜重置。额度用完的密钥返回 402。工作区级别预算则是 Enterprise 功能（[OpenRouter 博客](https://openrouter.ai/blog/insights/governing-team-ai-spend/)）。

### Vercel AI Gateway：叠加的预算

Vercel 的预算有四种范围（团队、项目、API 密钥、团队成员），并且会叠加，一笔请求必须通过范围内的每一个预算。重置周期可选每日、每周、每月或不重置，均以 UTC 计。超出预算返回 402 与 `quota_for_entity_exceeded`，信息会写出是哪个范围用完。

Vercel 把预算定位为软上限：检查发生在每笔请求开始时，所以跨过上限的那一笔仍会完成。可选的邮件提醒在 50%、75%、100% 触发。有两个细节容易踩坑：API 密钥的花费永远不会计入项目预算（项目预算只看该项目部署的 OIDC token），BYOK 的花费也不计入任何预算。

### ATP Token：每个项目的预付分配

在 ATP Token，上限就是钱本身。点数（1 点 = USD 0.01）由组织拨到工作区、再拨到项目，每个密钥都从自己项目的余额扣。项目只能花掉分配给它的额度。余额用尽时，网关在计量阶段以 402 拒绝请求（[工作原理](https://atptoken.ai/zh-cn/docs/how-it-works)）。花费超过分配额度的项目会被标记为 In debt，直到补足为止。

这里没有重置周期。按量付费点数不会过期，没用完的分配会留到下个月。所以月度预算需要每月做一次分配，或使用项目自动充值：按量付费的项目在余额低于阈值时自动补点，受单次扣款上限与每月扣款上限约束。开启自动充值后，真正的天花板是那个每月扣款上限。

## 团队愿意遵守的上限设计原则

1. **每个工作负载分开设上限。** 每个生产服务一个项目，staging 一个，每个沙箱一个。组织级别的总上限一触发，所有产品会一起停，包括正常运行的那些。密钥部分见[一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)。
2. 在客户端代码里把预算错误当作终止状态。402、Anthropic 的 400 上限错误、花费上限导致的 429，都对应到“停止并通知负责人”，不要套用指数退避重试。
3. 每个上限都从单位成本推算。每笔请求的 token 数乘以模型费率，再乘以预估量，得到一个能向财务解释、流量变化时也能调整的数字。
4. 在最上层保留未分配的备用额度。生产环境如果在 27 号见底，管理员几分钟内就能拨点过去，不必动 staging。
5. 每周对照一次 Allocated 与 Consumed。ATP Token 的[用量页面](https://atptoken.ai/zh-cn/docs/spend)在每一层都同时显示两者。想要自动告警的话，可以通过 [Console API](https://atptoken.ai/zh-cn/docs/console-api-usage) 轮询项目实时余额，推送到你自己的频道。

## 实际算一次：每月 USD 2,000 的 AI 预算换成点数

USD 2,000 等于 200,000 点。以下是拆给三个工作负载加一笔备用额度的一种做法。

| 项目 | 工作区 | 允许的模型 | 分配 | 可以支撑 |
|---|---|---|---|---|
| support-bot-prod | Production | [claude-haiku-4-5](https://atptoken.ai/zh-cn/models/claude-haiku-4-5/) | 140,000 点（USD 1,400） | 约 400,000 条回复 |
| support-bot-staging | Pre-production | claude-haiku-4-5 | 10,000 点（USD 100） | 约 28,500 次测试调用 |
| coding-agent-sandbox | Engineering | [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/) | 30,000 点（USD 300） | 约 23 个开发者工作日 |
| 未分配备用额度 | 组织 | 无 | 20,000 点（USD 200） | 紧急补点 |

客服机器人。claude-haiku-4-5 的 ATP 标价是每百万输入 token USD 1、每百万输出 token USD 5。一条典型回复用 2,000 个输入 token、300 个输出 token，成本是 2,000 × 1 / 1,000,000 + 300 × 5 / 1,000,000 = USD 0.0035，也就是 0.35 点。140,000 点 ÷ 0.35 = 每月 400,000 条回复，约每天 13,300 条。

整个周末都在跑的 staging 任务。假设一个重试 bug 每秒发 5 次请求，每次同样 0.35 点，相当于每秒烧掉 1.75 点，10,000 点的 staging 分配大约撑 10,000 ÷ 1.75 ≈ 5,700 秒，约 95 分钟。之后 staging 收到 402，生产环境照常回复客户。如果没有拆开，同一个循环从周五 18:00 跑到周一 09:00（63 小时，226,800 秒），会花掉 226,800 × 1.75 = 396,900 点，几乎是整月预算的两倍。

Coding agent。Anthropic 公布的 Claude Code 平均成本是[每位开发者每个活跃日约 USD 13](https://code.claude.com/docs/en/costs)。按这个平均值，USD 300 约可支撑 23 个开发者工作日，大约是一位开发者一个月的工作日。沙箱在下午撞到 402 时，先看那个 session 在做什么，再决定要不要补点。为什么 agent 每项任务比单次调用贵，见[什么是 agent 税](https://atptoken.ai/zh-cn/blog/what-is-the-agent-tax)。

下个月 1 日不会重置任何东西。如果客服机器人用掉 120,000 点，它还剩 20,000 点；再拨 120,000 点就回到 140,000。

## 在 ATP Token 上怎么设置

1. 创建 Team 组织，再到 Resources 页面创建工作区（Production、Pre-production、Engineering）（[设置组织](https://atptoken.ai/zh-cn/docs/console-setup)）。
2. 创建每个项目并选择允许的模型，每个项目至少一个（[工作区与项目](https://atptoken.ai/zh-cn/docs/resources)）。
3. 沿着树状结构分配点数：组织、工作区、项目。备用额度留在组织层，不要分出去。
4. 每个项目发一个密钥，密钥继承该项目的模型与余额（[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys)）。
5. 在客户端把 402 视为“预算用尽”，并通知项目负责人（[常见响应](https://atptoken.ai/zh-cn/docs/errors)）。

[设置有预算上限的团队](https://atptoken.ai/zh-cn/docs/cb-budget-caps)

## 延伸阅读

- [为什么 AI 账单上线后会爆](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live)
- [一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)
- [Coding agent 成本控制清单](https://atptoken.ai/zh-cn/blog/coding-agents-cost-control-checklist)

## 常见问题

### OpenAI 的用量限制有哪些？

有两种。用量等级（usage tier）为组织设定每月上限，Tier 1 为每月 USD 100，Tier 5 为 USD 200,000；此外你可以为组织或单个项目设置自己的花费上限。花费提醒只发通知，流量照常；硬性花费上限会让受影响的请求返回 429。

### Claude API 可以设置花费上限吗？

可以。在 Claude Console 可为组织和每个工作区设置每月花费上限，工作区上限不能高于组织上限，Default Workspace 无法设置。达到自己设置的上限时，请求返回 HTTP 400（invalid_request_error），直到调高上限或进入下个月。

### AI API 密钥达到花费上限时会怎样？

取决于平台。OpenAI 硬上限返回 429，Anthropic 自定义上限返回 400，Vercel AI Gateway 预算与 OpenRouter 单个密钥点数上限返回 402，OpenRouter guardrail 预算返回 403，ATP Token 在项目余额用尽时返回 402。重试逻辑应把这些都当作停止信号。

### ATP Token 的花费上限会每月重置吗？

不会。ATP Token 项目只能花掉分配给它的点数，而按量付费点数不会过期，没用完的分配会留到下个月。要做月度预算，就每月重新分配一次，或开启项目自动充值并设置每月扣款上限。

### staging 和实验应该和生产环境共用 AI 预算吗？

不应该。为 staging 和沙箱各开一个项目或工作区，给小额上限。staging 的重试循环会先撞到自己的上限而停下，生产环境继续服务。

---

Tags: AI API 花费上限, OpenAI 用量限制, AI 预算, ATP
