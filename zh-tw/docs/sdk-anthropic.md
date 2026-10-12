# Anthropic SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何東西。把 base URL 設成 Gateway（不用加 `/v1`——SDK 會自己補上 `/v1/messages`）、帶一把專案（project） API 金鑰，並呼叫 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的任一模型。

## 設定客戶端

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 驗證 | `Authorization: Bearer atp-…`（SDK 預設） |
| 模型 | GET /v1/models 的任一 id |

## 送出第一個請求

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

## 串流與 system prompt

設 `stream=True` 即可 SSE 串流——見 [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/)。最上層 `system` 欄位可以是字串，也可以是文字區塊陣列。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) — 完整端點規格
- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — 串流時要讀的事件序列
- [在 ATP 上跑 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code/) — 把 Claude Code 指向 Gateway
