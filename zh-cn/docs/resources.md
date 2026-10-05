# Workspaces 与 projects

> Source: https://atptoken.ai/zh-cn/docs/resources/

Resources 页是你建立 workspace、project，以及在它们之间搬移 credits 的地方。

## 1. 建立 workspace

Workspace 把多个 project 分在一起，并持有一池可往下分配的 credits。多数团队会为每个产品或环境用一个 workspace。

## 2. 建立 project 并挑选允许的模型

在 workspace 里建立 project，并选择它的 **allowed models**（至少一个）。只有这些模型能被该 project 底下的每一把 key 呼叫。模型存取权是设在 project，不是设在单一 key。

## 3. 分配 credits

Credits 沿树往下流：organization → workspace → project。拨一笔预算给 project，它底下的 key 才有额度可花。用词说明见 [点数如何运作](#credits)。

拖动滑块，看拨给 project 的点数如何决定它的 key 能不能花。

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
