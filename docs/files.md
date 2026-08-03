# /v1/files

> Source: https://atptoken.ai/docs/files/

`POST /v1/files`

Upload a file to the Gateway and reference it in subsequent chat or messages requests by the returned `gw_file_id` (format `an_<ULID>`).

```
curl https://api.atptoken.ai/v1/files \
  -H "Authorization: Bearer atp-..." \
  -F "file=@./input.pdf"
# → { "gw_file_id": "an_01H...", ... }
```

### POST /v1/files
multipart/form-data upload with a `file` part. Max 20 MB. Identical bytes are deduped by SHA-256.
### GET /v1/files/:id
Returns 302 to a short-lived presigned URL on the object store. Follow the redirect to download.
