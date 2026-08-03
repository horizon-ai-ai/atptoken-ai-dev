# OpenAI SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-openai/

直接用官方 OpenAI SDK，不改任何东西。把 base URL 设成 Gateway、带一把 project API key，并呼叫 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的任一模型。

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai/v1` |
| 验证 | `Authorization: Bearer atp-…`（SDK 预设） |
| 模型 | GET /v1/models 的任一 id |

```
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

设 `stream=True` 即可 SSE 串流 — 见 [OpenAI SSE](https://atptoken.ai/zh-cn/docs/sse-openai/)。request 与 response body 就是 OpenAI 的原样；跟直接呼叫 OpenAI 的唯一区别是 base URL、`atp-` key，以及未在你 project 启用的模型会回 `403`。完整端点规格：[/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/)。
