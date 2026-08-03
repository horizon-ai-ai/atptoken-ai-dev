# 设定你的 organization

> Source: https://atptoken.ai/zh-cn/docs/console-setup/

Console 里的一切都挂在一个四层结构下。你只会建立一次 organization，然后在里面层层放进 workspace、project 与 key。

| 层级 | 装什么 |
|---|---|
| Organization | Billing 与团队的边界。分 Personal 或 Team。 |
| Workspace | 一个 credit 容器，把相关的 project 分在一起。 |
| Project | 设定允许的模型清单，并持有一份 credit balance。 |
| API key | 范围受限的凭证，继承所属 project 的模型与 credits。 |

首次登入时，onboarding 会请你输入 organization 名称（会自动产生一个选填的小写 slug）。**Team** organization 可以邀请成员并指派角色；**Personal** organization 为单人使用，并会隐藏 Team 页。
