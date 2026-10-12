# Anthropic SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何东西。把 base URL 设成 Gateway（不用加 `/v1`——SDK 会自己补上 `/v1/messages`）、带一把项目（project） API 密钥，并呼叫 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的任一模型。

## 设定客户端

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 验证 | `Authorization: Bearer atp-…`（SDK 默认） |
| 模型 | GET /v1/models 的任一 id |

## 送出第一个请求

```
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/models>",
    max_tokens=256,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

## 串流与 system prompt

设 `stream=True` 即可 SSE 串流——见 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)。最上层 `system` 栏位可以是字串，也可以是文字区块阵列。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) — 完整端点规格
- [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/) — 串流时要读的事件序列
- [在 ATP 上跑 Claude Code](https://atptoken.ai/zh-cn/docs/cb-claude-code/) — 把 Claude Code 指向 Gateway
