# 点数如何运作

> Source: https://atptoken.ai/zh-cn/docs/credits/

用量是用 credits 支付。**1 credit = USD 0.01**（100 credits = USD 1）。按量付费（PAYG）的 credits 不会过期（合约承诺的 contract credits 可能带到期日 — 见「充值与钱包」）。余额显示到小数点后四位；非零但低于此的金额会显示为 `<0.0001`。

Credits 沿阶层往下流 — organization → workspace → project — 一把 key 从其 project 的余额扣款。每一层都回报相同的四个数字：

| 用词 | 意义 |
|---|---|
| Available | 这一层可花费或可分配的 credits。 |
| Received | 从上一层收到的 credits 总额。 |
| Allocated | 已往下拨给子 workspace 或 project 的 credits。 |
| Consumed | 实际花在 API 呼叫上的 credits（project 层级）。 |

若某个 project 花得比被分配的还多，会被标为 **In debt**，直到再充值为止。
