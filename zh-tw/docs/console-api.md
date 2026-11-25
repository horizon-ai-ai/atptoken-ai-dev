# 主控台 API——用 API 查用量、帳務與資源

> Source: https://atptoken.ai/zh-tw/docs/console-api/

ATP Token 網頁主控台看得到的資料，都有對應的 REST API：`https://admin.atptoken.ai/api`——即時餘額、每月各模型用量、計費活動、模型目錄、組織／工作區／專案（project）結構。可用來做儀表板、預算告警、或自動切換模型。

完整且永遠與實作同步的規格是線上 Swagger：[admin.atptoken.ai/api/docs](https://admin.atptoken.ai/api/docs)，以下各頁的每個端點都能在那裡直接試打。同一份規格也有一份靜態、方便 agent 讀取的鏡像版本，含 operation ID 與型別化參數，發布於 [/openapi.json](https://atptoken.ai/openapi.json)。

## 認證

> **兩種憑證，不要混用**
>
> **`atp-` API 金鑰** 只用於資料面（`api.atptoken.ai`——chat、媒體、embeddings）。主控台 API 使用 **某個已登入真人的 session token**。對主控台 API 端點送 `atp-` 金鑰一律回 `401`，換哪個端點都一樣。

### 要有一個真人登入

`POST /api/users/login` 的 body 必須帶人機驗證的答案，而只有瀏覽器產生得出來。主控台 API 沒有 API 金鑰、沒有服務帳號，也沒有給機器登入的端點：這幾頁上的每一個呼叫，用的都是某個真人在 [atptoken.ai](https://atptoken.ai) 登入後拿到的 session token。

這是一個決定，不是還沒做完的功能。登入頁正是腳本猜密碼會打的地方，而原本唯一的防線——單一帳號的失敗次數上限——罰錯了人：腳本換下一個帳號繼續猜，被鎖在外面的卻是真正的持有人。人機驗證在第一個請求就擋下整輪，所以它對每一次登入都生效，沒有門檻可以跨過，也沒有例外可以申請。

在瀏覽器登入之後，主控台把那個 session token 放在 `localStorage` 的 `atp_token`——它就是以下範例裡的 `$TOKEN`。這是 Bearer token，效期約 **2 小時**，`POST /api/users/logout` 可以提前結束它。

### 這代表什麼事做不到

腳本不能自己登入，也就不能讓自己一直保持認證：token 過期之後，要有一個人重新登入。主控台 API 適合「手上有 session 時才跑」的工作——出報表、對帳、追一個失敗的請求——而不是一個長期無人看管的服務。

如果你要的是完全不需要 session 的花費上限，請改用點數分配，而不是監看餘額：專案只能花掉被分配到的額度，而且是 Gateway 在每一個請求上執行。見[建立帶預算上限的團隊](https://atptoken.ai/zh-tw/docs/cb-budget-caps/)。

## 輪詢餘額、切換模型

最常見的整合情境：監看專案即時餘額，低於門檻時切換到較便宜的模型。它能跑多久取決於 session token 的效期：token 過期之後，要有一個人重新登入。

```
# $TOKEN is one signed-in person's session token (see Authentication)

# 1) Real-time project balance (Redis-backed, reflects every request instantly)
curl -sS "https://admin.atptoken.ai/api/quota/balance?org_id=<org>&workspace_id=<ws>&project_id=<proj>" \
  -H "Authorization: Bearer $TOKEN"

# 2) Current-month usage per model
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
- 400 — `POST /api/users/login` 回 `captcha_required` 或 `captcha_invalid`：人機驗證沒有通過。腳本過不了，請在瀏覽器登入。
- 401 — session token 缺失／過期，或誤用了 `atp-` API 金鑰。
- 403 — 已認證但無此範圍的存取權。
- 404 — 可見範圍內找不到資源。

## 下一步

- [用量與餘額](https://atptoken.ai/zh-tw/docs/console-api-usage/) — 讀取專案即時餘額與每月用量。
- [資源與成員](https://atptoken.ai/zh-tw/docs/console-api-resources/) — 查出多數端點需要的組織、工作區與專案 ID。
- [請求紀錄](https://atptoken.ai/zh-tw/docs/console-api-logs/) — 依狀態碼或 request ID 找出失敗的請求。
