# LLM API 密钥管理：一项目一密钥，附 30 天迁移流程（2026）

> 来源: https://atptoken.ai/zh-cn/blog/one-project-one-key/
> 发表于: 2026-08-07 · 作者: hung-chien (AI 增长与品牌经理)

LLM API 的 API 密钥管理：共用密钥会在哪里出问题、如何每个项目发一个密钥、各环境密钥放在哪里，以及一份 30 天迁移流程。

## 重点摘要

- 每个工作负载有自己的项目和自己的密钥，吊销、轮换、追查花费时一次只影响一个服务。
- OpenAI 建议每位成员使用各自的 API 密钥，并且永远不要把密钥放在客户端代码里；生产服务则需要工作负载专属的密钥，员工离职才不会拖垮服务。
- 从共用密钥迁出大约需要 30 天：盘点调用方、创建项目、先切非生产环境、生产服务逐个切换，最后吊销。

LLM API 的密钥管理，是一套决定谁能拿到密钥、每个密钥能访问什么、存放在哪里、以及如何轮换与吊销的规则。在生产环境站得住的做法是一项目一密钥：每个工作负载有自己的项目，项目的密钥带着自己的模型清单与预算。下面依次整理共用密钥出问题的三种情况、发密钥的做法、各环境密钥存放位置的对照表，以及一份 30 天迁移流程。

## 共用密钥出问题的三种情况

### 已离职的外包工程师

一位外包工程师用公司唯一的一个 API 密钥做 RAG 原型，密钥放在本地的 `.env` 文件里，周五离职。同一个密钥还在跑客服机器人、每晚的摘要任务和内部的 Slack 助手。当天下午吊销它，三个服务一起挂；不吊销，等于一位已离职的外包手里还有一个能用的密钥。多数团队选择“下个 sprint 再轮换”，而下个 sprint 总是排满。

一项目一密钥的话，这位外包从头到尾只拿到自己沙箱项目的密钥。吊销它，其他什么都不受影响。

### 被推到公开仓库的密钥

有人把含密钥的配置文件 commit 到公开仓库。拿到它的人发出的流量会算在你的账单上，而且因为每个服务都发同一个密钥，对方的请求在用量数据里和你的完全一样。处理方式与外包的情况相同，同样会带来一次停机。

### 没人说得清的花费暴涨

月度账单翻倍。供应商的仪表盘看得出哪个模型用量上升，但每笔请求都带同一个密钥，没人能说清是哪个产品造成的。财务要求按产品拆账，工程师花两天比对各服务日志的时间戳。

## 各家厂商的建议

OpenAI 的 [API 密钥安全最佳实践](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) 要求每位团队成员使用各自的 API 密钥、定期轮换并设置过期，且永远不要把密钥放在客户端代码里。OpenAI 还建议把 staging 与生产环境分成不同项目，各自设置上限（[生产环境最佳实践](https://developers.openai.com/api/docs/guides/production-best-practices)）。Anthropic 可以把 API 密钥限定在单个 Console [工作区](https://platform.claude.com/docs/en/manage-claude/workspaces)。Vercel AI Gateway 的密钥可以同时设置预算与过期时间，适合有明确结束日期的外包密钥（[Vercel 预算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)）。

个人密钥解决的是人员离职的问题。生产服务不应该跑在某个人的密钥上，否则移除这个人，服务也会跟着停。实际可行的分法是：个人密钥给个人沙箱，每个已部署的工作负载各有一个项目密钥。

## 发密钥的做法

1. **每个工作负载、每个环境各一个项目。** `support-bot-prod` 与 `support-bot-staging` 是两个独立项目，各有各的密钥。
2. 服务使用项目密钥，一个项目一个。需要做实验的人有自己的沙箱项目。
3. 密钥按“服务、环境、签发月份”命名，例如 `support-bot-prod-2026-10`，在日志或仓库里发现时能直接对应到负责人。
4. 密钥从控制台直接放进 secret manager，不要贴到聊天、工单或文档里。
5. 用重叠方式轮换：在同一个项目发新密钥、部署、确认流量已经转移，再吊销旧的。

## 各环境的密钥放在哪里

| 环境 | 项目 | 密钥存放位置 | 谁能读取 |
|---|---|---|---|
| 生产服务 | `support-bot-prod` | 云端 secret manager，部署时注入为环境变量 | 该服务的运行身份 |
| Staging | `support-bot-staging` | 同一个 secret manager，不同的 secret 路径 | Staging 部署角色 |
| CI 评测 | `ci-evals` | CI 的 secret 存储（例如 GitHub Actions secrets） | 只有 pipeline |
| 本地开发 | `dev-<name>` 沙箱 | 列入 `.gitignore` 的 `.env` 文件 | 该开发者 |
| Coding agent | `agent-<name>` 沙箱 | shell 中的 `ANTHROPIC_AUTH_TOKEN`，或 `~/.claude/settings.json` 的 `env` 区块（[在 ATP 上运行 Claude Code](https://atptoken.ai/zh-cn/docs/cb-claude-code)） | 该开发者 |
| 浏览器或移动 App | 无 | 不存放。App 调用你的后端，由后端持有密钥 | 后端以外没有人 |

## ATP Token 的密钥如何工作

ATP Token 是四层结构：组织、工作区、项目、密钥（[设置组织](https://atptoken.ai/zh-cn/docs/console-setup)）。一个密钥只属于一个项目，并继承该项目允许的模型与点数余额。模型权限按项目设置，从不按密钥设置，所以同一个项目里的两个密钥能调用的模型始终相同。

创建密钥的向导会让你填写名称、选择工作区与项目，并可选择先拨入一些起始点数。密钥以 `atp-` 开头、长度 92 个字符，完整密钥只在创建时显示一次，之后只能看到前缀（[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys)）。API 密钥页面列出组织内所有工作区与项目的每一个密钥，可按名称或前缀搜索。吊销的密钥立即失效，并保留在列表中供审计。

追查花费时，用量页面按模型和密钥显示点数与 token，请求日志则记录每次调用的模型、状态、token 数与请求 ID（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。请求日志保留 7 天，事件发生后请尽快检查可疑的密钥。网关在转发请求前会去掉你的 `atp-` 密钥，上游供应商永远看不到它（[工作原理](https://atptoken.ai/zh-cn/docs/how-it-works)）。

谁能做什么由角色决定：Admin 管理成员、资源、密钥与点数分配，Member 则使用自己有权限的内容（[团队与角色](https://atptoken.ai/zh-cn/docs/team)）。

## 迁移流程：从一个共用密钥到项目密钥

| 时间 | 步骤 | 完成标准 |
|---|---|---|
| 第 1 天 | 在代码仓库、CI secrets 和 secret manager 中搜索共用密钥的前缀，列出每个调用方并指定负责人。 | 每个调用方旁边都有一个名字 |
| 第 2–3 天 | 每个调用方建一个项目，选定允许的模型、分配小额预算、发密钥。 | 每个项目的密钥都已放进 secret manager |
| 第 4–10 天 | 先迁非生产环境：staging、CI、沙箱。在 ATP 上要改的是 base URL、`atp-` 密钥和模型 ID（[从 OpenAI 迁移](https://atptoken.ai/zh-cn/docs/cb-migrate-openai)）。 | 非生产环境流量出现在新密钥下 |
| 第 11–20 天 | 生产服务一次迁一个，选低流量时段，每迁完一个就检查该密钥的用量。 | 每个服务的用量都出现在自己的密钥下 |
| 第 21–27 天 | 观察共用密钥。还有流量就说明有漏掉的调用方，找出来迁走。 | 共用密钥连续 7 天没有流量 |
| 第 28 天 | 吊销共用密钥。 | 已吊销，并记录原因与时间 |
| 第 30 天 | 写下泄露处理流程：吊销、在同一项目发新密钥、重新部署、检查该密钥的用量。 | 流程已放进值班手册 |

这份流程最好搭配每个项目的预算，泄露或陷入循环的密钥也会撞到上限。见 [AI API 花费上限对比](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)。

[快速开始：创建项目密钥](https://atptoken.ai/zh-cn/docs/quickstart)

## 延伸阅读

- [模型目录与访问控制](https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control)
- [AI API 花费上限对比](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)
- [企业 AI 治理检查清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist)

## 常见问题

### 什么是 LLM API 的密钥管理？

就是一套规则：谁能拿到 API 密钥、每个密钥能访问什么、存放在哪里、如何轮换与吊销。对 LLM API 来说，它还决定了你能否看出是哪个服务花掉了这笔钱。

### 每位开发者都应该有自己的 OpenAI API 密钥吗？

OpenAI Help Center 建议每位团队成员使用各自的 API 密钥。个人密钥用于个人沙箱；生产服务则给它自己的项目密钥，开发者离职时线上服务才不会跟着停。

### LLM API 密钥泄露时该怎么办？

先吊销，再在同一个项目发一个新密钥、重新部署用到它的服务，并检查该密钥有没有不是你发出的流量。一项目一密钥的话，受影响的只有那一个服务。

### 一个 ATP Token 密钥可以访问多个项目吗？

不可以。ATP Token 密钥只属于一个项目，并继承该项目允许的模型与点数余额。要使用另一个项目，就在那个项目里发密钥。

---

Tags: API 密钥管理, API 密钥, LLM 安全, ATP
