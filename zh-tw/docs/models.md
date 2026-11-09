# 列出這把金鑰能用的模型

> Source: https://atptoken.ai/zh-tw/docs/models/

`GET /v1/project/models`

`GET /v1/project/models` 列出這把金鑰所屬專案能放進 `body.model` 的每一個模型 ID。文字、圖像、影片、語音、向量模型都在同一份清單。這是唯一一份完整清單。用它取得正確的模型 ID，不需要從行銷頁或供應商 dashboard 複製名稱。

> **能用哪些模型，看專案**
>
> 一把金鑰屬於一個專案，能用哪些模型由那個專案決定。同一個組織裡的另一個專案，開放的模型可能不同。專案沒開放的模型，在建立請求時就回 `403`，不收費。

## 完整清單：GET /v1/project/models

```curl
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

#### 回應

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

- 每一筆只有 `id`。這份清單只告訴你**能呼叫什麼**，不告訴你**在哪裡呼叫**：聊天模型和非同步的影片模型排在一起，沒有標記區分。
- 查的是這把金鑰自己的專案。沒有路徑參數，所以一把金鑰查不到別的專案。
- 專案沒有任何模型時，回 `200` 和 `{"data": []}`。
- 列在清單上的模型，此刻仍可能用不了。「有權限呼叫」和「此刻有地方執行」是兩回事；後者會被路由錯誤擋下。

## 各入口自己的清單

每個聊天入口有自己的清單端點，只列這個入口收得下的模型。某個名字不在這些清單上，通常是因為它在別的入口呼叫。

| 清單 | 列出什麼 | 格式 |
|---|---|---|
| `GET /v1/models` | 能在 `/v1/chat/completions` 與 `/v1/responses` 呼叫的模型（OpenAI 的清單端點） | `{"object":"list","data":[{"id":…}]}` |
| `GET /v1beta/models` | 能在 `:generateContent` 與 `:streamGenerateContent` 呼叫的模型（Gemini） | `{"models":[{"name":"models/<id>",…}]}` |

這兩份清單不會列出：

- **大部分 `claude-*` 模型。** 它們在 [/v1/messages](https://atptoken.ai/zh-tw/docs/messages/) 呼叫，而 Anthropic 沒有自己的清單端點。Anthropic SDK 的 `models.list()` 會去打 `/v1/models`，格式剛好相容，所以不會報錯，只會少東西。
- **媒體模型**（影片、圖像、語音）。它們在 `/omni/media/v1/...` 的任務路由呼叫。
- **向量模型。** 它們在 `/v1/embeddings` 呼叫。

Gemini 客戶端如果釘在 `apiVersion: "v1"`，會去 `/v1/models` 拿清單，拿到 OpenAI 格式，結果解析出 0 個模型。請用 `apiVersion: "v1beta"`，見 [Gemini](https://atptoken.ai/zh-tw/docs/gemini/)。

#### GET /v1/models 的回應

```
{
  "object": "list",
  "data": [
    { "id": "gpt-5.5", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gemini-3-5-flash", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

## 不在清單上，不代表不能用

從模型名稱看不出該走哪個入口，要查。每個模型固定在一個入口服務。打錯入口會回 `422`，訊息會直接告訴你正確的入口：

```
this model is not served on this endpoint; it is available on /v1/messages
```

專案沒開放的模型，在建立請求時回 `403`，不收費。專案管理員可以在主控台的「資源」開通模型。

## 平台目錄與專案權限

平台目錄與專案 allowlist 為什麼是兩套控制，見 [模型目錄 vs 存取控制](https://atptoken.ai/zh-tw/blog/model-catalog-vs-access-control/)。更完整的導入路徑見 [企業 AI 治理清單](https://atptoken.ai/zh-tw/blog/ai-governance-checklist/)。

### 模型存取如何運作

_(模型列表請見 https://atptoken.ai/zh-tw/models/)_

## 下一步

- [工作區與專案](https://atptoken.ai/zh-tw/docs/resources/) — 在「資源」替專案開通模型。
- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 用專案開放的模型 ID 送出請求。
- [模型目錄](https://atptoken.ai/zh-tw/docs/console-api-models/) — 從平台 API 取得各模態的平台級模型清單。
