# Request logs

> Source: https://atptoken.ai/docs/console-api-logs/

`GET /api/request-logs`

Per-request observability records from the gateway — endpoint, model, HTTP status, provider result, token counts and billing status for every call made with your keys. **Retention is 7 days**; this is a debugging view, not the billing source of truth (use [billing events](https://atptoken.ai/docs/console-api-billing/) for that).

```
curl -sS "https://admin.atptoken.ai/api/request-logs?org_id=<org>&limit=50&min_status=400" \
  -H "Authorization: Bearer $TOKEN"
```

| Param | Type | Description |
|---|---|---|
| org_id | string · required | Organization id. |
| workspace_id / project_id | string | Narrow the scope. |
| from / to | string | Time range. |
| request_id | string | Look up one request — the id every API response returns. |
| unified_model_name / endpoint_url | string | Filter by model or API path. |
| min_status / max_status | integer | e.g. `min_status=400` for failures only. |
| provider_id / provider_status / has_provider_error | — | Upstream-side filters. |
| limit / cursor / sort_by | — | Paging and ordering. |

> **Correlating errors**
>
> Every gateway response carries an `x-request-id` header (also `id` in the body). When reporting an issue, quote it — support can match it to the exact log row here.
