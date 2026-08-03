# Set up your organization

> Source: https://atptoken.ai/docs/console-setup/

Everything in the console hangs off a four-level hierarchy. You create an organization once, then nest workspaces, projects, and keys inside it.

| Level | What it holds |
|---|---|
| Organization | The billing and team boundary. Either Personal or Team. |
| Workspace | A credit container that groups related projects. |
| Project | Sets the allowed model list and holds a credit balance. |
| API key | A scoped credential that inherits its project's models and credits. |

On first sign-in, onboarding asks for an organization name (an optional lowercase slug is auto-generated). A **Team** organization can invite members and assign roles; a **Personal** organization is single-user and hides the Team page.
