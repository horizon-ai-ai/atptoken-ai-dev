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

### 200 但內容為空

請求可能回傳 `200 OK` 卻是空訊息 — 不是錯誤，只是沒有文字。這幾乎都是由 request 參數造成，而非失敗。最常見的原因是 reasoning(extended thinking)模型的 `max_tokens` 設太低：整個額度在產生任何可見輸出前就被內部推理吃完，於是內容回空。

在本平台上，這種請求通常會顯示**零 token 用量、也不會扣 credits**——空的 `200` 加上空的 `usage`，就是這個情況的特徵，不是計費 bug。解法：把 `max_tokens` 調高到「思考預算 + 預期輸出」都夠用，或關閉 extended thinking。在假設有文字前，一律先檢查 `finish_reason` / `stop_reason` 與 `usage`。
