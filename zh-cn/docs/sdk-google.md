# Google GenAI SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-google/

直接用 Google GenAI SDK，不改任何东西。把 base URL 设成 Gateway、以 `x-goog-api-key`（SDK 默认）验证，并呼叫 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传的任一模型。

## 设定 client

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| 验证 | `x-goog-api-key: atp-…`（SDK 默认） |
| 模型 | GET /v1/models 的任一 id |

```
from google import genai

client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai"},
)
r = client.models.generate_content(
    model="<model from GET /v1/models>",
    contents="hi",
)
print(r.text)
```

## 支持的路由

`generateContent` 与 `streamGenerateContent` 路由在 `/v1` 与 `/v1beta`（SDK 默认）底下皆可用。完整端点规格：[/v1/models/{model}:generateContent](https://atptoken.ai/zh-cn/docs/gemini/)。

## 下一步

- [/v1/models/{model}:generateContent](https://atptoken.ai/zh-cn/docs/gemini/) — 这个端点的参数与回应格式。
- [列出平台可用模型](https://atptoken.ai/zh-cn/docs/models/) — 取得要填进 `model` 的模型 ID。
- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 三种可接受的密钥位置，包括 `x-goog-api-key`。
