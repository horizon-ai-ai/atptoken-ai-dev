# 资源与成员

> Source: https://atptoken.ai/zh-cn/docs/console-api-resources/

`GET /api/orgs`

读取你的资源树 —— 也就是所有用量端点需要的 `org_id`／`workspace_id`／`project_id` 的来源。

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

| 端点 | 回传 |
|---|---|
| `GET /api/accounts/me` | 你的 account、方案与角色旗标。 |
| `GET /api/orgs` · `GET /api/orgs/{id}` | 可见的组织（可依名称／类型过滤）。 |
| `GET /api/workspaces` · `GET /api/workspaces/{id}` | 工作区，可依 `org` 过滤。 |
| `GET /api/projects` · `GET /api/projects/{id}` | 专案，可依 `org`／`workspace` 过滤；明细含专案的允许模型清单与 credit。 |
| `GET /api/org-members` | 组织成员（`orgId`）。 |
| `GET /api/workspace-members` | 工作区成员（`workspaceId`）。 |
| `GET /api/project-members` | 专案成员（`projectId`）。 |

列表端点以 `limit`／`page` 分页（`limit` 上限 100）。
