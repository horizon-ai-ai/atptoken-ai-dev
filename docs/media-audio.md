# Speech generation (TTS)

> Source: https://atptoken.ai/docs/media-audio/

`POST /omni/media/v1/audio/generations`

Text-to-speech is **synchronous** — text in, one audio file out as a signed URL. Same base URL and `atp-` key. The gateway routes your unified `model` to an audio provider (e.g. `fish-s2-pro`) and speaks the right dialect. There is no async task; `GET /omni/media/v1/audio/tasks/{id}` always returns `404`.

- **Output is written to object storage and returned as a signed edge URL (`https://media-<env>.atptoken.ai/v/...`) with a **30-minute TTL** — never inline base64. Fetch it promptly.**
- Requests are refused with `402 insufficient_quota` when the project balance is ≤ 0.

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
```

| Field | Type | Notes |
|---|---|---|
| model | string · Req | unified audio model (`audio` pool) |
| text | string · Req | text to speak |
| reference_id | string | voice id (string, or array for multi-speaker) |
| format | string | `mp3` (default) / `wav` / `pcm` / `opus` |
| sample_rate | integer | Hz (format default) |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }` |
| temperature | number | expressiveness 0–1 (default `0.7`) |

#### Response `200`

```
{
  "created": 1781776187,
  "data": [
    { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
  ]
}
```

**OpenAI-style clients:** OpenAI TTS models also accept the OpenAI shape — `input`, `voice`, `response_format` — which the gateway maps.

### Errors

- 400 — missing `model` / `text`, or an invalid `format`.
- 402 insufficient_quota — project balance ≤ 0; top up and retry (don't hammer).
- 422 — the model has no audio provider.
