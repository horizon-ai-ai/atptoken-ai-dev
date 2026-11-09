# 列出这把密钥能用的模型

> Source: https://atptoken.ai/zh-cn/docs/models/

`GET /v1/project/models`

`GET /v1/project/models` 列出这把密钥所属项目能放进 `body.model` 的每一个模型 ID。文字、图像、影片、语音、向量模型都在同一份清单。这是唯一一份完整清单。用它取得正确的模型 ID，不需要从行销页或供应商 dashboard 复制名称。

> **能用哪些模型，看项目**
>
> 一把密钥属于一个项目，能用哪些模型由那个项目决定。同一个组织里的另一个项目，开放的模型可能不同。项目没开放的模型，在建立请求时就回 `403`，不收费。

## 完整清单：GET /v1/project/models

```curl
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

#### 回应

```
{
  "data": [
    { "id": "gpt-5.5" },
    { "id": "claude-opus-4-8" },
    { "id": "seedance-2-0" },
    { "id": "text-embedding-3-small" }
  ]
}
```

- 每一笔只有 `id`。这份清单只告诉你**能呼叫什么**，不告诉你**在哪里呼叫**：聊天模型和非同步的影片模型排在一起，没有标记区分。
- 查的是这把密钥自己的项目。没有路径参数，所以一把密钥查不到别的项目。
- 项目没有任何模型时，回 `200` 和 `{"data": []}`。
- 列在清单上的模型，此刻仍可能用不了。「有权限呼叫」和「此刻有地方执行」是两回事；后者会被路由错误挡下。

## 各入口自己的清单

每个聊天入口有自己的清单端点，只列这个入口收得下的模型。某个名字不在这些清单上，通常是因为它在别的入口呼叫。

| 清单 | 列出什么 | 格式 |
|---|---|---|
| `GET /v1/models` | 能在 `/v1/chat/completions` 与 `/v1/responses` 呼叫的模型（OpenAI 的清单端点） | `{"object":"list","data":[{"id":…}]}` |
| `GET /v1beta/models` | 能在 `:generateContent` 与 `:streamGenerateContent` 呼叫的模型（Gemini） | `{"models":[{"name":"models/<id>",…}]}` |

这两份清单不会列出：

- **大部分 `claude-*` 模型。** 它们在 [/v1/messages](https://atptoken.ai/zh-cn/docs/messages/) 呼叫，而 Anthropic 没有自己的清单端点。Anthropic SDK 的 `models.list()` 会去打 `/v1/models`，格式刚好相容，所以不会报错，只会少东西。
- **媒体模型**（影片、图像、语音）。它们在 `/omni/media/v1/...` 的任务路由呼叫。
- **向量模型。** 它们在 `/v1/embeddings` 呼叫。

Gemini 客户端如果钉在 `apiVersion: "v1"`，会去 `/v1/models` 拿清单，拿到 OpenAI 格式，结果解析出 0 个模型。请用 `apiVersion: "v1beta"`，见 [Gemini](https://atptoken.ai/zh-cn/docs/gemini/)。

#### GET /v1/models 的回应

```
{
  "object": "list",
  "data": [
    { "id": "gpt-5.5", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gemini-3-5-flash", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

## 不在清单上，不代表不能用

从模型名称看不出该走哪个入口，要查。每个模型固定在一个入口服务。打错入口会回 `422`，消息会直接告诉你正确的入口：

```
this model is not served on this endpoint; it is available on /v1/messages
```

项目没开放的模型，在建立请求时回 `403`，不收费。项目管理员可以在控制台的「资源」开通模型。

## 平台目录与项目权限

平台目录与项目 allowlist 为什么是两套控制，见 [模型目录 vs 存取控制](https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control/)。更完整的导入路径见 [企业 AI 治理清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist/)。

### 模型存取如何运作

_(模型列表请见 https://atptoken.ai/zh-cn/models/)_

## 下一步

- [工作区与项目](https://atptoken.ai/zh-cn/docs/resources/) — 在「资源」替项目开通模型。
- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 用项目开放的模型 ID 送出请求。
- [模型目录](https://atptoken.ai/zh-cn/docs/console-api-models/) — 从平台 API 取得各模态的平台级模型清单。
