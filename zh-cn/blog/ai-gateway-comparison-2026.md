# LLM 网关对比 2026：OpenRouter、Vercel AI Gateway、LiteLLM、Portkey、Helicone 与 ATP Token

> 来源: https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026/
> 发表于: 2026-08-21 · 作者: hung-chien (AI 增长与品牌经理)

LLM 网关是做什么的，以及截至 2026 年 10 月，六个网关在部署方式、计费、消费上限、模型白名单和 API 格式上的差异。

## 重点摘要

- LLM 网关让应用用一个 API 调用多家模型，同时处理密钥、供应商路由与故障切换、请求日志和消费上限。
- 到 2026 年，大多数网关都有预算和日志。真正的区别在于：网关部署在哪里、怎么付费、预算绑定在什么单位上，以及上限是硬还是软。
- 按约束条件选：必须自建（LiteLLM、Portkey 或 Helicone 开源版）、要最大的模型目录（OpenRouter）、部署在 Vercel（Vercel AI Gateway）、要每个项目预付预算并单独设置模型白名单（ATP Token）。

LLM 网关是位于应用和模型供应商之间的服务：代码只对一个 API 调用多家模型，密钥、路由与故障切换、请求日志和消费上限由网关处理。本文用同一份清单对比 2026 年团队常考虑的六个网关，每一项价格和功能都附上该厂商截至 2026 年 10 月的官方文档链接。

## LLM 网关做哪些事

按请求经过的顺序，一共五件事：

1. 一个 API 调用多家模型。代码对同一个 base URL 发送熟悉的格式（通常是 OpenAI 格式），换模型只改 `model` 字段。
2. 鉴权和密钥。网关签发自己的密钥，供应商凭证不必放进应用。
3. 访问规则。决定这个密钥能不能调用这个模型。
4. 路由与故障切换。为模型选择供应商，失败时改发到其他供应商。
5. 计量、日志和上限。逐条记录 token 和费用，预算用完就拦截。

在 ATP Token 上，这几个环节对应可以实测的状态码：密钥错误 401、模型不在项目允许清单 403、供应商失败 502 或 503、项目点数用完 402（[运作方式](https://atptoken.ai/zh-cn/docs/how-it-works)、[错误](https://atptoken.ai/zh-cn/docs/errors)）。

## 六个网关一览

| | 部署在哪里 | 你付的钱 | 预算绑定在 | 达到上限时 | 模型白名单 | API 格式 |
|---|---|---|---|---|---|---|
| [OpenRouter](https://openrouter.ai/pricing) | 托管 | 供应商价格＋购买点数银行卡 5.5%（Standard） | API 密钥、成员；工作区需 Enterprise | 拒绝 | 对成员或密钥设置 guardrails | OpenAI 兼容、Anthropic Messages |
| [Vercel AI Gateway](https://vercel.com/docs/ai-gateway/pricing) | 托管 | 供应商标价，token 不加价；可能有支付手续费 | 团队、项目、密钥、成员 | 402，软上限 | 供应商白名单（付费增购） | AI SDK、OpenAI Chat 与 Responses、Anthropic Messages |
| [LiteLLM](https://docs.litellm.ai/docs/proxy/users) | 自建（开源） | 自己的供应商账单＋服务器；可选 Enterprise 许可 | 密钥、用户、团队、客户 | 拒绝 | 按密钥或团队设置 access group | OpenAI 兼容 |
| [Portkey](https://portkey.ai/pricing) | 托管；另有开源和 VPC 选项 | 免费方案、Production 每月 49 美元、Enterprise 另议 | 供应商或虚拟密钥（Enterprise 和部分 Pro） | 密钥达到上限即失效 | 本文未对比 | OpenAI 兼容 |
| [Helicone](https://docs.helicone.ai/gateway/overview) | 开源（Apache）或托管 | 见厂商说明 | 本文未对比 | — | 本文未对比 | OpenAI 兼容 |
| [ATP Token](https://atptoken.ai/zh-cn/docs/how-it-works) | 托管 | 预付点数，按各模型标价扣减；5 美元起 | 项目，额度由工作区和组织往下拨 | 余额用完返回 402 | 每个项目一份，发往供应商前检查（403） | OpenAI、Anthropic、Gemini |

“本文未对比”表示我们在厂商公开文档中没有找到该项细节，正式采用前请向厂商确认。

## 怎么选：六个问题

### 1. 网关必须部署在哪里？

如果流量不能经过第三方，候选名单就是自建：LiteLLM proxy、Helicone 开源网关，或 Portkey 的开源和 VPC 选项。本文其他选项都是托管服务。

### 2. 想怎么付费？

有三种模式：

- 供应商价格加充值手续费。OpenRouter：Standard 银行卡 5.5%（最低 0.80 美元）、Business 8%（[FAQ](https://openrouter.ai/docs/faq)）。
- 按供应商标价、token 不加价。Vercel AI Gateway，可能有支付手续费（[定价](https://vercel.com/docs/ai-gateway/pricing)）。
- 预付点数，按各模型标价扣减。ATP Token：1 点 = 0.01 美元，按量付费点数不会过期，充值 5 美元起（[点数](https://atptoken.ai/zh-cn/docs/credits)）。各模型费率见[定价页](https://atptoken.ai/zh-cn/pricing)。

自建网关没有平台费，成本在供应商账单和工程时间上。

### 3. 预算绑定在什么上面？是硬上限吗？

这是各网关差异最大的地方。

- OpenRouter：guardrails 里的预算挂在成员或密钥上，按天、周、月重置；工作区预算需要 Enterprise（[guardrails](https://openrouter.ai/docs/guides/features/guardrails)）。
- Vercel：团队、项目、密钥、成员四种预算。Vercel 称之为软上限：越过上限的那一笔仍会完成，之后的请求返回 402（[预算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)）。
- LiteLLM：按密钥、用户、团队或客户设置预算，重置周期如 `30d`。
- ATP Token：点数沿组织 → 工作区 → 项目往下拨，项目只能花自己的额度。没有重置周期，项目用到余额为零就返回 402，直到有人再拨款（[预算上限配置](https://atptoken.ai/zh-cn/docs/cb-budget-caps)）。

按周期重置的预算适合“这个密钥每月不超过 500 美元”；预付额度适合“这条产品线这个季度有 5,000 美元”。

### 4. 应用现在用哪些 SDK 格式？

大多数网关支持 OpenAI 格式。如果有服务用 Anthropic SDK（Claude Code 就是）或 Google GenAI SDK，要确认是否原生支持：OpenRouter 和 Vercel 有 Anthropic Messages 文档；ATP Token 可以直接使用 OpenAI、Anthropic、Google GenAI 三种官方 SDK（[OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai)、[Anthropic SDK](https://atptoken.ai/zh-cn/docs/sdk-anthropic)、[Google GenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-google)）。

### 5. 需要哪些模型和模态？

OpenRouter 列出 80+ 家供应商、500+ 个模型。ATP Token 有 11 家供应商、70+ 个模型，包括 [Seedance 2.0](https://atptoken.ai/zh-cn/models/seedance-2-0/)、[Kling v3 Pro](https://atptoken.ai/zh-cn/models/kling-v3-pro/) 等视频模型，以及 [Nano Banana Pro](https://atptoken.ai/zh-cn/models/nano-banana-pro/) 等图像模型（[媒体模型](https://atptoken.ai/zh-cn/docs/media)）。如果只需要几个前沿 LLM，目录大小没有其他问题重要。

### 6. 日志保留什么、保留多久？

Portkey 公布了各方案的保留期：免费方案日志 3 天，Production 30 天。ATP Token 的请求日志保留 7 天，定位是排障视图，账务以账务事件为准（[请求日志 API](https://atptoken.ai/zh-cn/docs/console-api-logs)）。如果按月复盘消费，请每周导出或汇总。

## 逐个细看

### OpenRouter

- 适合：需要最大的托管模型目录、要快速评估模型。
- 管控：组织、工作区、包含预算和模型及供应商白名单的 guardrails、ZDR 规则；所有方案都能对单个密钥设置点数上限。
- 需要注意：购买点数的手续费、点数可能在一年后失效、开具发票只限 Enterprise。完整说明见 [OpenRouter 替代方案（团队版）](https://atptoken.ai/zh-cn/blog/openrouter-vs-enterprise-governance)。

### Vercel AI Gateway

- 适合：部署在 Vercel 的团队，或想要按供应商标价计费的托管网关。
- 管控：四种预算范围、50/75/100% 消费提醒、请求日志、供应商与模型故障切换。
- 需要注意：预算是软上限；使用自带供应商密钥的消费不计入预算；部分管控是付费增购。

### LiteLLM

- 适合：希望完全掌控、本来就在运维基础设施的平台团队。
- 管控：虚拟密钥、多层预算、用 access group 管理模型。
- 需要注意：需要自己运维。用户和密钥级别的按模型预算需要 Enterprise 许可。

### Portkey

- 适合：希望网关、监控和 guardrails 在同一个产品里的团队。
- 管控：对供应商或虚拟密钥设置预算上限，可设提醒阈值、每周或每月重置，适用于 Enterprise 和部分 Pro 方案（[预算上限](https://portkey.ai/docs/product/ai-gateway/virtual-keys/budget-limits)）。每月 49 美元的 Production 方案起提供基于角色的权限控制。
- 需要注意：各方案有日志额度（免费每月 1 万条，Production 10 万条）。

### Helicone

- 适合：以监控为主的团队；网关开源，用 Rust 编写。
- 管控：记录每个请求的 token 和费用，支持 100+ 个模型的路由、故障切换和缓存。
- 需要注意：预算和访问控制功能请按需求向厂商确认，网关概览文档中没有看到。

### ATP Token

- 适合：多个团队共用一笔 AI 预算，每个项目要有拨好的额度和审核过的模型清单。
- 管控：组织 → 工作区 → 项目的层级、绑定项目的密钥、每个项目的允许模型、以点数额度作为上限、逐条请求日志、Owner／Admin／Member 角色（[团队与角色](https://atptoken.ai/zh-cn/docs/team)）。
- 需要注意：模型目录比 OpenRouter 小；点数不可退款；请求日志保留 7 天。

## 同时用两个网关

很多团队最后会有两个：一个大目录网关做研究和评估，一个有治理能力的网关跑生产环境。让这种配置不出问题的规则是：生产环境的密钥不放在研究账号里，每个生产服务都有自己的密钥和预算。参考[一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)。

## 在 ATP Token 上实际对比一次

1. 创建一个项目，启用两三个想对比的模型，例如 [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/)、[gemini-3-5-flash](https://atptoken.ai/zh-cn/models/gemini-3-5-flash/) 和 [deepseek-v4-flash](https://atptoken.ai/zh-cn/models/deepseek-v4-flash/)。
2. 拨少量点数作为这次测试的上限，例如 500 点（5 美元）。
3. 把现有的 OpenAI、Anthropic 或 Google GenAI client 指向网关，用同一组提示词跑每个模型。
4. 在请求日志里对比每个请求的 token 和点数（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。模型并排对比页见 [/compare](https://atptoken.ai/zh-cn/compare/gemini-vs-gpt/)。

[从快速开始上手](https://atptoken.ai/zh-cn/docs/quickstart)

## 延伸阅读

- [OpenRouter 替代方案（团队版）](https://atptoken.ai/zh-cn/blog/openrouter-vs-enterprise-governance)
- [OpenAI API 与 OpenAI 兼容网关](https://atptoken.ai/zh-cn/blog/openai-api-vs-enterprise-ai-gateway)
- [AI API 消费上限对比](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)

## 常见问题

### 什么是 LLM 网关？

LLM 网关是位于应用和模型供应商之间的服务，对外提供一个可以调用多家模型的 API。根据产品不同，它还负责鉴权、供应商路由与故障切换、请求日志、消费上限和模型权限。

### 最好的 LLM 网关是哪个？

没有唯一答案，取决于你的约束条件。必须自建选 LiteLLM，要最大的托管模型目录选 OpenRouter，应用在 Vercel 上选 Vercel AI Gateway，想按项目预付预算并设置模型白名单选 ATP Token。

### LLM 网关和 LLM proxy 一样吗？

基本一样。proxy 把请求转发给供应商、保持稳定的 API；网关是更宽泛的说法，指同时负责密钥、预算、模型权限和日志的 proxy。

### LiteLLM 免费吗？

LiteLLM proxy 开源、自建免费；你支付的是供应商费用和服务器成本。部分功能，例如用户和密钥级别的按模型预算，需要 Enterprise 许可。

### 用了网关还需要供应商账号吗？

自建网关需要，因为它用你的密钥调用供应商。OpenRouter、Vercel AI Gateway、ATP Token 这类托管网关可以自己计收模型用量，部分也支持自带供应商密钥。

---

Tags: LLM 网关, AI 网关, ATP
