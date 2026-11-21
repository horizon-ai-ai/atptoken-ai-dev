# 错误码与处理方式

> Source: https://atptoken.ai/zh-cn/docs/errors/

查 Gateway 回传的状态码代表什么、该先检查哪里，以及怎么处理。**遇到 4xx，要读消息，不要只看状态码。** Gateway 会把模型自己的 4xx 原样转给你，那些消息通常直接写出是哪个栏位、合法值是什么。

## 状态码

跳到：[400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [404](#status-404) · [409](#status-409) · [422](#status-422) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **联络支持时附上 x-request-id**
>
> 每个回应都有 `x-request-id` header，这是回报问题唯一的依据，联络支持时请附上。自己送一个 request id 不会被采用。

| 状态码 | 代表什么 | 先检查 | 怎么处理 |
|---|---|---|---|
| `400` | 请求格式错误。媒体请求常见：缺 `model` 或 prompt、混用不同来源的资产、`asset_not_ready`、`asset_failed` | 错误消息——通常会指出是哪个栏位 | 对照该端点的参数表修正后再送 |
| `401` | 密钥无效或过期：`token_revoked`，消息是「API key has been revoked or does not exist」。**完全没送密钥也是这个错误** | 先确认 header 真的有送出去，再看是否以 `atp-` 开头、是否已停用或过期 | 到「API 密钥」确认或重新建立；header 位置见[验证方式](https://atptoken.ai/zh-cn/docs/auth/) |
| `402` | `insufficient_quota`：点数用完 | 控制台「用量」的可用点数 | 这不是暂时性限流，不要重试。到「账单」充值；团队组织再到「资源」拨点数 |
| `403` | `permission_denied`：这个模型受控，你的项目不在允许清单上。不是密钥或余额的问题 | `GET /v1/project/models` 回传的模型 ID | 换一个模型，或请管理员到「资源」替项目加上模型。不收费 |
| `404` | 网域或路径打错。消息会写 `This domain serves only the LLM Gateway API (/v1, /v1beta)` | base URL 和路径前缀——这个网域只服务 `/v1*` 与 `/omni/*` | 修正 base URL 或路径 |
| `409` | 这把 `Idempotency-Key` 已经指向**另一个**媒体端点的任务 | 是不是把同一把 key 用在影片、图像、语音不同端点 | 换一把新的；每个端点用各自的 key |
| `422` | 这个模型不在这个端点服务（消息会**指名正确的端点**），或这个资产不能给你指定的模型使用 | 消息里写的端点 | 改打那个端点，或改用直接网址而不是资产 |
| `429` | 速率限制（RPM），或这个模型此刻没有可用容量 | 回应的 `Retry-After` | 退避：依 `Retry-After` 等待后重试 |
| `502` | 模型的服务回传错误，或连线失败、逾时 | — | 可以重试 |
| `503` | 两种原因：此刻没有可用容量；或 `balance_check_unavailable`——余额读不到（**不是**余额不足），请求没有开始，也没有扣款 | `Retry-After` | 依 `Retry-After` 等待后重试 |
| `5xx` | 供应商或 Gateway 错误 | 回应的 `x-request-id` header | 在控制台「请求记录」用 request ID 查询；联络支持时附上 |

## 怎么计费

计费以「请求」为单位，不是以「尝试」为单位。一个请求在你的记录里可能有好几列，**不要相加**。

点数在请求开始前先预留，完成后才实际扣款。`403` 在建立请求时就被挡下，不收费。`503 balance_check_unavailable` 的请求没有开始，也没有扣款。

## 看请求在哪里被挡下

选一个情境，看请求被哪一道检查挡下、回应长什么样子。

**一次请求在 ATP 里的路径**

| 步骤 | 检查 | 拦截时 |
| --- | --- | --- |
| 1. 客户端 | 带项目密钥发出 | — |
| 2. 密钥校验 | 密钥有效且已启用 | 401 |
| 3. 模型白名单 | 项目已开通该模型 | 403 |
| 4. 点数 | 项目还有余额 | 402 |
| 5. 限流 | 未超出限制 | 429 |
| 6. 供应商 | 路由与故障转移 | — |
| 7. 记录与计费 | 按点数计量 | — |

| 场景 | 停在 | 状态 | 响应 |
| --- | --- | --- | --- |
| 放行 | 记录与计费 | 200 OK | 响应头：`x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests` — 响应体是供应商的回应，格式与你使用的 SDK 一致。限流响应头告诉你还剩多少额度。 |
| 密钥无效 | 密钥校验 | 401 Unauthorized | `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}` |
| 模型未开通 | 模型白名单 | 403 Forbidden | `{"error":{"message":"model not available for this project","type":"permission_denied","request_id":"..."}}` |
| 点数用完 | 点数 | 402 Payment Required | 错误响应体沿用 SDK 的错误格式：钱包或点数池已用完。充值后恢复；重试没有用。 |
| 被限流 | 限流 | 429 Too Many Requests | 错误响应体沿用 SDK 的错误格式：限流、配额或供应商冷却。退避后重试；有 Retry-After 就按它等。 |

## 200 但内容为空

请求可能回传 `200 OK` 却是空消息——不是错误，只是没有文字。这几乎都是由 request 参数造成，而非失败。最常见的原因是 推理模型（extended thinking）的 `max_tokens` 设太低：整个额度在产生任何可见输出前就被内部推理吃完，于是内容回空。

在本平台上，这种请求通常会显示**零 token 用量、也不会扣点数**——空的 `200` 加上空的 `usage`，就是这个情况的特征，不是计费 bug。解法：把 `max_tokens` 调高到「思考预算 + 预期输出」都够用，或关闭 extended thinking。在假设有文字前，一律先检查 `finish_reason` / `stop_reason` 与 `usage`。

拿到 `200` 也不代表模型看到了你送的全部内容。少一则消息的请求依然合法、依然 `200`；不属于这个端点的写法（例如把 OpenAI 的 `role: "tool"` 送到 `/v1/messages`）会被原样转送——有的模型读得到，有的回 `200` 却当作没收到。要确认内容真的送到，在消息里放一个模型猜不到的值，再请它回答出来。

## 下一步

- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 密钥放在哪里，以及 `401` 代表什么。
- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 设好 `max_tokens`，让 reasoning 模型产生可见输出。
- [请求记录](https://atptoken.ai/zh-cn/docs/console-api-logs/) — 用 request ID 查出失败的那一笔请求。
