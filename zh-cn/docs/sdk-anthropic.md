# Anthropic SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何东西。把 base URL 设成 Gateway（不用加 `/v1`——SDK 会自己补上 `/v1/messages`）、带一把项目（project） API 密钥，并呼叫项目允许、且在 `/v1/messages` 服务的模型。

## 设定客户端

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 验证 | `x-api-key: atp-…`（SDK 默认；`Authorization: Bearer` 也可以） |
| 模型 | 项目允许、在 `/v1/messages` 服务的模型——从 GET /v1/project/models 找 |

不要去 `GET /v1/models` 找 Claude 模型：那是 OpenAI 的清单端点，多数 `claude-*` 不在上面。SDK 的 `models.list()` 打的也是 `/v1/models`，所以不会报错，只会少东西。Anthropic 没有自己的清单端点；完整清单请打 `GET /v1/project/models`。拿不在 `/v1/messages` 服务的模型来打，会回 `422`，消息会指名正确的入口。

## 送出第一个请求

```
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/project/models>",
    max_tokens=256,
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

## 串流与 system prompt

这个入口有三件事要做对：

- `max_tokens` 是必填（OpenAI 那边不是）。
- 要带 `anthropic-version` header；SDK 会自动帮你送，自己发请求的写法见 [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/)。
- `stream` 在这里默认是 `true`，跟 Anthropic 官方相反，所以请明确送。要 SSE 用 `stream=True`（见 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)），要单一 JSON 回应用 `stream=False`。

最上层 `system` 栏位可以是字串，也可以是文字区块阵列。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 完整端点规格
- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — 串流时要读的事件序列
- [在 ATP 上跑 Claude Code](https://atptoken.ai/zh-cn/docs/cb-claude-code/) — 把 Claude Code 指向 Gateway
