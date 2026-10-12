# 列出平台可用模型

> Source: https://atptoken.ai/zh-tw/docs/models/

`GET /v1/models`

這支 API 會列出平台可用的所有模型。你可以用它取得正確且最新的模型 ID，不需要從行銷頁或供應商 dashboard 複製名稱。

> **這份清單是選單，不代表這把金鑰的權限**
>
> `GET /v1/models` 不會依專案（project）範圍過濾。實際可呼叫哪些模型，是由專案的 allowed list 決定，並在 request time 強制檢查。

## 回應

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

## 平台目錄與專案權限

平台目錄與專案 allowlist 為什麼是兩套控制，見 [模型目錄 vs 存取控制](https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control/)。更完整的導入路徑見 [企業 AI 治理清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist/)。

### 模型存取如何運作

_(模型列表請見 https://atptoken.ai/zh-tw/models/)_

## 下一步

- [工作區與專案](https://atptoken.ai/zh-tw/docs/resources/) — 在「資源」替專案開通模型。
- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 用這份清單裡的模型 ID 送出請求。
- [模型目錄](https://atptoken.ai/zh-tw/docs/console-api-models/) — 從平台 API 取得各模態的平台級模型清單。
