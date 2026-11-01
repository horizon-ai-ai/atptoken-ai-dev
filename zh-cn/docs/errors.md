# 错误码与处理方式

> Source: https://atptoken.ai/zh-cn/docs/errors/

查 Gateway 回传的状态码代表什么、该先检查哪里，以及怎么处理。

## 状态码

跳到：[400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **联络支持时附上 request_id**
>
> 每个错误回应都带 `request_id`。联络支持时附上它，我们就能找到这一笔。

| 状态码 | 代表什么 | 先检查 | 怎么处理 |
|---|---|---|---|
| `400` | 请求格式错误 | 缺栏位、JSON 格式错误，或用了该格式不支持的写法 | 对照该端点的参数表修正后再送 |
| `401` | 密钥无效 | 有没有带密钥、是否以 `atp-` 开头、是否已停用或过期 | 到「API 密钥」确认或重新建立；header 位置见[验证方式](https://atptoken.ai/zh-cn/docs/auth/) |
| `402` | 点数用完 | 控制台「用量」的可用点数 | 到「账单」充值；团队组织再到「资源」拨点数 |
| `403` | 模型未在此项目开通 | `GET /v1/models` 回传的模型 ID | 改用清单内的模型，或到「资源」替项目加上模型 |
| `429` | 速率限制、配额或供应商冷却中 | 回应的 `Retry-After` | 依 `Retry-After` 等待后重试 |
| `502` | 供应商连线失败或逾时 | — | 可以直接重试 |
| `503` | 这个模型的所有供应商暂时无法使用 | `Retry-After: 60` | 60 秒后重试 |
| `5xx` | 供应商或 Gateway 错误 | 回应里的 `request_id` | 在控制台「请求记录」用 request ID 查询；联络支持时附上 |

## 看请求在哪里被挡下

选一个情境，看请求被哪一道检查挡下、回应长什么样子。

****

_（交互图——请看本页的网页版。）_

## 200 但内容为空

请求可能回传 `200 OK` 却是空消息——不是错误，只是没有文字。这几乎都是由 request 参数造成，而非失败。最常见的原因是 推理模型（extended thinking）的 `max_tokens` 设太低：整个额度在产生任何可见输出前就被内部推理吃完，于是内容回空。

在本平台上，这种请求通常会显示**零 token 用量、也不会扣点数**——空的 `200` 加上空的 `usage`，就是这个情况的特征，不是计费 bug。解法：把 `max_tokens` 调高到「思考预算 + 预期输出」都够用，或关闭 extended thinking。在假设有文字前，一律先检查 `finish_reason` / `stop_reason` 与 `usage`。

## 下一步

- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 三种可接受的密钥位置，以及 `401` 代表什么。
- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 设好 `max_tokens`，让 reasoning 模型产生可见输出。
- [请求记录](https://atptoken.ai/zh-cn/docs/console-api-logs/) — 用 request ID 查出失败的那一笔请求。
