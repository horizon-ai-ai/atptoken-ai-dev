# Anthropic SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何东西。把 base URL 设成 Gateway（不用加 `/v1` — SDK 会自己补上 `/v1/messages`）、带一把 project API key，并呼叫 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的任一模型。

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 验证 | `Authorization: Bearer atp-…`（SDK 预设） |
| 模型 | GET /v1/models 的任一 id |

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

设 `stream=True` 即可 SSE 串流 — 见 [Anthropic SSE](https://atptoken.ai/zh-cn/docs/sse-anthropic/)。注意最上层 `system` 栏位必须是字串，阵列形式尚未支援。完整端点规格：[/v1/messages](https://atptoken.ai/zh-cn/docs/messages/)。
