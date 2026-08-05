# 模型目录 vs 存取控制：为什么 GET /v1/models 不是密钥权限（2026）

> 来源: https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control/
> 发表于: 2026-08-28 · 作者: hung-chien (AI 增长与品牌经理)

模型目录列出平台能提供什么；存取控制决定项目密钥能呼叫什么。两者混淆会造成 403、影子花费与虚假安全感。

## 重点摘要

- 目录是菜单；项目白名单是许可证。GET /v1/models 回答有没有，不回答准不准。
- 在流量到达供应商前强制白名单，政策才不是 code review 的希望。
- 白名单要搭配预算——获准且无上限仍是账单事件。

模型目录是平台可服务的模型 id 列表；存取控制是决定某项目密钥能呼叫哪些 id 的政策。

**菜单 ≠ 权限。** 在 ATP，列表描述平台；项目白名单强制存取并在违规时 403（[模型](https://atptoken.ai/zh-cn/docs/models)、[how it works](https://atptoken.ai/zh-cn/docs/how-it-works)）。混淆两者会助长[账单爆炸](https://atptoken.ai/zh-cn/blog/why-ai-bills-explode-after-go-live)。

## 每笔请求要回答的两个问题

平台认不认识这模型？**这个项目**可不可以呼叫？**这个项目**付不付得起（[点数](https://atptoken.ai/zh-cn/docs/credits)）？

## 设计白名单

预设拒绝 frontier；按项目不是按人（[一项目一密钥](https://atptoken.ai/zh-cn/blog/one-project-one-key)）；放宽白名单要有管理事件 log（[监控](https://atptoken.ai/zh-cn/docs/monitoring)）；搭配 cap（[花费上限](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work)）；对应用团队说明 403 是政策不是当机（[错误](https://atptoken.ai/zh-cn/docs/errors)）。

## 更现代的做法

ATP Token 在项目设定允许模型，密钥继承，未授权呼叫不到供应商。

[工作区与项目 →](https://atptoken.ai/zh-cn/docs/resources) · [快速开始 →](https://atptoken.ai/zh-cn/docs/quickstart)

## 常见问题

### 模型目录与模型存取控制有何不同？

目录列出平台能路由的模型；存取控制是请求时的项目政策。

### 文件上看得到的模型为什么回 403？

列表常是菜单；不在白名单就在出站前拒绝。

### 每个项目都该开 frontier 模型吗？

不该；预设中阶，有预算与理由再开。

### 白名单如何降低 AI 成本？

防止静默升级高价模型；仍需花费上限。

### 模型政策该放程式码还是平台？

平台强制为最终权威。

## 延伸阅读

- [企业 AI 治理清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist)
- [AI 闸道选型 2026](https://atptoken.ai/zh-cn/blog/ai-gateway-comparison-2026)
- [模型文件](https://atptoken.ai/zh-cn/docs/models)

[申请企业方案 →](https://atptoken.ai/zh-cn/enterprise-plan)

## 常见问题

### 模型目录与模型存取控制有何不同？

目录列出平台能路由的模型；存取控制是请求时允许或拒绝这些模型的项目（或密钥）政策。

### 文件上看得到的模型为什么回 403？

文件与列表端点常是平台菜单。若模型不在项目白名单，治理闸道会在出站前拒绝。

### 每个项目都该开 frontier 模型吗？

不该。高频路径预设中阶；仅在有预算与书面理由的项目启用 frontier。

### 白名单如何降低 AI 成本？

防止应用程序码静默升到高价模型。成本控制仍需花费上限；白名单去掉意外高级路由。

### 模型政策该放程式码还是平台？

平台强制能扛住客户端 bug 与分叉。程式码可给好预设；闸道必须是最终权威。

---

Tags: 模型白名单, AI 闸道, ATP
