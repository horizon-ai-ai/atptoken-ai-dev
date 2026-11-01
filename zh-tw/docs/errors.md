# 錯誤碼與處理方式

> Source: https://atptoken.ai/zh-tw/docs/errors/

查 Gateway 回傳的狀態碼代表什麼、該先檢查哪裡，以及怎麼處理。

## 狀態碼

跳到：[400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **聯絡支援時附上 request_id**
>
> 每個錯誤回應都帶 `request_id`。聯絡支援時附上它，我們就能找到這一筆。

| 狀態碼 | 代表什麼 | 先檢查 | 怎麼處理 |
|---|---|---|---|
| `400` | 請求格式錯誤 | 缺欄位、JSON 格式錯誤，或用了該格式不支援的寫法 | 對照該端點的參數表修正後再送 |
| `401` | 金鑰無效 | 有沒有帶金鑰、是否以 `atp-` 開頭、是否已停用或過期 | 到「API 金鑰」確認或重新建立；header 位置見[驗證方式](https://atptoken.ai/zh-tw/docs/auth/) |
| `402` | 點數用完 | 主控台「用量」的可用點數 | 到「帳單」儲值；團隊組織再到「資源」撥點數 |
| `403` | 模型未在此專案開通 | `GET /v1/models` 回傳的模型 ID | 改用清單內的模型，或到「資源」替專案加上模型 |
| `429` | 速率限制、配額或供應商冷卻中 | 回應的 `Retry-After` | 依 `Retry-After` 等待後重試 |
| `502` | 供應商連線失敗或逾時 | — | 可以直接重試 |
| `503` | 這個模型的所有供應商暫時無法使用 | `Retry-After: 60` | 60 秒後重試 |
| `5xx` | 供應商或 Gateway 錯誤 | 回應裡的 `request_id` | 在主控台「請求紀錄」用 request ID 查詢；聯絡支援時附上 |

## 看請求在哪裡被擋下

選一個情境，看請求被哪一道檢查擋下、回應長什麼樣子。

****

_（互動圖——請看本頁的網頁版。）_

## 200 但內容為空

請求可能回傳 `200 OK` 卻是空訊息——不是錯誤，只是沒有文字。這幾乎都是由 request 參數造成，而非失敗。最常見的原因是 推理模型（extended thinking）的 `max_tokens` 設太低：整個額度在產生任何可見輸出前就被內部推理吃完，於是內容回空。

在本平台上，這種請求通常會顯示**零 token 用量、也不會扣點數**——空的 `200` 加上空的 `usage`，就是這個情況的特徵，不是計費 bug。解法：把 `max_tokens` 調高到「思考預算 + 預期輸出」都夠用，或關閉 extended thinking。在假設有文字前，一律先檢查 `finish_reason` / `stop_reason` 與 `usage`。

## 下一步

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 三種可接受的金鑰位置，以及 `401` 代表什麼。
- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 設好 `max_tokens`，讓 reasoning 模型產生可見輸出。
- [請求紀錄](https://atptoken.ai/zh-tw/docs/console-api-logs/) — 用 request ID 查出失敗的那一筆請求。
