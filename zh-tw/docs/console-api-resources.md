# 資源與成員

> Source: https://atptoken.ai/zh-tw/docs/console-api-resources/

`GET /api/orgs`

讀取你的資源樹 —— 也就是所有用量端點需要的 `org_id`／`workspace_id`／`project_id` 的來源。

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

| 端點 | 回傳 |
|---|---|
| `GET /api/accounts/me` | 你的 account、方案與角色旗標。 |
| `GET /api/orgs` · `GET /api/orgs/{id}` | 可見的組織（可依名稱／類型過濾）。 |
| `GET /api/workspaces` · `GET /api/workspaces/{id}` | 工作區，可依 `org` 過濾。 |
| `GET /api/projects` · `GET /api/projects/{id}` | 專案，可依 `org`／`workspace` 過濾；明細含專案的允許模型清單與 credit。 |
| `GET /api/org-members` | 組織成員（`orgId`）。 |
| `GET /api/workspace-members` | 工作區成員（`workspaceId`）。 |
| `GET /api/project-members` | 專案成員（`projectId`）。 |

列表端點以 `limit`／`page` 分頁（`limit` 上限 100）。
