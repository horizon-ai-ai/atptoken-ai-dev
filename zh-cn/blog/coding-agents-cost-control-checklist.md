# Claude Code 费用怎么算：每位开发者一天多少钱，以及 10 项管控（2026）

> 来源: https://atptoken.ai/zh-cn/blog/coding-agents-cost-control-checklist/
> 发表于: 2026-08-14 · 作者: hung-chien (AI 增长与品牌经理)

Claude Code 费用平均约每位开发者每个活跃日 13 美元。以 25 人团队测算月预算，并列出 10 项把 coding agent 花费控制在上限内的做法。

## 重点摘要

- Anthropic 公布的 Claude Code 平均费用约为每位开发者每个活跃日 13 美元、每月 150–250 美元，90% 用户每个活跃日低于 30 美元。
- 25 位开发者、每月 20 个活跃日，基准是每月 6,500 美元；其中 5 位重度用户用量翻倍，就变成 7,800 美元。
- 十项管控：独立项目、每人一个密钥、以分配额度作上限、只开 Sonnet 的白名单、固定默认模型、会话习惯、无人值守运行的预算、agent teams 改为申请制、每周查请求日志、离职即吊销。

团队的 Claude Code 费用，是开发者工作时 CLI 发出的每个请求累积起来的 token 账单；Anthropic 公布的平均值约为每位开发者每个活跃日 13 美元。本文把这个数字换算成 25 人团队的月预算，算出少数重度用户会多出多少，并列出十项管控及各自的具体设置。

| 问题 | 简答 |
|---|---|
| 每位开发者平均费用 | 每个活跃日约 13 美元，每月 150–250 美元 |
| 常见上沿 | 90% 用户每个活跃日低于 30 美元 |
| 25 位开发者、20 个活跃日 | 每月基准 6,500 美元 |
| 同一团队、5 位重度用户用量翻倍 | 每月 7,800 美元 |
| 最可避免的花费来源 | 没清理的长会话、Opus 作默认、agent teams |

## Claude Code 怎么计费

截至 2026 年 10 月，Anthropic 的 [Claude Code 费用说明页](https://code.claude.com/docs/en/costs)指出，在企业部署中，平均费用约为每位开发者每个活跃日 13 美元、每月 150–250 美元，且 90% 用户每个活跃日低于 30 美元。Anthropic 建议先用小规模试点团队建立自己的基准，再扩大推广。

费用如何落到你头上，取决于开发者用什么方式登录。Pro 与 Max 订阅已包含用量。Team 与 Enterprise 方案的每位成员使用每个席位的额度，按滚动 5 小时和每周两个窗口重置，并与 Claude 对话共用；只有管理员开启 usage credits 后，成员才能超出额度继续使用。通过 Claude Console、云服务商，或 ATP Token 这类网关使用时，Claude Code 按 token 向组织计费。

本文讨论的是按 token 计费的情况：除了你自己设的上限，没有任何东西会让会话停下来。

## 25 人团队的 Claude Code 费用测算

假设 25 位开发者每月 20 个工作日都使用 Claude Code，按 Anthropic 的平均 13 美元计算：

25 位开发者 × 20 个活跃日 × 13 美元 = **每月 6,500 美元**

折合每人 260 美元，略高于 Anthropic 的每月 150–250 美元区间，因为 20 个活跃日假设每个人每个工作日都在用。

平均值会掩盖长尾。假设其中 5 位开发者经常开长会话或同时运行多个实例，费用是平均的 2 倍（每个活跃日 26 美元）：

| 情境 | 算式 | 每月费用 | ATP 点数 |
|---|---|---|---|
| 基准 | 25 × 20 × 13 美元 | 6,500 美元 | 650,000 |
| 5 位重度用户 2 倍 | (20 × 20 × 13) + (5 × 20 × 26) = 5,200 + 2,600 美元 | 7,800 美元 | 780,000 |
| 再加一周 agent team | 7,800 美元 + 5 天 × (91 − 13 美元) | 8,190 美元 | 819,000 |

最后一行假设一位普通用量的开发者连续 5 天使用 agent team。Anthropic 表示，队友在 plan 模式下运行时，agent teams 的 token 用量约为普通会话的 7 倍，因此每天是 7 × 13 = 91 美元，而不是 13 美元。ATP Token 以点数计费，1 点 = 0.01 美元。

## 管控 Claude Code 花费的 10 项做法

### 1. 给 coding agent 独立的项目

建立一个只给 Claude Code（以及其他 coding agent）使用的项目，与生产服务的项目分开。同一项目内的每个密钥都从该项目余额扣费，所以整晚跑循环的 agent 不会把面向客户服务的预算用光。做法见[一个项目，一个密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)。

### 2. 项目内每位开发者一个密钥

密钥只属于一个项目，并继承该项目的允许模型与余额。每人一个密钥，用量页就能按密钥显示点数与 token，不用另外接工具就看得到每个人的花费。密钥以 `atp-` 开头，完整密钥只显示一次（[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys)）。

### 3. 把分配额度当作每月上限

把上表中含重度用户的数字，也就是 780,000 点，分配给这个项目。项目只能花被分配到的额度；余额用完后，请求会返回 `402`，直到管理员再次分配。如果开启了项目自动充值，也要设置每月上限，否则上限就不再是上限。设置步骤见[设置有预算上限的团队](https://atptoken.ai/zh-cn/docs/cb-budget-caps)。

### 4. 白名单只开 claude-sonnet-4-6，Opus 放到另一个项目

主要的 coding 项目只启用 [claude-sonnet-4-6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/)。按 ATP 牌价，它是每百万 token 输入 3 美元、输出 15 美元；[claude-opus-4-8](https://atptoken.ai/zh-cn/models/claude-opus-4-8/) 则是 5 美元和 25 美元，每个 token 约贵 1.67 倍。如果有人切换到项目未允许的模型，网关会在请求到达任何供应商之前返回 `403`。需要用 Opus 做架构设计的开发者，另开第二个项目并给较小的额度，例如 50,000 点。

### 5. 固定 ANTHROPIC_MODEL

在每位开发者的环境变量，或 `~/.claude/settings.json` 的 `env` 区块中设置 `ANTHROPIC_MODEL="claude-sonnet-4-6"`。`--model` 参数会在单个会话中覆盖 `ANTHROPIC_MODEL`，所以固定模型只决定默认值，真正的限制靠第 4 项的白名单。

### 6. 养成 /usage 与 /clear 的习惯

`/usage` 的 Session 区块会显示 token 用量，以及 Claude Code 在本地按牌价估算的金额；项目实际被扣多少，以 ATP 用量页为准。Anthropic 建议的省钱习惯：

- 切换到不相关的工作时执行 `/clear`。旧的上下文会随每条消息重发，而 `/clear` 本身不花钱。
- 简单任务用 `/effort` 调低思考强度。思考 token 按输出 token 计费。
- 让 `CLAUDE.md` 保持精简，把专门的指令移到按需加载的 skills。

### 7. 无人值守的运行用 --max-budget-usd 与 --max-turns 设限

针对 CI 和脚本，Claude Code 的 [CLI 参考文档](https://code.claude.com/docs/en/cli-reference)列出两个 print 模式参数：`--max-budget-usd` 会在估算花费（含 subagent）达到金额时停止；`--max-turns` 在固定的 agent 轮数后退出。

```
claude -p --max-budget-usd 5.00 --max-turns 30 "fix the failing tests in src/auth"
```

这是客户端的单次停止点。对那种整晚重试修 flaky test 的任务，项目分配额度仍是服务端的上限。

### 8. Agent teams 改为申请制

Agent teams 默认关闭，用 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 开启。在 plan 模式下 token 用量约为普通会话的 7 倍，一位开发者跑 agent team 的花费，约等于七位开发者的普通用量。把它放在有独立额度的另一个项目，并请团队让队友使用 Sonnet、任务完成就关闭队友。

### 9. 每周从请求日志检查花费

每周一打开用量页，按密钥和模型排序，再看同一周的请求日志。每一行显示时间、范围、模型、状态、request ID 以及输入／输出 token。请求日志保留 7 天，所以每周检查是不漏掉任何请求的最长间隔；要保存历史，可以用[请求日志 API](https://atptoken.ai/zh-cn/docs/console-api-logs) 导出。重点看用量超过团队中位数 2 倍的密钥、计划外的模型，以及连续出现的 `4xx` 或 `5xx`。

### 10. 离职时吊销密钥

外包人员离开时，在 API 密钥页吊销他的密钥。被吊销的密钥立即失效，并保留在列表中供审计；因为每人一个密钥，其他人的会话不受影响。

第 6 到第 8 项背后的成本结构，见[什么是 agent tax](https://atptoken.ai/zh-cn/blog/what-is-the-agent-tax)；哪类工作该开哪个模型，见[最适合写代码的 LLM 指南](https://atptoken.ai/zh-cn/guides/best-llm-for-coding/)。

## 在 ATP Token 上配置 Claude Code

### 步骤 1：建立项目与分配额度

在控制台建立工作区，以及以团队命名的项目（例如 `claude-code-platform`），只启用 `claude-sonnet-4-6`，并分配每月点数。

### 步骤 2：每位开发者发一个密钥

从项目为每个人创建一个密钥，通过密码管理工具交给本人。完整密钥只会显示一次。

### 步骤 3：把 Claude Code 指向网关

Base URL 不加 `/v1`，因为 Claude Code 会自己补上 `/v1/messages`。把 `ANTHROPIC_API_KEY` 清空，避免它优先生效。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

同样的值也可以写在 `~/.claude/settings.json` 的 `env` 区块。

### 步骤 4：验证

运行一次提示，再打开控制台：请求会出现在请求日志里，花掉的点数会出现在用量页。完整步骤见[在 ATP 上运行 Claude Code](https://atptoken.ai/zh-cn/docs/cb-claude-code)。

## 延伸阅读

- [什么是 agent tax？一步步算出 AI agent 的成本](https://atptoken.ai/zh-cn/blog/what-is-the-agent-tax)
- [真正有效的 AI 花费上限](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)
- [一个项目，一个密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)

## 常见问题

### Claude Code 每位开发者要花多少钱？

Anthropic 表示，在企业部署中平均约为每位开发者每个活跃日 13 美元、每月 150–250 美元，90% 用户每个活跃日低于 30 美元。实际数字主要取决于模型选择，以及每个人同时开几个会话。

### Claude Code 是按订阅收费，还是按 API 用量收费？

两种都有。Pro 与 Max 订阅已包含用量；Team 与 Enterprise 成员使用每个席位的额度，按滚动 5 小时和每周两个窗口重置。通过 Claude Console、云服务商或网关使用时，则按 token 计费。

### 怎么给 Claude Code 设花费上限？

把 Claude Code 的流量放进独立项目，并分配固定点数；分配额度就是上限，余额用完后请求会返回 402。用脚本运行时，可以再加上 Claude Code 在 print 模式下的 --max-budget-usd 参数，作为单次运行的停止点。

### Claude Code 可以用 API 密钥代替订阅吗？

可以。把 ANTHROPIC_BASE_URL 指向网关，项目密钥放进 ANTHROPIC_AUTH_TOKEN，ANTHROPIC_API_KEY 设为空字符串避免它优先生效，再把 ANTHROPIC_MODEL 固定为项目允许的模型。

### 为什么 Claude Code 的账单比预期高？

Anthropic 自己的说明指出，API 花费意外偏高，通常来自从未清理的长会话，或把 Opus 留作默认模型。Agent teams 也是来源之一：队友在 plan 模式下运行时，token 用量约为普通会话的 7 倍。

---

Tags: Claude Code, Coding agents, ATP
