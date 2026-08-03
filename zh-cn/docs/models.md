# 列出平台可用模型

> Source: https://atptoken.ai/zh-cn/docs/models/

`GET /v1/models`

这支 API 会列出平台目前可用的所有模型。你可以用它取得正确且最新的 model ID，不需要从行销页或 provider dashboard 复制名称。

> **这份清单是选单，不代表这把 key 的权限**
>
> `GET /v1/models` 不会依 project 范围过滤。实际可呼叫哪些模型，是由 project 的 allowed list 决定，并在 request time 强制检查。

平台目录与 project allowlist 为什么是两套控制，见 [模型目录 vs 存取控制](https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control/)。更完整的导入路径见 [企业 AI 治理清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist/)。

#### Response

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

### 模型存取如何运作

_(模型列表请见 https://atptoken.ai/zh-cn/models/)_
