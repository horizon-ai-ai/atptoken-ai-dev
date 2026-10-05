# LLM token 成本怎么算？计算公式、5 个模型实算与 AI 账单读法（2026）

> 来源: https://atptoken.ai/zh-cn/blog/how-to-read-your-ai-bill/
> 发表于: 2026-07-21 · 作者: hung-chien (AI 增长与品牌经理)

LLM token 成本怎么算：单次请求计算公式、同一请求在 5 个模型上的实际花费、输入与输出价差、缓存与推理 token，以及 AI 账单该看哪些字段。

## 重点摘要

- 单次请求的 LLM token 成本 = 输入 token × 输入单价 + 输出 token × 输出单价，单价按每 100 万 token 计。claude-sonnet-4-6（$3 / $15）处理 1,284 个输入与 412 个输出 token，成本是 $0.010032，也就是 1.0032 点 ATP 点数。
- 同一笔请求在 gpt-5.5 上是 $0.01878，在 qwen-3-7-flash 上是 $0.00009208，相差 204 倍。模型选择对账单的影响，大于其他任何单一设置。
- 常见模型的输出单价是输入的 2 到 6 倍，推理 token 也按输出计费。读账单时先按项目与模型看，再趁 7 天的请求日志还在时追到单笔请求。

LLM token 成本，是模型读入（输入）与写出（输出）的 token 产生的费用，两者分别按每 100 万 token 的单价计算。本文给出计算公式，拿一笔真实大小的请求在五个模型上实算，说明输出、缓存与推理 token 如何改变算式，并列出月度账单对不上时该看哪些字段。

以下单价均为各模型页上的 ATP 标价，截至 2026 年 10 月。引用的厂商单价都附上厂商定价页链接。

## token 成本计算公式

任何按 token 计价的 API，单次请求的成本都来自同样三步：

1. 输入成本 = 输入 token × 输入单价 ÷ 1,000,000
2. 输出成本 = 输出 token × 输出单价 ÷ 1,000,000
3. 请求成本 = 输入成本 + 输出成本

在 ATP Token 上，这笔费用会以点数从项目余额中扣除，[1 点 = 0.01 美元](https://atptoken.ai/zh-cn/docs/credits)。点数 = 美元成本 × 100。

### 实算：一条客服机器人回复

客服机器人发送 1,284 token 的提示（系统提示、检索到的帮助中心片段、客户消息）给 claude-sonnet-4-6，单价为每 100 万 token 输入 $3、输出 $15，拿回 412 token 的回答。

- 输入：1,284 × $3 ÷ 1,000,000 = $0.003852
- 输出：412 × $15 ÷ 1,000,000 = $0.00618
- 合计：$0.010032 = 1.0032 点

每月 10 万条回复就是 $1,003.20。这笔请求里输出只占 token 数的 24%，却占成本的 61.6%。

### 可以直接粘贴的 token 成本计算器

SDK 返回的内容本身就带有 token 数。OpenAI 格式的字段是 `usage.prompt_tokens` 与 `usage.completion_tokens`，Anthropic 格式则是 `usage.input_tokens` 与 `usage.output_tokens`。

```python
RATES = {  # 每 100 万 token 美元：(输入, 输出)，ATP 标价
    "gpt-5.5": (5.00, 30.00),
    "claude-sonnet-4-6": (3.00, 15.00),
    "gemini-3-5-flash": (1.50, 9.00),
    "deepseek-v4-flash": (0.20, 0.40),
    "qwen-3-7-flash": (0.03, 0.13),
}

def token_cost(model, input_tokens, output_tokens):
    rate_in, rate_out = RATES[model]
    usd = (input_tokens * rate_in + output_tokens * rate_out) / 1_000_000
    return usd, usd * 100  # (美元, ATP 点数)

print(token_cost("claude-sonnet-4-6", 1284, 412))  # 约 (0.010032, 1.0032)
```

## 同一笔请求放到 5 个模型上

把输入 1,284、输出 412 的请求放到五个模型上计价。qwen-3-7-flash 采用提示在 32K token 以内的档位单价。

| 模型 | ATP 标价（每 100 万 token 输入 / 输出） | 单次成本 | 单次点数 | 每 10 万次 |
|---|---|---|---|---|
| [gpt-5.5](https://atptoken.ai/zh-cn/models/gpt-5.5/) | $5 / $30 | $0.01878 | 1.878 | $1,878.00 |
| [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/) | $3 / $15 | $0.010032 | 1.0032 | $1,003.20 |
| [gemini-3-5-flash](https://atptoken.ai/zh-cn/models/gemini-3-5-flash/) | $1.50 / $9 | $0.005634 | 0.5634 | $563.40 |
| [deepseek-v4-flash](https://atptoken.ai/zh-cn/models/deepseek-v4-flash/) | $0.20 / $0.40 | $0.0004216 | 0.04216 | $42.16 |
| [qwen-3-7-flash](https://atptoken.ai/zh-cn/models/qwen-3-7-flash/) | $0.03 / $0.13 | $0.00009208 | 0.009208 | $9.21 |

这张表把 token 数固定，只比较单价。实际上每家的 tokenizer 切分方式不同，token 数也会不同。Anthropic 指出 Claude 4.7 及以后模型的 tokenizer，同样文本大约会多产生 30% 的 token（[Anthropic 定价](https://platform.claude.com/docs/en/about-claude/pricing)），所以同一段 1,284 token 的提示，在 4.7 及以后的模型上会接近 1,670 token。比较模型前先用自己的提示实测，质量也要并排看，例如 [DeepSeek vs Claude 对比](https://atptoken.ai/zh-cn/compare/deepseek-vs-claude/)。

## 为什么输出 token 主导账单

输出与输入的单价比，决定钱花在哪里。

| 模型 | 输出单价 ÷ 输入单价 | 上例中输出占成本比例 |
|---|---|---|
| gpt-5.5 | 6 倍 | 65.8% |
| claude-sonnet-4-6 | 5 倍 | 61.6% |
| deepseek-v4-flash | 2 倍 | 39.1% |

实际影响有两点。在 5 倍或 6 倍的模型上，缩短回答比缩短提示更划算：在 claude-sonnet-4-6 上少 200 个输出 token 省 $0.003，相当于少 1,000 个输入 token。另外，大量生成文本的工作（起草、生成代码、写报告），估算成本时主要看预期的输出长度。

## 缓存输入与推理 token

厂商价目表上有两种 token，第一次读账单的人最容易卡住。

### 缓存输入是厂商的计价功能

部分厂商对命中缓存的重复提示前缀另定较低单价。OpenAI 列出 GPT-5.5 的缓存输入为每 100 万 token $0.50，普通输入是 $5（[OpenAI 定价](https://developers.openai.com/api/docs/pricing)）。Anthropic 多数模型的缓存读取是基础输入单价的 0.1 倍，缓存写入为 1.25 倍（5 分钟）或 2 倍（1 小时）（[Anthropic 定价](https://platform.claude.com/docs/en/about-claude/pricing)）。这些是按各厂商缓存规则直接调用时的厂商单价。ATP Token 按[计价模式](https://atptoken.ai/zh-cn/docs/pricing-model)以输入与输出 token 计费，所以 ATP 预算请按输入与输出标价来估算。

### 推理 token 按输出计费

推理模型回答前会先思考，这些看不见的 token 也要付费。OpenAI 写明推理 token 按输出 token 计费（[OpenAI 推理指南](https://developers.openai.com/api/docs/guides/reasoning)），Anthropic 也把 extended thinking 的 token 按输出计费（[Claude Code 成本](https://code.claude.com/docs/en/costs)）。如果上面那条客服回复在 claude-sonnet-4-6 上用了 1,500 个 thinking token，就多出 1,500 × $15 ÷ 1,000,000 = $0.0225，单次成本从 $0.010032 变成 $0.032532，约 3.2 倍。

推理预算也能解释一种让人困惑的日志：返回 `200` 但内容为空。`max_tokens` 设得太低时，模型把预算全用在思考上，没有产出文本。在 ATP 上这类请求通常显示零用量、不扣点数；解决方法是调高 `max_tokens`（[错误码](https://atptoken.ai/zh-cn/docs/errors)）。

## 单笔请求记录告诉你什么

月度总额只说得出花了多少。单笔请求记录说得出是哪个项目、哪个模型、用了多少 token。下面是示意用的记录，列出计算单次成本需要的字段，并不是 ATP 实际的日志格式。

```json
{
  "request_id": "req_example_01",
  "project": "support-bot-prod",
  "model": "claude-sonnet-4-6",
  "input_tokens": 1284,
  "output_tokens": 412,
  "cost_usd": 0.010032,
  "cost_credits": 1.0032
}
```

在 ATP Token 里，这些信息分布在三个地方：

- 请求日志，每次调用一行：时间、范围（工作区与项目）、模型、端点、HTTP 状态、供应商结果、输入与输出 token、计费状态与请求 ID。可按时间范围、范围、模型、状态或请求 ID 筛选（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。保留 7 天，费用异常要在一周内查。
- 账务事件，即逐笔计费账本，控制台以 90 天呈现，可按模型、密钥、计费状态或请求 ID 筛选（[账务 API](https://atptoken.ai/zh-cn/docs/console-api-billing)）。计费以这份账本为准。
- 用量页，按模型与 API 密钥汇总一段时间内的点数与 token。

每个响应还带有 `x-request-id` 头，工程师可以把应用日志里的某次调用，对应到控制台里的那一行。

## 三种账单异常与排查方法

### 某一周费用突然跳升

在用量页按 API 密钥排序。如果密钥和项目一一对应，跳升会立刻落到某个负责人身上。接着在请求日志里筛选该项目，比较跳升前后每次请求的 token 数。输入从约 1,300 涨到 13,000 token，通常是有人开始每一轮都发送整份文档。

### 单价没错，总额却对不上

检查模型组合。把 10 万条客服回复中的 20% 从 claude-sonnet-4-6 改到 gpt-5.5，流量不变，当月就从 $1,003.20 变成 $1,178.16。

### 请求成功却没有文本

查找推理模型上输出 token 为零的 `200` 记录，把 `max_tokens` 调到足以覆盖思考加回答。

## 在 ATP Token 上怎么设置

1. 每个服务、每个环境各建一个项目，各配一把 `atp-` 密钥，用量页的「按密钥」就等于「按负责人」。
2. 为每个项目分配点数。分配额就是项目的上限，余额用完时调用会返回 `402`（[预算上限设置](https://atptoken.ai/zh-cn/docs/cb-budget-caps)）。项目也可以开启自动充值，设置触发阈值与每月上限。
3. 记录每个响应的 `usage` 与模型 ID，每周按项目运行一次上面的计算器。
4. 月底以账务事件对账，7 天内的细节用请求日志追查。

[从快速开始接入](https://atptoken.ai/zh-cn/docs/quickstart)

## 延伸阅读

- [企业 AI 成本管理与 LLM 成本优化指南](https://atptoken.ai/zh-cn/blog/enterprise-ai-cost-management-guide)
- [上线后 AI 账单为什么会暴增](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live)
- [什么是 agent tax？](https://atptoken.ai/zh-cn/blog/what-is-the-agent-tax)

## 常见问题

### LLM token 成本怎么计算？

把输入 token 乘以模型的输入单价、输出 token 乘以输出单价，由于单价按每 100 万 token 计，各自再除以 1,000,000，最后相加。例如 claude-sonnet-4-6（$3 / $15）处理 1,284 个输入与 412 个输出 token，成本是 $0.003852 + $0.00618 = $0.010032。

### 为什么输出 token 比输入 token 贵？

厂商对生成的定价高于读取。按 ATP 标价，gpt-5.5 的输出是输入的 6 倍、claude-sonnet-4-6 是 5 倍、deepseek-v4-flash 是 2 倍，所以提示短、回答长的请求，成本大多落在输出上。

### 推理 token 要付费吗？

要。OpenAI 与 Anthropic 都把推理（thinking）token 按输出 token 计费，即使它不会出现在回答里。在 claude-sonnet-4-6 上多用 1,500 个 thinking token，单次请求就多 $0.0225。

### 在 ATP Token 上一次请求会扣多少点数？

1 点 = 0.01 美元，所以点数 = 美元成本 × 100。$0.010032 的请求扣 1.0032 点。余额显示到小数点后四位。

### ATP 的请求日志保留多久？

请求日志保留 7 天，用于排查问题。计费以账务事件（billing events）为准，控制台以 90 天账本呈现。

---

Tags: LLM token 成本, AI 账务, ATP
