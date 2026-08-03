# Anthropic SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何東西。把 base URL 設成 Gateway（不用加 `/v1` — SDK 會自己補上 `/v1/messages`）、帶一把 project API key，並呼叫 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的任一模型。

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 驗證 | `Authorization: Bearer atp-…`（SDK 預設） |
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

設 `stream=True` 即可 SSE 串流 — 見 [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/)。注意最上層 `system` 欄位必須是字串，陣列形式尚未支援。完整端點規格：[/v1/messages](https://atptoken.ai/zh-tw/docs/messages/)。
