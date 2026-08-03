# Provider routing 與 fallback

> Source: https://atptoken.ai/zh-tw/docs/provider-routing/

平台上每個模型由一個或多個上游 provider 組成的 pool 服務。你呼叫單一 model id；Gateway 為該請求挑一個 provider，並可 fail over 到另一個，因此就算某個 provider 降級，模型仍能持續運作。

### 一個 model id，背後一個 pool

每個模型的 provider 組合與順序是設在平台端，不是逐請求指定。你的 client 永遠只指名模型（來自 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/)）；實際由哪個 provider 服務由 Gateway 處理，且可在請求之間改變，你這端不需改任何 code。

### Fallback 行為

當某個 provider 失敗或逾時，Gateway 會換到該模型 pool 裡下一個可用的 provider。這對應到你可能看到的狀態碼：

| 狀態碼 | 意義 |
|---|---|
| `502` | Provider 連線失敗或逾時。可安全重試。 |
| `503` | 該模型的所有 provider 目前皆 circuit-open。請遵守 `Retry-After`（60 秒）。 |
| `429` | 上游速率限制、配額或 provider 冷卻中。若有 `Retry-After` 請遵守。 |

完整清單見 [Errors](https://atptoken.ai/zh-tw/docs/errors/)。所有回應都帶一個 `request_id`，路由行為異常時可附上給支援。

> **後端待確認的細節**
>
> Pool 內的挑選順序、health-check 週期與 circuit-open 門檻設定在平台端，確認後會補在這頁。上面的行為（每模型一個 pool、自動 fallback，以及狀態碼對應）目前可穩定依賴。
