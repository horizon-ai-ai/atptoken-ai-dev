# Files through the gateway

Upload a file once, get a reference id, and use that id in later requests instead of re-sending the bytes.

## Upload — `POST /v1/files`

`multipart/form-data` with a `file` part and an optional `purpose` field (default `user_data`). Maximum size **20 MB**.

```bash
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY" \
  -F "file=@./data.csv" \
  -F "purpose=user_data"
```

Response (OpenAI Files-compatible):

```json
{
  "id":         "an_01J9ZK7VQHX3M9PNQ4ABCDEFGH",
  "object":     "file",
  "bytes":      152340,
  "created_at": 1714579200,
  "expires_at": 1715184000,
  "filename":   "data.csv",
  "purpose":    "user_data",
  "mime_type":  "text/csv"
}
```

Use the returned `id` to reference the file in subsequent chat/messages requests.

**Idempotent:** uploading identical bytes again returns the existing record (HTTP `200` instead of `201`) — no duplicate is stored.

**Errors:** `400` (no file part) · `413` (over 20 MB) · `500` (storage failure).

## Retrieve — `GET /v1/files/{id}`

```bash
curl -L https://api.atptoken.ai/v1/files/an_01J9ZK7VQHX3M9PNQ4ABCDEFGH \
  -H "Authorization: Bearer $ATPTOKEN_API_KEY"
```

Returns a redirect to a short-lived download URL; pass `-L` (or let your HTTP client follow redirects) to fetch the bytes. A file can only be retrieved with a key from the same account that uploaded it (otherwise `403`); unknown ids return `404`.
