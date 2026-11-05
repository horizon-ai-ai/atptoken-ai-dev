# Workspaces & projects

> Source: https://atptoken.ai/docs/resources/

The Resources page is where you create workspaces and projects and move credits between them.

## 1. Create a workspace

A workspace groups projects and holds a pool of credits you can allocate downward. Most teams use one workspace per product or environment.

## 2. Create a project and pick allowed models

Inside a workspace, create a project and choose its **allowed models** (at least one). Those models — and only those — can be called by every key in the project. Model access is set per project, never per key.

## 3. Allocate credits

Credits flow down the tree: organization → workspace → project. Allocate a budget to the project so its keys have something to spend. See [How credits work](https://atptoken.ai/docs/credits/) for the terminology.

## See how an allocation works

Drag the slider to see how an allocation decides whether a project's keys can spend.

**Who can spend what** — _sample_

- Organization Northwind — 10,000 credits
  - Workspace Product — received 4,000 credits
    - Project support-bot — allocated 1,200 credits; models: claude-sonnet-5, gpt-5.5
      - Key support-bot-prod
      - Key support-bot-staging
    - Project web-app — allocated 1,500 credits; models: gpt-5.5, deepseek-v4-flash
      - Key web-app-prod
  - Workspace Media lab — received 2,500 credits
    - Project video-lab — allocated 2,500 credits; models: seedance-2-0
      - Key video-lab-render

- **Organization**: Holds the credits you top up and allocates them down to workspaces.
- **Workspace**: Groups projects and holds a pool of credits it can allocate to them — never more than it received.
- **Project**: Has its own credit budget and allowed models. Every key in the project can call only those models.
- **Key**: Belongs to exactly one project and spends from that project's balance.

## Next steps

- [Managing API keys](https://atptoken.ai/docs/console-keys/) — Issue a key from the project you just funded.
- [How credits work](https://atptoken.ai/docs/credits/) — What Available, Received, Allocated, and Consumed mean.
- [Team & roles](https://atptoken.ai/docs/team/) — Give people access at the workspace or project level.
