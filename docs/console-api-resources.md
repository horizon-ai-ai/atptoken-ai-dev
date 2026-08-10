# Resources & members

> Source: https://atptoken.ai/docs/console-api-resources/

`GET /api/orgs`

Read your resource tree — the source of the `org_id` / `workspace_id` / `project_id` values every usage endpoint needs.

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

| Endpoint | Returns |
|---|---|
| `GET /api/accounts/me` | Your account, plan and role flags. |
| `GET /api/orgs` · `GET /api/orgs/{id}` | Visible organizations (filter by name/type). |
| `GET /api/workspaces` · `GET /api/workspaces/{id}` | Workspaces, filterable by `org`. |
| `GET /api/projects` · `GET /api/projects/{id}` | Projects, filterable by `org` / `workspace`. The detail view includes the project's allowed-model list and credit. |
| `GET /api/org-members` | Members of an org (`orgId`). |
| `GET /api/workspace-members` | Members of a workspace (`workspaceId`). |
| `GET /api/project-members` | Members of a project (`projectId`). |

List endpoints use `limit` / `page` paging (`limit` capped at 100).
