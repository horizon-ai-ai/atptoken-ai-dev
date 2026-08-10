# 請求日誌

> Source: https://atptoken.ai/zh-tw/docs/console-api-logs/

`GET /api/request-logs`

Gateway 的逐請求觀測紀錄 —— 你的 key 每一筆呼叫的端點、模型、HTTP 狀態、上游結果、token 數與計費狀態。**保留 7 天**；這是除錯視圖、不是計費真值（對帳請用[計費活動](https://atptoken.ai/zh-tw/docs/console-api-billing/)）。

```
curl -sS "https://admin.atptoken.ai/api/request-logs?org_id=<org>&limit=50&min_status=400" \
  -H "Authorization: Bearer $TOKEN"
```

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 組織 id。 |
| workspace_id / project_id | string | 縮小範圍。 |
| from / to | string | 時間區間。 |
| request_id | string | 查單一請求 —— 每個 API 回應都會回傳這個 id。 |
| unified_model_name / endpoint_url | string | 依模型或 API 路徑過濾。 |
| min_status / max_status | integer | 例：`min_status=400` 只看失敗。 |
| provider_id / provider_status / has_provider_error | — | 上游側過濾。 |
| limit / cursor / sort_by | — | 分頁與排序。 |

> **錯誤對帳**
>
> Gateway 每個回應都帶 `x-request-id` 標頭（回應 body 的 `id` 亦同值）。回報問題時附上它，支援端可直接對到這裡的那一列紀錄。
