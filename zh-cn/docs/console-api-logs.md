# 请求日志

> Source: https://atptoken.ai/zh-cn/docs/console-api-logs/

`GET /api/request-logs`

Gateway 的逐请求观测纪录 —— 你的 key 每一笔呼叫的端点、模型、HTTP 状态、上游结果、token 数与计费状态。**保留 7 天**；这是除错视图、不是计费真值（对帐请用[计费活动](https://atptoken.ai/zh-cn/docs/console-api-billing/)）。

```
curl -sS "https://admin.atptoken.ai/api/request-logs?org_id=<org>&limit=50&min_status=400" \
  -H "Authorization: Bearer $TOKEN"
```

| Param | Type | Description |
|---|---|---|
| org_id | string · required | 组织 id。 |
| workspace_id / project_id | string | 缩小范围。 |
| from / to | string | 时间区间。 |
| request_id | string | 查单一请求 —— 每个 API 回应都会回传这个 id。 |
| unified_model_name / endpoint_url | string | 依模型或 API 路径过滤。 |
| min_status / max_status | integer | 例：`min_status=400` 只看失败。 |
| provider_id / provider_status / has_provider_error | — | 上游侧过滤。 |
| limit / cursor / sort_by | — | 分页与排序。 |

> **错误对帐**
>
> Gateway 每个回应都带 `x-request-id` 标头（回应 body 的 `id` 亦同值）。回报问题时附上它，支援端可直接对到这里的那一列纪录。
