# OpenAI SDK

> Source: https://atptoken.ai/zh-tw/docs/sdk-openai/

直接用官方 OpenAI SDK，不改任何東西。把 base URL 設成 Gateway、帶一把專案（project） API 金鑰，並呼叫 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳的任一模型。這份清單是 OpenAI 自己的清單端點，列的剛好就是這個 SDK 能在 `/v1/chat/completions` 與 `/v1/responses` 呼叫的模型。

## 設定 client

| 設定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai/v1` |
| 驗證 | `Authorization: Bearer atp-…`（SDK 預設） |
| 模型 | GET /v1/models 的任一 id |

不在這份清單上的模型，你的專案可能還是能用，只是走別的入口——多數 `claude-*` 用 [Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic/)，Gemini 用 [Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google/)。`GET /v1/project/models` 會全部列出。拿它們打這裡會回 `422`，訊息會指名正確的入口。

```
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## 串流，以及與 OpenAI 的差異

設 `stream=True` 即可 SSE 串流——見 [OpenAI SSE](https://atptoken.ai/zh-tw/docs/sse-openai/)。request 與 response body 就是 OpenAI 的原樣。跟直接呼叫 OpenAI 的差別是：base URL、`atp-` 金鑰、未在你專案啟用的模型會回 `403`（不收費），以及 `stream` 的預設值——`/v1/chat/completions` 預設是 `true`（OpenAI 官方是 `false`），`/v1/responses` 預設是 `false`。程式在兩者之間搬動，串流行為會靜默反過來，所以 `stream` 一定要明確送。完整端點規格：[/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/)。

## 下一步

- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 這個端點的參數與回應格式。
- [Server-Sent Events](https://atptoken.ai/zh-tw/docs/sse-openai/) — 設 `stream=True` 時拿到的串流格式。
- [從 OpenAI 遷移](https://atptoken.ai/zh-tw/docs/cb-migrate-openai/) — 把既有的 OpenAI 整合搬到 Gateway。
