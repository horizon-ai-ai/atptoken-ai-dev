# OpenAI SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-openai/

直接用官方 OpenAI SDK，不改任何東西。把 base URL 設成 Gateway、帶一把 project API key，並呼叫 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的任一模型。

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai/v1` |
| 驗證 | `Authorization: Bearer atp-…`（SDK 預設） |
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

設 `stream=True` 即可 SSE 串流 — 見 [OpenAI SSE](https://atptoken.ai/zh-tw/docs/sse-openai/)。request 與 response body 就是 OpenAI 的原樣；跟直接呼叫 OpenAI 的唯一差別是 base URL、`atp-` key，以及未在你 project 啟用的模型會回 `403`。完整端點規格：[/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/)。
