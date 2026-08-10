# 用量与余额

> Source: https://atptoken.ai/zh-cn/docs/console-api-usage/

`GET /api/quota/balance`

Credit 沿 Account → Org → Workspace → Project 阶层下放。**只有专案（叶节点）的余额是即时消耗的** —— gateway 每一笔请求都会即时扣减。Org 与 workspace 的余额是转拨池，只在拨款／退回时变动。

#### GET /api/quota/balance

自动化要用的端点。`proj_balance` 读的是 gateway 每笔请求即时扣减的储存，因此即时反映用量；`proj_inflight` 是进行中请求的预留额。

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 组织 id。 |
| workspace_id | string | 加上工作区范围。 |
| project_id | string | 须同时带 workspace_id；回传专案即时余额。 |

```
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"
```

#### GET /api/quota/status

同样的三层余额，以逐层区块呈现。只回「剩余余额」—— credit 模型不储存「期初配额」，因此没有使用率栏位。

#### GET /api/billing/summary

每月用量与计费汇总：指定 `period`（`YYYY-MM`，预设当前 UTC 月份）内各模型的 token 总量、请求数、计量与 credits。**范围级视角** —— 涵盖该 org／workspace／project 下所有 key。

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 组织 id。 |
| period | string | `YYYY-MM`（UTC），预设当月。 |
| workspace_id / project_id | string | 缩小范围。 |

#### GET /api/billing/usage-by-key

每月各 API key 用量。**只回呼叫者本人建立的 key** —— 这是个人视角，不是组织全量报表（全量请用 `billing/summary`）。

#### GET /api/billing/usage-series

单月每日用量趋势（UTC 分桶），支援 `interval` 与 `group_by`。与 usage-by-key 相同为个人视角。

#### GET /api/quota/monthly

历史每月关帐快照（worker 于月底写入），并为未关帐的当月附加一笔 `is_current: true` 合成项。`months` 1–24（预设 6），或以 `period` 查单月。

#### GET /api/quota/history

原始 token 使用纪录（ledger），支援 `since`／`until`／`cursor` 分页。

#### GET /api/billing/wallet

呼叫者 account 层的 plan 与 credit 余额。

> **要轮询哪一个？**
>
> 做自动切换模型或预算告警，请轮询 **`/api/quota/balance`**（三个 id 都带）——它是唯一每笔请求都会更新的值。`billing/summary` 的汇总在数分钟内落帐，适合报表，不适合即时决策。
