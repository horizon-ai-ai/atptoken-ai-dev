# Console API — 用 API 查用量、帐务与资源

> Source: https://atptoken.ai/zh-cn/docs/console-api/

网页 Console 看得到的资料，都有对应的 REST API：`https://admin.atptoken.ai/api` —— 即时余额、每月各模型用量、计费活动、模型目录、组织／工作区／专案结构。可用来做仪表板、预算告警、或自动切换模型。

完整且永远与实作同步的规格是线上 Swagger：[admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs)，以下各页的每个端点都能在那里直接试打。

> **两种凭证，不要混用**
>
> **`atp-` API key** 只用于资料面（`api.atptoken.ai` —— chat、媒体、embeddings）。Console API 使用 **`POST /api/users/login` 取得的 session token**（Console 帐号密码）。对 Console API 端点送 `atp-` key 一律回 `401`，换哪个端点都一样。

#### 认证

```
curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}'
# → { "token": "<JWT>", "exp": ..., "user": { ... } }
```

回传的 `token` 为 Bearer token，效期约 **2 小时**。长期执行的脚本遇到 `401` 应重新登入，不要永久快取 token。`POST /api/users/logout` 可撤销当前 session。

#### 快速开始 —— 轮询余额、切换模型

最常见的整合情境：监看专案即时余额，低于门槛时切换到较便宜的模型。

```
# 1) Login (console credentials, NOT the atp- API key)
TOKEN=$(curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}' | jq -r .token)

# 2) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 3) Current-month usage per model
curl -sS "https://admin.atptoken.ai/api/billing/summary?org_id=<org>" \
  -H "Authorization: Bearer $TOKEN"
```

#### 查自己的 ID

多数端点需要 `org_id`／`workspace_id`／`project_id` 查询参数，用以下端点列出：

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

#### 分页导览

- [用量与余额](https://atptoken.ai/zh-cn/docs/console-api-usage/) —— 即时余额、每月用量、各 key 用量、趋势、钱包
- [帐务与储值](https://atptoken.ai/zh-cn/docs/console-api-billing/) —— 计费活动、储值纪录、结帐连结、credit 调整历史
- [模型目录](https://atptoken.ai/zh-cn/docs/console-api-models/) —— 各模态平台级模型清单（chat／image／video／audio／embedding）
- [资源与成员](https://atptoken.ai/zh-cn/docs/console-api-resources/) —— 组织、工作区、专案、成员、我的帐号
- [请求日志](https://atptoken.ai/zh-cn/docs/console-api-logs/) —— 逐请求观测纪录（保留 7 天）

- 400 — 参数缺漏或格式错误（多数端点必带 `org_id`）。
- 401 — session token 缺失／过期，或误用了 `atp-` API key。
- 403 — 已认证但无此范围的存取权。
- 404 — 可见范围内找不到资源。
