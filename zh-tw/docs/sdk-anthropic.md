# Anthropic SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-anthropic/

直接用官方 Anthropic SDK，不改任何東西。把 base URL 設成 Gateway（不用加 `/v1`——SDK 會自己補上 `/v1/messages`）、帶一把專案（project） API 金鑰，並呼叫專案允許、且在 `/v1/messages` 服務的模型。

## 設定客戶端

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 驗證 | `x-api-key: atp-…`（SDK 預設；`Authorization: Bearer` 也可以） |
| 模型 | 專案允許、在 `/v1/messages` 服務的模型——從 GET /v1/project/models 找 |

不要去 `GET /v1/models` 找 Claude 模型：那是 OpenAI 的清單端點，多數 `claude-*` 不在上面。SDK 的 `models.list()` 打的也是 `/v1/models`，所以不會報錯，只會少東西。Anthropic 沒有自己的清單端點；完整清單請打 `GET /v1/project/models`。拿不在 `/v1/messages` 服務的模型來打，會回 `422`，訊息會指名正確的入口。

## 送出第一個請求

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

## 串流與 system prompt

這個入口有三件事要做對：

- `max_tokens` 是必填（OpenAI 那邊不是）。
- 要帶 `anthropic-version` header；SDK 會自動幫你送，自己發請求的寫法見 [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/)。
- `stream` 在這裡預設是 `true`，跟 Anthropic 官方相反，所以請明確送。要 SSE 用 `stream=True`（見 [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/)），要單一 JSON 回應用 `stream=False`。

最上層 `system` 欄位可以是字串，也可以是文字區塊陣列。

## 下一步

- [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) — 完整端點規格
- [Anthropic SSE](https://atptoken.ai/zh-tw/docs/sse-anthropic/) — 串流時要讀的事件序列
- [在 ATP 上跑 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code/) — 把 Claude Code 指向 Gateway
