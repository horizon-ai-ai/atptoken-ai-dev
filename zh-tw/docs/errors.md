# 錯誤碼與處理方式

> Source: https://atptoken.ai/zh-tw/docs/errors/

查 Gateway 回傳的狀態碼代表什麼、該先檢查哪裡，以及怎麼處理。**遇到 4xx，要讀訊息，不要只看狀態碼。** Gateway 會把模型自己的 4xx 原樣轉給你，那些訊息通常直接寫出是哪個欄位、合法值是什麼。

## 狀態碼

跳到：[400](#status-400) · [401](#status-401) · [402](#status-402) · [403](#status-403) · [404](#status-404) · [409](#status-409) · [422](#status-422) · [429](#status-429) · [502](#status-502) · [503](#status-503) · [5xx](#status-5xx)

> **聯絡支援時附上 x-request-id**
>
> 每個回應都有 `x-request-id` header，這是回報問題唯一的依據，聯絡支援時請附上。自己送一個 request id 不會被採用。

| 狀態碼 | 代表什麼 | 先檢查 | 怎麼處理 |
|---|---|---|---|
| `400` | 請求格式錯誤。媒體請求常見：缺 `model` 或 prompt、混用不同來源的資產、`asset_not_ready`、`asset_failed` | 錯誤訊息——通常會指出是哪個欄位 | 對照該端點的參數表修正後再送 |
| `401` | 金鑰無效或過期：`token_revoked`，訊息是「API key has been revoked or does not exist」。**完全沒送金鑰也是這個錯誤** | 先確認 header 真的有送出去，再看是否以 `atp-` 開頭、是否已停用或過期 | 到「API 金鑰」確認或重新建立；header 位置見[驗證方式](https://atptoken.ai/zh-tw/docs/auth/) |
| `402` | `insufficient_quota`：點數用完 | 主控台「用量」的可用點數 | 這不是暫時性限流，不要重試。到「帳單」儲值；團隊組織再到「資源」撥點數 |
| `403` | `permission_denied`：這個模型受控，你的專案不在允許清單上。不是金鑰或餘額的問題 | `GET /v1/project/models` 回傳的模型 ID | 換一個模型，或請管理員到「資源」替專案加上模型。不收費 |
| `404` | 網域或路徑打錯。訊息會寫 `This domain serves only the LLM Gateway API (/v1, /v1beta)` | base URL 和路徑前綴——這個網域只服務 `/v1*` 與 `/omni/*` | 修正 base URL 或路徑 |
| `409` | 這把 `Idempotency-Key` 已經指向**另一個**媒體端點的任務 | 是不是把同一把 key 用在影片、圖像、語音不同端點 | 換一把新的；每個端點用各自的 key |
| `422` | 這個模型不在這個端點服務（訊息會**指名正確的端點**），或這個資產不能給你指定的模型使用 | 訊息裡寫的端點 | 改打那個端點，或改用直接網址而不是資產 |
| `429` | 速率限制（RPM），或這個模型此刻沒有可用容量 | 回應的 `Retry-After` | 退避：依 `Retry-After` 等待後重試 |
| `502` | 模型的服務回傳錯誤，或連線失敗、逾時 | — | 可以重試 |
| `503` | 兩種原因：此刻沒有可用容量；或 `balance_check_unavailable`——餘額讀不到（**不是**餘額不足），請求沒有開始，也沒有扣款 | `Retry-After` | 依 `Retry-After` 等待後重試 |
| `5xx` | 供應商或 Gateway 錯誤 | 回應的 `x-request-id` header | 在主控台「請求紀錄」用 request ID 查詢；聯絡支援時附上 |

## 怎麼計費

計費以「請求」為單位，不是以「嘗試」為單位。一個請求在你的紀錄裡可能有好幾列，**不要相加**。

點數在請求開始前先預留，完成後才實際扣款。`403` 在建立請求時就被擋下，不收費。`503 balance_check_unavailable` 的請求沒有開始，也沒有扣款。

## 看請求在哪裡被擋下

選一個情境，看請求被哪一道檢查擋下、回應長什麼樣子。

**一筆請求在 ATP 裡的路徑**

| 步驟 | 檢查 | 擋下時 |
| --- | --- | --- |
| 1. 用戶端 | 帶專案金鑰送出 | — |
| 2. 金鑰檢查 | 金鑰有效且啟用 | 401 |
| 3. 模型允許清單 | 專案已開放此模型 | 403 |
| 4. 點數 | 專案還有餘額 | 402 |
| 5. 速率限制 | 未超過限制 | 429 |
| 6. 供應商 | 路由與備援 | — |
| 7. 紀錄與計費 | 以點數計量 | — |

| 情境 | 停在 | 狀態 | 回應 |
| --- | --- | --- | --- |
| 放行 | 紀錄與計費 | 200 OK | 標頭：`x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests` — 本體是供應商的回應，格式跟你用的 SDK 一致。速率限制標頭告訴你還剩多少額度。 |
| 金鑰無效 | 金鑰檢查 | 401 Unauthorized | `{"message":"API key has been revoked or does not exist.","error":"token_revoked"}` |
| 模型未開放 | 模型允許清單 | 403 Forbidden | `{"error":{"message":"model not available for this project","type":"permission_denied","request_id":"..."}}` |
| 點數用完 | 點數 | 402 Payment Required | 錯誤本體沿用 SDK 的錯誤格式：錢包或點數池已用完。儲值後恢復；重試沒有用。 |
| 被限流 | 速率限制 | 429 Too Many Requests | 錯誤本體沿用 SDK 的錯誤格式：速率限制、配額或供應商冷卻。退避後重試；有 Retry-After 就照它等。 |

## 200 但內容為空

請求可能回傳 `200 OK` 卻是空訊息——不是錯誤，只是沒有文字。這幾乎都是由 request 參數造成，而非失敗。最常見的原因是 推理模型（extended thinking）的 `max_tokens` 設太低：整個額度在產生任何可見輸出前就被內部推理吃完，於是內容回空。

在本平台上，這種請求通常會顯示**零 token 用量、也不會扣點數**——空的 `200` 加上空的 `usage`，就是這個情況的特徵，不是計費 bug。解法：把 `max_tokens` 調高到「思考預算 + 預期輸出」都夠用，或關閉 extended thinking。在假設有文字前，一律先檢查 `finish_reason` / `stop_reason` 與 `usage`。

拿到 `200` 也不代表模型看到了你送的全部內容。少一則訊息的請求依然合法、依然 `200`；不屬於這個端點的寫法（例如把 OpenAI 的 `role: "tool"` 送到 `/v1/messages`）會被原樣轉送——有的模型讀得到，有的回 `200` 卻當作沒收到。要確認內容真的送到，在訊息裡放一個模型猜不到的值，再請它回答出來。

## 下一步

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 金鑰放在哪裡，以及 `401` 代表什麼。
- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 設好 `max_tokens`，讓 reasoning 模型產生可見輸出。
- [請求紀錄](https://atptoken.ai/zh-tw/docs/console-api-logs/) — 用 request ID 查出失敗的那一筆請求。
