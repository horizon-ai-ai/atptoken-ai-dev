# 控制台 API——用 API 查用量、帐务与资源

> Source: https://atptoken.ai/zh-cn/docs/console-api/

ATP Token 网页控制台看得到的数据，都有对应的 REST API：`https://admin.atptoken.ai/api`——即时余额、每月各模型用量、计费活动、模型目录、组织／工作区／项目（project）结构。可用来做仪表板、预算告警、或自动切换模型。

完整且永远与实作同步的规格是线上 Swagger：[admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs)，以下各页的每个端点都能在那里直接试打。同一份规格也有一份静态、方便 agent 读取的镜像版本，含 operation ID 与型别化参数，发布于 [/openapi.json](https://atptoken.ai/openapi.json)。

## 认证

> **两种凭证，不要混用**
>
> **`atp-` API 密钥** 只用于数据面（`api.atptoken.ai`——chat、媒体、embeddings）。控制台 API 使用 **某个已登录真人的 session token**。对控制台 API 端点送 `atp-` 密钥一律回 `401`，换哪个端点都一样。

### 要有一个真人登录

`POST /api/users/login` 的 body 必须带人机验证的答案，而只有浏览器产生得出来。控制台 API 没有 API 密钥、没有服务账号，也没有给机器登录的端点：这几页上的每一个呼叫，用的都是某个真人在 [atptoken.ai](https://atptoken.ai) 登录后拿到的 session token。

这是一个决定，不是还没做完的功能。登录页正是脚本猜密码会打的地方，而原本唯一的防线——单一账号的失败次数上限——罚错了人：脚本换下一个账号继续猜，被锁在外面的却是真正的持有人。人机验证在第一个请求就挡下整轮，所以它对每一次登录都生效，没有门槛可以跨过，也没有例外可以申请。

在浏览器登录之后，控制台把那个 session token 放在 `localStorage` 的 `atp_token`——它就是以下范例里的 `$TOKEN`。这是 Bearer token，效期约 **2 小时**，`POST /api/users/logout` 可以提前结束它。

### 这代表什么事做不到

脚本不能自己登录，也就不能让自己一直保持认证：token 过期之后，要有一个人重新登录。控制台 API 适合「手上有 session 时才跑」的工作——出报表、对账、追一个失败的请求——而不是一个长期无人看管的服务。

如果你要的是完全不需要 session 的花费上限，请改用点数分配，而不是监看余额：项目只能花掉被分配到的额度，而且是 Gateway 在每一个请求上执行。见[建立带预算上限的团队](https://atptoken.ai/zh-cn/docs/cb-budget-caps/)。

## 轮询余额、切换模型

最常见的整合情境：监看项目即时余额，低于门槛时切换到较便宜的模型。它能跑多久取决于 session token 的效期：token 过期之后，要有一个人重新登录。

```
# $TOKEN is one signed-in person's session token (see Authentication)

# 1) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 2) Current-month usage per model
curl -sS "https://admin.atptoken.ai/api/billing/summary?org_id=<org>" \
  -H "Authorization: Bearer $TOKEN"
```

## 查自己的 ID

多数端点需要 `org_id`／`workspace_id`／`project_id` 查询参数，用以下端点列出：

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

## 端点分组

- [用量与余额](https://atptoken.ai/zh-cn/docs/console-api-usage/)——即时余额、每月用量、各密钥用量、趋势、钱包
- [帐务与充值](https://atptoken.ai/zh-cn/docs/console-api-billing/)——计费活动、充值记录、结帐连结、点数调整历史
- [模型目录](https://atptoken.ai/zh-cn/docs/console-api-models/)——各模态平台级模型清单（chat／image／video／audio／embedding）
- [资源与成员](https://atptoken.ai/zh-cn/docs/console-api-resources/)——组织、工作区、项目、成员、我的账号
- [请求记录](https://atptoken.ai/zh-cn/docs/console-api-logs/)——逐请求观测记录（保留 7 天）

## 错误

- 400 — 参数缺漏或格式错误（多数端点必带 `org_id`）。
- 400 — `POST /api/users/login` 回 `captcha_required` 或 `captcha_invalid`：人机验证没有通过。脚本过不了，请在浏览器登录。
- 401 — session token 缺失／过期，或误用了 `atp-` API 密钥。
- 403 — 已认证但无此范围的存取权。
- 404 — 可见范围内找不到资源。

## 下一步

- [用量与余额](https://atptoken.ai/zh-cn/docs/console-api-usage/) — 读取项目即时余额与每月用量。
- [资源与成员](https://atptoken.ai/zh-cn/docs/console-api-resources/) — 查出多数端点需要的组织、工作区与项目 ID。
- [请求记录](https://atptoken.ai/zh-cn/docs/console-api-logs/) — 依状态码或 request ID 找出失败的请求。
