# 常見回應

> Source: https://atptoken.ai/zh-tw/docs/errors/

所有錯誤回應都含一個 `request_id` — 聯絡支援時請附上。錯誤外層格式會跟隨你呼叫的 SDK 格式（OpenAI / Anthropic / Gemini）。

- 400 — Bad request — 缺欄位、body 格式錯誤，或不支援的功能（例如 Anthropic system 用陣列）。
- 401 — API key 缺失、被停用、過期或無法辨識。
- 402 — 錢包或 credit 池已耗盡。儲值後即可恢復。
- 403 — 該模型未在此 project 啟用。
- 429 — 速率限制、配額，或 provider 冷卻中。若有 Retry-After 請遵守。
- 502 — Provider 連線失敗或逾時。可安全重試。
- 503 — 該模型的所有 provider 皆 circuit-open。Retry-After: 60。
- 5xx — Provider 或 Gateway 錯誤。請查 Console 的 request logs。

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

### 200 但內容為空

請求可能回傳 `200 OK` 卻是空訊息 — 不是錯誤，只是沒有文字。這幾乎都是由 request 參數造成，而非失敗。最常見的原因是 reasoning(extended thinking)模型的 `max_tokens` 設太低：整個額度在產生任何可見輸出前就被內部推理吃完，於是內容回空。

在本平台上，這種請求通常會顯示**零 token 用量、也不會扣 credits**——空的 `200` 加上空的 `usage`，就是這個情況的特徵，不是計費 bug。解法：把 `max_tokens` 調高到「思考預算 + 預期輸出」都夠用，或關閉 extended thinking。在假設有文字前，一律先檢查 `finish_reason` / `stop_reason` 與 `usage`。
