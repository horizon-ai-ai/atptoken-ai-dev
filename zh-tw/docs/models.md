# 列出平台可用模型

> Source: https://atptoken.ai/zh-tw/docs/models/

`GET /v1/models`

這支 API 會列出平台目前可用的所有模型。你可以用它取得正確且最新的 model ID，不需要從行銷頁或 provider dashboard 複製名稱。

> **這份清單是選單，不代表這把 key 的權限**
>
> `GET /v1/models` 不會依 project 範圍過濾。實際可呼叫哪些模型，是由 project 的 allowed list 決定，並在 request time 強制檢查。

平台目錄與 project allowlist 為什麼是兩套控制，見 [模型目錄 vs 存取控制](https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control/)。更完整的導入路徑見 [企業 AI 治理清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist/)。

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

### 模型存取如何運作

_(模型列表請見 https://atptoken.ai/zh-tw/models/)_
