# 列出平台可用模型

> Source: https://atptoken.ai/zh-cn/docs/models/

`GET /v1/models`

这支 API 会列出平台可用的所有模型。你可以用它取得正确且最新的模型 ID，不需要从行销页或供应商 dashboard 复制名称。

> **这份清单是选单，不代表这把密钥的权限**
>
> `GET /v1/models` 不会依项目（project）范围过滤。实际可呼叫哪些模型，是由项目的 allowed list 决定，并在 request time 强制检查。

## 回应

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

## 平台目录与项目权限

平台目录与项目 allowlist 为什么是两套控制，见 [模型目录 vs 存取控制](https://atptoken.ai/zh-cn/blog/model-catalog-vs-access-control/)。更完整的导入路径见 [企业 AI 治理清单](https://atptoken.ai/zh-cn/blog/ai-governance-checklist/)。

### 模型存取如何运作

_(模型列表请见 https://atptoken.ai/zh-cn/models/)_

## 下一步

- [工作区与项目](https://atptoken.ai/zh-cn/docs/resources/) — 在「资源」替项目开通模型。
- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 用这份清单里的模型 ID 送出请求。
- [模型目录](https://atptoken.ai/zh-cn/docs/console-api-models/) — 从平台 API 取得各模态的平台级模型清单。
