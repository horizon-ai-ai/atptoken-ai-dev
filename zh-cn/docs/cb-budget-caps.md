# 建立带预算上限的团队

> Source: https://atptoken.ai/zh-cn/docs/cb-budget-caps/

沿组织 → 工作区 → 项目（project）树往下拨点数，给团队自己的花费上限。项目只能花被分配到的额度，所以「分配额」就是上限。

## 1. 建立 Team 组织

首次登录（或从 org 切换器）建立一个 **Team** 组织——它能邀请成员并指派角色，这点和 Personal org 不同。见 [设定你的组织](https://atptoken.ai/zh-cn/docs/console-setup/)。

## 2. 建立工作区与项目

在「资源」建一个工作区把相关工作分组，再在里面建项目。选择项目的 **allowed models**——只有这些能被它的密钥呼叫。见 [工作区与项目](https://atptoken.ai/zh-cn/docs/resources/)。

## 3. 拨预算（上限）

点数沿树往下流：组织 → 工作区 → 项目。拨一笔固定金额给项目——这个金额就是它的天花板。花超过分配额时，项目会被标为 **In debt**，直到再充值。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## 4. 加人并给对的角色

邀请伙伴，在工作区或项目层级指派 Owner / Admin / Member，让他们能用预算但不能搬动它。见 [团队与角色](https://atptoken.ai/zh-cn/docs/team/)。

## 5. 盯著消耗

用量页显示每一层的已分配对已用，让你在项目快到上限前就看得到。见 [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/)。

> **团队额度来自分配，不是钱包**
>
> 在 team 组织里，密钥花的是 org 被分配到的点数——不是个人钱包。充值是充进你的个人账户；再从那里于「资源」拨给 org。见 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

「分配额即上限」的设计理由见 [有效的 AI 花费上限](https://atptoken.ai/zh-cn/blog/ai-spending-caps-that-work/)。

## 下一步

- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 可用、已收到、已分配与已用各代表什么。
- [团队与角色](https://atptoken.ai/zh-cn/docs/team/) — Owner、Admin 与 Member 各能做什么。
- [追踪消耗](https://atptoken.ai/zh-cn/docs/spend/) — 盯著每一层的已分配与已用。
