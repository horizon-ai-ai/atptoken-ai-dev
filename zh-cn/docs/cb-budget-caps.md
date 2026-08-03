# 建立带预算上限的团队

> Source: https://atptoken.ai/zh-cn/docs/cb-budget-caps/

沿 organization → workspace → project 树往下拨 credits，给团队自己的花费上限。project 只能花被分配到的额度，所以「分配额」就是上限。

## 1. 建立 Team organization

首次登入（或从 org 切换器）建立一个 **Team** organization — 它能邀请成员并指派角色，这点和 Personal org 不同。见 [设定你的 organization](https://atptoken.ai/zh-cn/docs/console-setup/)。

## 2. 建立 workspace 与 project

在 Resources 建一个 workspace 把相关工作分组，再在里面建 project。选择 project 的 **allowed models** — 只有这些能被它的 key 呼叫。见 [Workspaces 与 projects](https://atptoken.ai/zh-cn/docs/resources/)。

## 3. 拨预算（上限）

Credits 沿树往下流：organization → workspace → project。拨一笔固定金额给 project — 这个金额就是它的天花板。花超过分配额时，project 会被标为 **In debt**，直到再充值。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## 4. 加人并给对的角色

邀请伙伴，在 workspace 或 project 层级指派 Owner / Admin / Member，让他们能用预算但不能搬动它。见 [团队与角色](https://atptoken.ai/zh-cn/docs/team/)。

## 5. 盯著消耗

Usage 页显示每一层的 Allocated 对 Consumed，让你在 project 快到上限前就看得到。见 [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/)。

> **团队额度来自分配，不是钱包**
>
> 在 team organization 里，key 花的是 org 被分配到的 credits — 不是个人钱包。充值是充进你的个人帐户；再从那里于 Resources 拨给 org。见 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

「分配额即上限」的设计理由见 [有效的 AI 花费上限](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work/)。
