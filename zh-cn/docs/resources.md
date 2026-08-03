# Workspaces 与 projects

> Source: https://atptoken.ai/zh-cn/docs/resources/

Resources 页是你建立 workspace、project，以及在它们之间搬移 credits 的地方。

## 1. 建立 workspace

Workspace 把多个 project 分在一起，并持有一池可往下分配的 credits。多数团队会为每个产品或环境用一个 workspace。

## 2. 建立 project 并挑选允许的模型

在 workspace 里建立 project，并选择它的 **allowed models**（至少一个）。只有这些模型能被该 project 底下的每一把 key 呼叫。模型存取权是设在 project，不是设在单一 key。

## 3. 分配 credits

Credits 沿树往下流：organization → workspace → project。拨一笔预算给 project，它底下的 key 才有额度可花。用词说明见 [点数如何运作](#credits)。
