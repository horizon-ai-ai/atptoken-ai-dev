# 什么是 Shadow AI（影子 AI）？风险、实例与收回管控的方法（2026）

> 来源: https://atptoken.ai/zh-cn/blog/shadow-ai-governed-control-plane/
> 发表于: 2026-09-02 · 作者: hung-chien (AI 增长与品牌经理)

Shadow AI 是员工未经 IT 批准使用 AI 工具、账号或 API 密钥。整理 5 个实例、IBM 与 Verizon 2025 数据、发现方法，以及如何用批准路径取代。

## 重点摘要

- Shadow AI 是在 IT 未批准、未监督的情况下使用 AI 工具、账号或 API 密钥。IBM 2025 年数据泄露研究中，每五家组织就有一家报告曾因 Shadow AI 发生泄露。
- 常见形态是个人聊天机器人账号、刷公司卡的个人 API 密钥、未经评审就开启的 SaaS AI 功能、浏览器插件，以及未经批准的编程智能体。报销单、SSO 日志、DNS 日志与密钥扫描能找出大部分。
- 一刀切禁止只会让使用转到你看不到的地方。改为提供更快的批准路径：几分钟内拿到项目密钥、模型白名单、小额沙盒预算与逐条请求日志。

按照 [IBM 的定义](https://www.ibm.com/think/topics/shadow-ai)，Shadow AI（影子 AI）是员工在 IT 部门未正式批准或监督的情况下使用 AI 工具或应用。实际中，它可能是一个粘贴了客户合同的个人 ChatGPT 账号，也可能是一个每晚刷公司卡、用个人 API 密钥运行的脚本。本文整理五种具体形态、2025 年的数据、四种发现方法，以及一套让批准路径比影子路径更快的配置。

## Shadow AI 一览

| 形态 | 什么数据离开公司 | 谁付钱 | 最先在哪里看到 |
|---|---|---|---|
| 个人聊天机器人账号 | 粘贴的文本与上传的文件 | 员工自付或报销 | DNS 日志、浏览器遥测 |
| 脚本里的个人 API 密钥 | 脚本发出的任何内容 | 公司卡，事后报销 | 报销单 |
| 未经评审就开启的 SaaS AI 功能 | 原本就在该 SaaS 里的数据 | 包含在 SaaS 账单里 | 厂商管理后台、续约时 |
| AI 浏览器插件 | 它能读到的页面内容 | 通常免费 | 终端资产清单、OAuth 授权 |
| 未经批准的编程智能体 | 源代码与上下文里的密钥 | 个人密钥或订阅 | 密钥扫描、出口流量日志 |

Shadow AI 是 Shadow IT 的一个子集。区别在于每一次提示都是一次数据传输，而 API 用量按 token 计费，所以一个没人审过的脚本，可能在同一周同时带来数据问题和费用问题。

## Shadow AI 有多普遍：2025 年数据

[IBM 2025 年数据泄露成本报告](https://newsroom.ibm.com/2025-07-30-ibm-report-13-of-organizations-reported-breaches-of-ai-models-or-applications,-97-of-which-reported-lacking-proper-ai-access-controls)（2025 年 7 月发布）指出：

- 每五家组织就有一家报告曾因 Shadow AI 发生泄露。
- Shadow AI 程度高的组织，泄露成本比程度低或没有的组织平均高出 67 万美元。
- 13% 的组织报告 AI 模型或应用遭入侵，其中 97% 缺乏适当的 AI 访问控制。
- 只有 37% 的组织有管理 AI 或发现 Shadow AI 的制度。

[Verizon 2025 年数据泄露调查报告（DBIR）](https://www.verizon.com/business/resources/reports/2025-dbir-data-breach-investigations-report.pdf)补充了身份这一面：15% 的员工经常在公司设备上使用生成式 AI；其中 72% 以非公司邮箱作为账号标识，17% 使用公司邮箱但没有集成身份认证。

72% 这个数字和离职流程直接相关。用个人邮箱注册的账号不在你的身份提供方管理范围内，停用员工的 SSO 登录并不会关掉它。

## 五个 Shadow AI 实例

### 1. 用个人 ChatGPT 或 Claude 账号处理公司数据

财务分析师把董事会备忘录草稿粘贴进个人聊天机器人账号，让它帮忙润色。这份数据从此按照这个人自己注册的套餐条款被处理，安全团队完全不知情。

### 2. 脚本里的个人 API 密钥，刷公司卡

销售运营分析师写了一个脚本，每晚用 GPT-5.5 总结 2,000 份通话转写稿。每份 6,000 个输入 token、800 个输出 token，合计 1,200 万输入 token（60 美元）与 160 万输出 token（48 美元），按 OpenAI [公开价格](https://developers.openai.com/api/docs/pricing)每 100 万 token 输入 5 美元、输出 30 美元计算（截至 2026 年 10 月）。一晚约 108 美元，30 天约 3,240 美元，以「软件」名义报销，没有任何上限。

### 3. 已批准 SaaS 里被开启的 AI 功能

CRM 或客服系统推出 AI 助手，某位工作区管理员就把它打开了。这家厂商几年前只针对数据存储做过评审，新功能却把同样的数据发给模型厂商，适用的条款没有人重新读过。

### 4. 浏览器插件

一个「AI 帮你总结这一页」的插件，需要读取员工打开的每一个页面，包括内部管理后台和人事系统。因为免费，它从来不会出现在采购流程里。

### 5. 未经批准的编程智能体

外包工程师用个人密钥让编程智能体在公司 monorepo 上工作。智能体把 `.env` 文件读进上下文，合同结束后仍能继续运行，因为密钥是外包工程师自己的。

## Shadow AI 的风险

### 数据

提示和上传的文件在没有分级的情况下离开公司。适用的数据保留与训练条款，是员工个人套餐的条款，法务没有审过。

### 费用

刷在个人卡上的 token 计费，没有上限，也没有负责人。财务只看到一连串小额报销，总数要等有人把一个季度的报销单加起来才会出现。

### 离职

绑在个人身上的密钥和账号，在人离开后仍然有效。外包工程师离职后，能吊销那把个人密钥的只有他自己。

### 审计

客户的安全问卷问到「哪些 AI 厂商处理我们的数据」时，你需要一份厂商清单和请求日志。影子用量不会留下任何可以拿出来的记录。

## 怎么发现 Shadow AI

以下四个来源与厂商无关，多数公司手上已经有。

1. 报销单与信用卡账单。搜索过去 12 个月 AI 厂商与 AI SaaS 工具的商户名称。同一位员工每月固定的小额扣款，通常意味着有个人 API 密钥在生产环境里跑。
2. SSO 与 OAuth 授权日志。列出用户通过「使用某账号登录」授权过的第三方应用，筛出不在批准清单上的 AI 工具和插件。
3. 出口流量与 DNS 日志。查看本不该调用 AI 厂商 API 域名的服务器和 CI runner 是否有连接，以及笔记本上看起来像脚本在跑的流量。
4. 密钥扫描。用你的密钥扫描工具扫代码仓库、CI 变量和 notebook，查找 AI 厂商密钥的格式。每一条命中既是需要轮换的泄露，也是一条需要迁移的使用路径。

把结果当作迁移清单来用。如果大家因为扫描结果受到处罚，下一次扫到的会变少，实际用量却还在。

## 怎么把 Shadow AI 收回管控

影子路径大约五分钟：注册、绑卡、复制密钥。批准路径要接近这个速度，否则大家会继续走影子路径。让批准路径有竞争力的四件事：

- 几分钟内就能拿到项目密钥，每加一个新模型不必走一次采购流程。
- 每个项目一份模型白名单，访问权限决定一次，每次调用都强制执行。
- 一笔小额沙盒预算，不会变成意外账单。
- 逐条请求日志，看得出每次调用来自哪个项目、哪把密钥、哪个模型。

## 在 ATP Token 上怎么配置

ATP Token 让每个团队用一把项目密钥，通过 OpenAI、Anthropic 与 Gemini SDK 使用 11 家厂商的 70+ 个模型，上述管控都在网关层执行。

### 第 1 步：创建 Team 组织与沙盒工作区

创建 Team 组织，才能邀请成员和分配角色；然后在生产工作区旁边新增一个实验用工作区。见[设置组织](https://atptoken.ai/zh-cn/docs/console-setup)。

### 第 2 步：每个团队建一个项目并选择允许的模型

在 Resources 页面创建项目，选择允许的模型（至少一个）。调用清单以外的模型，会在发到任何厂商之前就返回 `403`，流程见[工作原理](https://atptoken.ai/zh-cn/docs/how-it-works)。想先比较模型的人，可以在写代码之前先到控制台的 Studio 试用。

### 第 3 步：分配一笔小额预算

例如分配 2,000 点数（20 美元，1 点数 = 0.01 美元）给沙盒项目。项目只能花被分配到的额度，分配额就是上限；余额用完时请求会返回 `402`。操作步骤见[团队预算上限配置](https://atptoken.ai/zh-cn/docs/cb-budget-caps)，额度怎么定可参考[有效的 AI 花费上限](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)。

### 第 4 步：发一把密钥，换掉影子脚本里的那把

密钥以 `atp-` 开头，只显示一次。以实例 2 的转写稿脚本为例，要改的只有 base URL 和密钥：

```python
import os
from openai import OpenAI

client = OpenAI(
    base_url="https://api.atptoken.ai/v1",
    api_key=os.environ["ATP_API_KEY"],  # 项目密钥
)
```

实例 5 的编程智能体，则用环境变量把 Claude Code 指向网关，做法见[在 ATP 上运行 Claude Code](https://atptoken.ai/zh-cn/docs/cb-claude-code)：

```bash
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"
```

模型 ID 必须在项目的允许清单上，例如 [Claude Sonnet 4.6](https://atptoken.ai/zh-cn/models/claude-sonnet-4-6/)。

### 第 5 步：用正确的角色添加成员

在工作区或项目层级以 Member 身份邀请同事，他们可以使用预算但不能调拨；Admin 负责管理密钥与分配。见[团队与角色](https://atptoken.ai/zh-cn/docs/team)。

### 第 6 步：查看用量，离职时吊销密钥

用量页按模型和密钥拆分点数与 token。请求日志逐条列出时间、范围、模型、状态、请求 ID 与 token 数，保留 7 天，定位是排障用。活动日志则记录登录、邀请与额度变更（[用量与日志](https://atptoken.ai/zh-cn/docs/monitoring)）。有人离职时，在 API 密钥页吊销他的项目密钥：吊销后立即失效，并保留在列表中供审计（[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys)）。

ATP 只看得到经过它的流量。聊天机器人账号、插件和 SaaS 功能仍要靠上面的发现方法；变化在于，你找到的脚本和智能体有了一条批准的路可以迁过去。

[快速开始](https://atptoken.ai/zh-cn/docs/quickstart)

## 延伸阅读

- [一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)
- [模型目录与访问控制](https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control)
- [AI 治理清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist)

## 常见问题

### 什么是 Shadow AI？

Shadow AI（影子 AI）是员工在 IT 部门未批准、未监督的情况下使用 AI 工具、应用、账号或 API 密钥。典型情况是用个人 ChatGPT 或 Claude 账号处理公司数据，或在公司脚本里使用个人 API 密钥。

### Shadow AI 有哪些实例？

常见例子包括：用个人聊天机器人账号总结客户文档、在脚本里放个人 API 密钥并刷公司卡、在已批准的 SaaS 工具里未经评审就开启 AI 功能、安装 AI 浏览器插件，以及在批准工具清单之外使用编程智能体。

### Shadow AI 有什么风险？

主要风险是公司数据按照没人审过的条款被处理、费用挂在没有上限的个人卡上、离职后访问权限仍在，以及审计时拿不出任何记录。IBM 2025 年数据泄露成本报告指出，Shadow AI 程度高的组织，泄露成本平均高出 67 万美元。

### 怎么发现 Shadow AI？

先从手上已有的四个来源入手：报销单与信用卡账单、SSO 与 OAuth 授权日志、访问 AI 厂商域名的出口流量与 DNS 日志，以及对代码仓库与 CI 变量的密钥扫描。

### 禁止 AI 工具能阻止 Shadow AI 吗？

通常不能。大家会把工作挪到个人设备和账号上，你的日志里反而看不到。真正能减少 Shadow AI 的，是一条和个人路径一样快上手、又内置预算与日志的批准路径。

---

Tags: Shadow AI, AI 治理, ATP
