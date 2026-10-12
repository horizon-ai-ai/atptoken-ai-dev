# 供應商路由與備援

> Source: https://atptoken.ai/zh-tw/docs/provider-routing/

平台上每個模型由一個或多個上游供應商組成的供應商池 服務。你呼叫單一模型 ID；Gateway 為該請求挑一個供應商，並可 fail over 到另一個，因此就算某個供應商降級，模型仍能持續運作。

## 一個模型 ID，背後一個供應商池

每個模型的供應商組合與順序是設在平台端，不是逐請求指定。你的程式 永遠只指名模型（來自 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/)）；實際由哪個供應商服務由 Gateway 處理，且可在請求之間改變，你這端不需改任何 code。

## 自動備援（fallback）行為

當某個供應商失敗或逾時，Gateway 會換到該模型的供應商池裡下一個可用的供應商。這對應到你可能看到的狀態碼：

| 狀態碼 | 意義 |
|---|---|
| `502` | 供應商連線失敗或逾時。可安全重試。 |
| `503` | 該模型的所有供應商皆 circuit-open。請遵守 `Retry-After`（60 秒）。 |
| `429` | 上游速率限制、配額或供應商冷卻中。若有 `Retry-After` 請遵守。 |

完整清單見 [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。所有回應都帶一個 `request_id`，路由行為異常時可附上給支援。

> **尚未公開的設定**
>
> 供應商池內的挑選順序、health-check 週期與 circuit-open 門檻不對外公開。可以依賴的行為：每個模型一個供應商池、自動備援，以及上表的狀態碼。

## 下一步

- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 完整的狀態碼清單，包含 `502`、`503` 與 `429`。
- [模型查詢](https://atptoken.ai/zh-tw/docs/models/) — 列出請求裡可以指名的模型 ID。
- [運作方式](https://atptoken.ai/zh-tw/docs/how-it-works/) — 跟著一個請求走過驗證、模型授權、路由與計量。
