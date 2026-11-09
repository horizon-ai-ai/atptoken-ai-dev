# Google GenAI SDK

> Source: https://atptoken.ai/zh-cn/docs/sdk-google/

直接用 Google GenAI SDK（`google-genai`：Python 是 `from google import genai`，Node 是 `@google/genai`），不改任何东西。旧的 `google-generativeai` 已弃用。把 base URL 设成 Gateway、`apiVersion` 设 `v1beta`，以 `x-goog-api-key`（SDK 默认）验证，并呼叫在这个入口服务的模型。

## 设定 client

| 设定 | 值 |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| API 版本 | `v1beta` |
| 验证 | `x-goog-api-key: atp-…`（SDK 默认） |
| 模型 | GET /v1beta/models 的任一 id |

`GET /v1beta/models` 是 Gemini 自己的清单端点，只列能在 `:generateContent`／`:streamGenerateContent` 呼叫的模型。`GET /v1/models` 是 OpenAI 的清单，不是这一份。要看项目在所有入口允许的全部模型，打 `GET /v1/project/models`。不在这里服务的模型会回 `422`，消息会指名正确的入口。

```
from google import genai

client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai", "api_version": "v1beta"},
)
r = client.models.generate_content(
    model="<model from GET /v1beta/models>",
    contents="hi",
)
print(r.text)
```

## 支持的路由

`generateContent` 与 `streamGenerateContent` 路由在 `/v1` 与 `/v1beta` 底下皆可用。模型放在网址里，不放在 body。这里没有 `stream` 栏位：要串流就改打 `:streamGenerateContent`。完整端点规格：[/v1/models/{model}:generateContent](https://atptoken.ai/zh-cn/docs/gemini/)。

> **apiVersion 要维持 v1beta**
>
> 钉在 `v1` 的客户端会去 `/v1/models` 拿模型清单，那是 OpenAI 的端点、回 OpenAI 的格式，SDK 会解析出 0 个模型，而且不会报错。聊天呼叫不受影响，受影响的只有清单。

用 Gemini 上传协定（`/upload/v1beta/files`）传的文件，这个入口的模型拿不到——引用它会回错。图片和音讯请改用 `inlineData` 直接内嵌。

## 下一步

- [/v1/models/{model}:generateContent](https://atptoken.ai/zh-cn/docs/gemini/) — 这个端点的参数与回应格式。
- [列出平台可用模型](https://atptoken.ai/zh-cn/docs/models/) — 取得要填进 `model` 的模型 ID。
- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 密钥可以放在哪些位置，包括 `x-goog-api-key`。
