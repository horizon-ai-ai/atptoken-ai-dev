# 主控台 API——用 API 查用量、帳務與資源

> Source: https://atptoken.ai/zh-tw/docs/console-api/

ATP Token 網頁主控台看得到的資料，都有對應的 REST API：`https://admin.atptoken.ai/api`——即時餘額、每月各模型用量、計費活動、模型目錄、組織／工作區／專案（project）結構。可用來做儀表板、預算告警、或自動切換模型。

完整且永遠與實作同步的規格是線上 Swagger：[admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs)，以下各頁的每個端點都能在那裡直接試打。同一份規格也有一份靜態、方便 agent 讀取的鏡像版本，含 operation ID 與型別化參數，發布於 [/openapi.json](https://atptoken.ai/openapi.json)。

## 認證

> **兩種憑證，不要混用**
>
> **`atp-` API 金鑰** 只用於資料面（`api.atptoken.ai`——chat、媒體、embeddings）。主控台 API 使用 **`POST /api/users/login` 取得的 session token**（主控台帳號密碼）。對主控台 API 端點送 `atp-` 金鑰一律回 `401`，換哪個端點都一樣。

#### 請求

```
curl -sS -X POST https://admin.atptoken.ai/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"********"}'
# → { "token": "<JWT>", "exp": ..., "user": { ... } }
```

回傳的 `token` 為 Bearer token，效期約 **2 小時**。長期執行的腳本遇到 `401` 應重新登入，不要永久快取 token。`POST /api/users/logout` 可撤銷當前 session。

## 輪詢餘額、切換模型

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

## 查自己的 ID

多數端點需要 `org_id`／`workspace_id`／`project_id` 查詢參數，用以下端點列出：

```
curl -sS "https://admin.atptoken.ai/api/orgs" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/workspaces?org=<org_id>" -H "Authorization: Bearer $TOKEN"
curl -sS "https://admin.atptoken.ai/api/projects?workspace=<workspace_id>" -H "Authorization: Bearer $TOKEN"
```

## 端點分組

- [用量與餘額](https://atptoken.ai/zh-tw/docs/console-api-usage/)——即時餘額、每月用量、各金鑰用量、趨勢、錢包
- [帳務與儲值](https://atptoken.ai/zh-tw/docs/console-api-billing/)——計費活動、儲值紀錄、結帳連結、點數調整歷史
- [模型目錄](https://atptoken.ai/zh-tw/docs/console-api-models/)——各模態平台級模型清單（chat／image／video／audio／embedding）
- [資源與成員](https://atptoken.ai/zh-tw/docs/console-api-resources/)——組織、工作區、專案、成員、我的帳號
- [請求紀錄](https://atptoken.ai/zh-tw/docs/console-api-logs/)——逐請求觀測紀錄（保留 7 天）

## 錯誤

- 400 — 參數缺漏或格式錯誤（多數端點必帶 `org_id`）。
- 401 — session token 缺失／過期，或誤用了 `atp-` API 金鑰。
- 403 — 已認證但無此範圍的存取權。
- 404 — 可見範圍內找不到資源。

## 下一步

- [用量與餘額](https://atptoken.ai/zh-tw/docs/console-api-usage/) — 讀取專案即時餘額與每月用量。
- [資源與成員](https://atptoken.ai/zh-tw/docs/console-api-resources/) — 查出多數端點需要的組織、工作區與專案 ID。
- [請求紀錄](https://atptoken.ai/zh-tw/docs/console-api-logs/) — 依狀態碼或 request ID 找出失敗的請求。
