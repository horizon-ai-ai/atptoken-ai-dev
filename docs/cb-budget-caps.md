# Set up a team with budget caps

> Source: https://atptoken.ai/docs/cb-budget-caps/

Give a team its own spending limit by allocating credits down the organization → workspace → project tree. A project can only spend what it was allocated, so the allocation is the cap.

## 1. Create a Team organization

On first sign-in (or from the org switcher), create a **Team** organization — it can invite members and assign roles, unlike a Personal org. See [Set up your organization](https://atptoken.ai/docs/console-setup/).

## 2. Create a workspace and project

In Resources, create a workspace to group related work, then a project inside it. Choose the project's **allowed models** — only those can be called by its keys. See [Workspaces & projects](https://atptoken.ai/docs/resources/).

## 3. Allocate the budget (the cap)

Credits flow down the tree: organization → workspace → project. Allocate a fixed amount to the project — that amount is its ceiling. When it spends more than allocated, the project is flagged **In debt** until topped up. See [How credits work](https://atptoken.ai/docs/credits/).

## 4. Add people with the right role

Invite teammates and assign Owner / Admin / Member at the workspace or project level, so they can use the budget without being able to move it. See [Team & roles](https://atptoken.ai/docs/team/).

## 5. Watch the spend

The Usage page shows Allocated versus Consumed at each level, so you can see a project approaching its cap before it runs out. See [Tracking spend](https://atptoken.ai/docs/spend/).

> **Team credits come from allocation, not the wallet**
>
> In a team organization, keys spend from the org's allocated credits — not an individual's wallet. Top-ups credit your personal account; allocate from there to the org in Resources. See [Top up & wallet](https://atptoken.ai/docs/topup/).

For the design rationale behind allocation-as-ceiling, see [AI spending caps that work](https://atptoken.ai/blog/ai-spending-caps-that-work/).
