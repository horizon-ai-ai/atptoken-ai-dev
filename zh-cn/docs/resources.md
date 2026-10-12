# 工作区与项目

> Source: https://atptoken.ai/zh-cn/docs/resources/

「资源」页是你建立工作区、项目（project），以及在它们之间搬移点数的地方。

## 1. 建立工作区

工作区把多个项目分在一起，并持有一池可往下分配的点数。多数团队会为每个产品或环境用一个工作区。

## 2. 建立项目并挑选允许的模型

在工作区里建立项目，并选择它的 **allowed models**（至少一个）。只有这些模型能被该项目底下的每一把密钥呼叫。模型存取权是设在项目，不是设在单一密钥。

## 3. 分配点数

点数沿树往下流：组织 → 工作区 → 项目。拨一笔预算给项目，它底下的密钥才有额度可花。用词说明见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## 看分配如何运作

拖动滑杆，看拨给项目的点数如何决定它的密钥能不能花。

**谁能花多少** — _示意_

- 组织 Northwind — 10,000 点数
  - 工作区 Product — 收到 4,000 点数
    - 项目 support-bot — 已拨 1,200 点数；模型：claude-sonnet-5, gpt-5.5
      - 密钥 support-bot-prod
      - 密钥 support-bot-staging
    - 项目 web-app — 已拨 1,500 点数；模型：gpt-5.5, deepseek-v4-flash
      - 密钥 web-app-prod
  - 工作区 Media lab — 收到 2,500 点数
    - 项目 video-lab — 已拨 2,500 点数；模型：seedance-2-0
      - 密钥 video-lab-render

- **组织**：持有你充值的点数，往下拨给工作区。
- **工作区**：把项目归为一组，持有一池可再往下拨给项目的点数——不会超过它收到的。
- **项目**：有自己的点数预算与允许模型；项目里每一把密钥只能调用这些模型。
- **密钥**：只属于一个项目，从该项目的余额扣点。

## 下一步

- [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/) — 从刚拨好点数的项目建立密钥。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 可用、已收到、已分配与已用各代表什么。
- [团队与角色](https://atptoken.ai/zh-cn/docs/team/) — 在工作区或项目层级给成员权限。
