# 什么是 agent tax？一步步算出 AI agent 的成本（2026）

> 来源: https://atptoken.ai/zh-cn/blog/what-is-the-agent-tax/
> 发表于: 2026-07-31 · 作者: hung-chien (AI 增长与品牌经理)

AI agent 成本会随步数增加，因为每一步都重发整段上下文。按牌价测算一个 20 步的 agent，并整理五个降低 agent tax 的做法。

## 重点摘要

- Agent tax 是用多次模型调用完成一项工作所多出的 token 成本，因为每次调用都会重发不断变长的上下文。
- 一个 20 步的 agent，基础上下文 8,000 token、每步增加 2,000 token，总共读入 540,000 个输入 token：在 claude-sonnet-4-6 上每项任务约 1.77 美元，单轮对话只要 0.03 美元。
- 把工具输出先做摘要，成本约可减半；项目分配额度则为成本设上限。每项完成任务的成本，要把自己的任务 ID 关联到 request ID 来算。

Agent tax 是 AI agent 为了完成一项工作，每一步都重发整段且不断变长的上下文，因而多付的 token 成本。单轮对话只为上下文付一次钱；20 步的 agent 要付 20 次，而且每次都比上一次大一点。下面按牌价逐行计算一项 agent 任务，再整理影响最大的五个做法。

| 运行形态 | 输入 token | 输出 token | claude-sonnet-4-6 成本 |
|---|---|---|---|
| 单轮对话 | 8,000 | 500 | 0.03 美元 |
| 20 步 agent | 540,000 | 10,000 | 1.77 美元 |
| 20 步 agent，工具输出先摘要 | 255,000 | 10,000 | 0.92 美元 |

## AI agent 成本怎么累加：20 步示例

假设一个 agent 每项任务从 8,000 token 的基础上下文开始（系统提示、工具定义、任务内容）。每一步附加约 2,000 token 的工具结果和模型输出，每一步写出 500 个输出 token。因此第 *i* 步读入 8,000 + 2,000 × (i − 1) 个输入 token。

20 步的输入 token：

Σ = 20 × 8,000 + 2,000 × (0 + 1 + … + 19) = 160,000 + 2,000 × 190 = **540,000 token**

输出 token：20 × 500 = 10,000。

基础上下文只占输入的 30%（540,000 中的 160,000），另外 70% 是同一批工具结果在后续步骤中被重复读入。仅最后 8 步就读了 312,000 token，比前 12 步加起来（228,000）还多。

按 ATP 牌价（每百万 token，截至 2026 年 10 月）计算：

| 模型（输入／输出） | 输入成本 | 输出成本 | 每项任务 | 每月 10,000 项任务 |
|---|---|---|---|---|
| [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/)（3／15 美元） | 0.54 × 3 = 1.62 美元 | 0.01 × 15 = 0.15 美元 | 1.77 美元 | 17,700 美元 |
| [gemini-3-5-flash](https://atptoken.ai/zh-cn/models/gemini-3-5-flash/)（1.5／9 美元） | 0.54 × 1.5 = 0.81 美元 | 0.01 × 9 = 0.09 美元 | 0.90 美元 | 9,000 美元 |
| [deepseek-v4-flash](https://atptoken.ai/zh-cn/models/deepseek-v4-flash/)（0.2／0.4 美元） | 0.54 × 0.2 = 0.108 美元 | 0.01 × 0.4 = 0.004 美元 | 0.112 美元 | 1,120 美元 |

同样的基础上下文如果单轮回答，在 claude-sonnet-4-6 上是 8,000 × 3/M + 500 × 15/M = 0.024 + 0.0075 = 0.0315 美元。Agent 任务约是它的 56 倍。这个倍数就是 agent tax：费率没变，变的是 token 数量。

Anthropic 公布过一个实际数据：在 Claude Code 中，队友以 plan 模式运行时，agent teams 的 token 用量约为普通会话的 7 倍，因为每个队友都有自己的上下文窗口（[Claude Code 费用说明](https://code.claude.com/docs/en/costs)）。

## 降低 agent tax 的五个做法

### 1. 限制步数

输入大致随步数的平方增长，贵的是后段的步骤。设置硬性上限，达到时返回明确的失败。如果同一项任务 12 步就能完成，输入降到 12 × 8,000 + 2,000 × 66 = 228,000 token，每项任务从 1.77 美元降到 0.77 美元。

### 2. 工具输出进入上下文前先做摘要

把完整文件内容和完整 API 响应换成简短摘要，或只保留关键的几行。如果每步增量从 2,000 降到 500 token，输入变成 160,000 + 500 × 190 = 255,000 token：0.765 + 0.15 = 每项任务 0.92 美元，少 48%。

### 3. 子步骤改用更便宜的模型

很多步骤只是读一段工具结果，再决定下一个调用什么。决策步骤留在 claude-sonnet-4-6，其余交给 deepseek-v4-flash。以 6 个决策步骤、14 个子步骤、每步平均 27,000 个输入 token 计：

- Sonnet：162,000 × 3/M + 3,000 × 15/M = 0.486 + 0.045 = 0.531 美元
- Flash：378,000 × 0.2/M + 7,000 × 0.4/M = 0.0756 + 0.0028 = 0.078 美元
- 合计：每项任务约 0.61 美元，比全用 Sonnet 少 66%

切换前先用自己的任务测试质量；[DeepSeek 与 Claude 对比](https://atptoken.ai/zh-cn/compare/deepseek-vs-claude/)可以作为起点。

### 4. 在供应商支持时使用 prompt caching

Agent 的大部分输入，是上一步已经发过的前缀。在 Anthropic 自家 API 上，缓存读取的费率是基础输入的 0.1 倍，5 分钟缓存写入是 1.25 倍（[Anthropic 定价](https://platform.claude.com/docs/en/about-claude/pricing)）。在 20 步示例中，540,000 个输入 token 有 494,000 个是重复内容。按 Anthropic 的 Sonnet 4.6 费率，是 494,000 × 0.30/M + 46,000 × 3.75/M + 0.15 美元输出 = 0.148 + 0.173 + 0.15，每项任务约 0.47 美元。缓存有存活时间，等待慢速工具的步骤可能错过缓存。依赖这个做法之前，先确认你的供应商如何计算缓存 token。

### 5. 给每个 agent 独立的预算

把每个 agent 放进自己的项目，并为它分配点数。项目只能花被分配到的额度，余额用完后请求会返回 `402`，卡住的循环会停在上限，而不是拖到月底才被发现。每月 10,000 项 Sonnet 任务，分配额度就是 1,770,000 点（1 点 = 0.01 美元）。设置方式见[设置有预算上限的团队](https://atptoken.ai/zh-cn/docs/cb-budget-caps)。

## 如何衡量每项完成任务的成本

网关看得到请求，但只有你的应用知道哪些请求属于同一项任务。ATP 的每个响应都带有 `x-request-id` 响应头。把它和你自己的任务或会话 ID、步骤编号，以及任务最终是否成功一起记录。

然后：

1. 从请求日志取出这些 request ID 对应的行，每行显示模型、状态和输入／输出 token（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。日志保留 7 天，请每周用[请求日志 API](https://atptoken.ai/zh-cn/docs/console-api-logs) 导出。
2. 把 token 乘以模型牌价，按任务汇总。
3. 用总成本（包括失败和中途放弃的任务）除以完成的任务数。

失败的任务要算进分子。成功率 80%、每次尝试 1.77 美元的 agent，每项完成任务的成本是 1.77 / 0.8 = 2.21 美元。

日志里要留意一种模式：内容为空的 `200`。在推理模型上，这通常说明 `max_tokens` 不足以覆盖思考预算。ATP 通常会报告零用量、不扣点数，但不调高 `max_tokens` 就重试的 agent，会一直重复这个空响应（[错误](https://atptoken.ai/zh-cn/docs/errors)）。

[了解计价方式](https://atptoken.ai/zh-cn/pricing)

## 延伸阅读

- [Claude Code 费用怎么算：每位开发者一天多少钱，以及 10 项管控](https://atptoken.ai/zh-cn/blog/coding-agents-cost-control-checklist)
- [为什么 LLM 成本在上线后暴涨](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live)
- [怎么读懂 AI 账单](https://atptoken.ai/zh-cn/blog/how-to-read-your-ai-bill)

## 常见问题

### 运行一个 AI agent 要花多少钱？

主要取决于步数和上下文增长，而不是每 token 的单价。一个从 8,000 token 开始、每步增加 2,000 token 的 20 步 agent，会读入 540,000 个输入 token、写出 10,000 个输出 token，按每百万 token 3／15 美元计，每项任务约 1.77 美元。

### 为什么 AI agent 比普通对话 API 贵？

对话 API 只发一次上下文。Agent 每一步都会再发一次，而且每次都附上新的工具结果，所以输入 token 大致随步数的平方增长。

### 怎么计算每项任务的 AI agent 成本？

输入 token 总和 = 基础 × 步数 + 增量 × (0 + 1 + … + 步数 − 1)，再加上输出 token，分别乘以模型费率。生产环境中，把自己的任务 ID 和每个 request ID 一起记录，再用总成本除以完成的任务数。

### 怎么降低 AI agent 的 token 成本？

限制步数、工具输出进入上下文前先做摘要、子步骤改用更便宜的模型、在供应商以更低费率计算缓存读取时使用 prompt caching，并给每个 agent 项目独立的点数分配。

---

Tags: Agent tax, AI agent 成本, ATP
