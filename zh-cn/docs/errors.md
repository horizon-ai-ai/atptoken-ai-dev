# 常见回应

> Source: https://atptoken.ai/zh-cn/docs/errors/

所有错误回应都含一个 `request_id` — 联络支援时请附上。错误外层格式会跟随你呼叫的 SDK 格式（OpenAI / Anthropic / Gemini）。

- 400 — Bad request — 缺栏位、body 格式错误，或不支援的功能（例如 Anthropic system 用阵列）。
- 401 — API key 缺失、被停用、过期或无法辨识。
- 402 — 钱包或 credit 池已耗尽。充值后即可恢复。
- 403 — 该模型未在此 project 启用。
- 429 — 速率限制、配额，或 provider 冷却中。若有 Retry-After 请遵守。
- 502 — Provider 连线失败或逾时。可安全重试。
- 503 — 该模型的所有 provider 皆 circuit-open。Retry-After: 60。
- 5xx — Provider 或 Gateway 错误。请查 Console 的 request logs。

选一个场景，看请求被哪一道检查拦下、响应长什么样子。

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

### 200 但内容为空

请求可能回传 `200 OK` 却是空讯息 — 不是错误，只是没有文字。这几乎都是由 request 参数造成，而非失败。最常见的原因是 reasoning(extended thinking)模型的 `max_tokens` 设太低：整个额度在产生任何可见输出前就被内部推理吃完，于是内容回空。

在本平台上，这种请求通常会显示**零 token 用量、也不会扣 credits**——空的 `200` 加上空的 `usage`，就是这个情况的特征，不是计费 bug。解法：把 `max_tokens` 调高到「思考预算 + 预期输出」都够用，或关闭 extended thinking。在假设有文字前，一律先检查 `finish_reason` / `stop_reason` 与 `usage`。
