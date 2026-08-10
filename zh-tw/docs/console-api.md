# Console API — 用 API 查用量、帳務與資源

> Source: https://atptoken.ai/zh-tw/docs/console-api/

網頁 Console 看得到的資料，都有對應的 REST API：`https://admin.atptoken.ai/api` —— 即時餘額、每月各模型用量、計費活動、模型目錄、組織／工作區／專案結構。可用來做儀表板、預算告警、或自動切換模型。

完整且永遠與實作同步的規格是線上 Swagger：[admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs)，以下各頁的每個端點都能在那裡直接試打。

> **兩種憑證，不要混用**
>
> **`atp-` API key** 只用於資料面（`api.atptoken.ai` —— chat、媒體、embeddings）。Console API 使用 **`POST /api/users/login` 取得的 session token**（Console 帳號密碼）。對 Console API 端點送 `atp-` key 一律回 `401`，換哪個端點都一樣。

#### 認證

```
curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}'
# → { "token": "<JWT>", "exp": ..., "user": { ... } }
```

回傳的 `token` 為 Bearer token，效期約 **2 小時**。長期執行的腳本遇到 `401` 應重新登入，不要永久快取 token。`POST /api/users/logout` 可撤銷當前 session。

#### 快速開始 —— 輪詢餘額、切換模型

最常見的整合情境：監看專案即時餘額，低於門檻時切換到較便宜的模型。

```
# 1) Login (console credentials, NOT the atp- API key)
TOKEN=$(curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}' | jq -r .token)

# 2) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 3) Current-month usage per model
curl -sS "https://admin.atptoken.ai/api/billing/summary?org_id=<org>" \
  -H "Authorization: Bearer $TOKEN"
```

#### 查自己的 ID

多數端點需要 `org_id`／`workspace_id`／`project_id` 查詢參數，用以下端點列出：

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

#### 分頁導覽

- [用量與餘額](https://atptoken.ai/zh-tw/docs/console-api-usage/) —— 即時餘額、每月用量、各 key 用量、趨勢、錢包
- [帳務與儲值](https://atptoken.ai/zh-tw/docs/console-api-billing/) —— 計費活動、儲值紀錄、結帳連結、credit 調整歷史
- [模型目錄](https://atptoken.ai/zh-tw/docs/console-api-models/) —— 各模態平台級模型清單（chat／image／video／audio／embedding）
- [資源與成員](https://atptoken.ai/zh-tw/docs/console-api-resources/) —— 組織、工作區、專案、成員、我的帳號
- [請求日誌](https://atptoken.ai/zh-tw/docs/console-api-logs/) —— 逐請求觀測紀錄（保留 7 天）

- 400 — 參數缺漏或格式錯誤（多數端點必帶 `org_id`）。
- 401 — session token 缺失／過期，或誤用了 `atp-` API key。
- 403 — 已認證但無此範圍的存取權。
- 404 — 可見範圍內找不到資源。
