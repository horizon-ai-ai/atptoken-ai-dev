# Speech generation (TTS)

> Source: https://atptoken.ai/docs/media-audio/

`POST /omni/media/v1/audio/generations/tasks`

Text-to-speech is **asynchronous** — there is no synchronous version. Like image and video, it takes three steps: create a task (`202` + an `aud_…` task id), poll until the status is terminal, then download the **top-level `audio_url`** within 24 hours. Same base URL and `atp-` key as image generation.

- **Output is a signed URL (`https://media-<env>.atptoken.ai/v/...`) valid for 24 hours** — never inline base64. Download it if you need to keep it.
- Requests are refused with `402 insufficient_quota` when the project balance is ≤ 0.
- `callback_url` is accepted but **no webhook is ever sent**. You must poll.

Why it's asynchronous: speech sends no bytes until the whole clip is synthesized, so long text can't survive the connection's idle timeout. Queue-and-poll is what makes long text possible.

## Create a task

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: tts-job-001" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
# → 202 { "id": "aud_..." }
```

A `202` means **synthesis hasn't started yet** — you get a task id.

Available models: `fish-s2-pro`, `gemini-3-1-flash-tts`. Which ones this key may actually use is answered by `GET /v1/project/models`; `GET /v1/models` lists only chat models, so speech models aren't on it. A model you're not authorized for is refused with `403` at create, and you are not billed.

**Only two fields are required: `model` and `text`.** The field is `text` — not `input`, and not `prompt`.

The table below is the full parameter set. Each model uses the subset that applies to it and its own defaults for the rest. **No error does not mean the field was read** — compare the output to confirm.

| Field | Type | Notes |
|---|---|---|
| model | string · Req | speech model name |
| text | string · Req | text to speak |
| format | string | `mp3` (default) / `wav` / `pcm` / `opus`. Sets the file extension and content-type; an invalid value returns `400` |
| reference_id | string / array | voice model id; an array for multi-speaker |
| references | array | inline voice samples `{audio, text}` (clip + transcript); nested arrays for multi-speaker |
| sample_rate | integer | Hz; omit for the format default |
| mp3_bitrate | integer | `64` / `128` (default) / `192`, only with `format=mp3` |
| opus_bitrate | integer | `-1000` (auto, default) / `24000` / `32000` / `48000` / `64000`, only with `format=opus` |
| temperature | number | expressiveness, 0–1 (default `0.7`) |
| top_p | number | diversity, 0–1 (default `0.7`) |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }`: speed multiplier 0.5–2.0, volume adjustment in dB, loudness normalization |
| chunk_length | integer | text chunk size, 100–300 (default `300`) |
| min_chunk_length | integer | minimum characters before a new chunk, 0–100 (default `50`) |
| max_new_tokens | integer | maximum audio tokens per chunk (default `1024`) |
| normalize | boolean | text normalization for stable number reading (default `true`) |
| condition_on_previous_chunks | boolean | use earlier audio to keep the voice consistent (default `true`) |
| latency | string | `low` / `balanced` / `normal` (default) — latency vs. quality |
| repetition_penalty | number | above 1 reduces repetition (default `1.2`) |
| early_stop_threshold | number | batch early-stop threshold, 0–1 (default `1`) |

**To use a specific voice**, either pass `reference_id` (a registered voice model id) or `references` (an inline sample clip with its transcript). Both accept arrays for multi-speaker.

**Idempotency:** reuse the same `Idempotency-Key` when retrying a create after a network failure. Image, video and audio each need their own keys: a key already used on another media surface returns `409`.

## Poll until terminal

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/aud_... \
  -H "Authorization: Bearer atp-..."
# → { "id": "aud_...", "status": "succeeded", "audio_url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
```

- Statuses: `queued`, `running`, `succeeded`, `failed`, `expired`, `cancelled`. The last four are terminal — **exit the loop on all four**.
- **The result is the top-level `audio_url`** — not `content.audio_url`, and not `data[].url`.
- **`succeeded` does not guarantee a file.** After 24 hours the status is still `succeeded`, but `audio_url` becomes `null` and `expired: true` appears. After checking `succeeded`, check that `audio_url` is not `null`.
- A `failed` task carries `error: { code, message }`.
- A task is visible as soon as it's created; a task that doesn't exist or isn't your project's returns `404`.

Full create + poll + download:

```
TASK=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer $ATPTOKEN_KEY" -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }' | jq -r '.id')

while true; do
  RESP=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/$TASK \
    -H "Authorization: Bearer $ATPTOKEN_KEY")
  S=$(echo "$RESP" | jq -r '.status')
  case "$S" in
    succeeded) break ;;
    failed|expired|cancelled) echo "$RESP" | jq '.error'; exit 1 ;;
  esac
  sleep 3
done

URL=$(echo "$RESP" | jq -r '.audio_url')
[ "$URL" = "null" ] && { echo "expired"; exit 1; }
curl -s -o out.mp3 "$URL"
```

| Method | Path | Action |
| --- | --- | --- |
| POST | /omni/media/v1/audio/generations/tasks | create |
| GET | /omni/media/v1/audio/generations/tasks/{id} | poll |
| GET | /omni/media/v1/audio/generations/tasks | list this project's tasks |
| DELETE | /omni/media/v1/audio/generations/tasks/{id} | `queued` is cancelled; terminal deletes the record; `running` returns `409` |

A `503` on cancel means the cancellation **did not get through**: the task will still run and be billed. Retry the cancel; don't treat it as cancelled.

## Errors

- 400 — missing `model` or `text`, or an invalid `format`. Read the message.
- 401 — `token_revoked`: invalid key — **also returned when no key was sent at all**. Check that the header actually went out.
- 402 — `insufficient_quota`: the project balance is exhausted. Not a transient rate limit — **don't retry**; top up first.
- 403 — `permission_denied`: the model is restricted and your project is not on its allow-list. Not a key or balance problem. Not billed.
- 404 — on poll: the task doesn't exist or isn't your project's.
- 409 — this `Idempotency-Key` already belongs to a task on another media surface (use a new key), or you tried to cancel a `running` task.
- 422 — the model has no available capacity. Switch models.
- 503 — the task couldn't be queued, or `balance_check_unavailable` (**the balance couldn't be read — not insufficient balance**; nothing started, nothing charged). Both are retryable.

## Next steps

- [Media models](https://atptoken.ai/docs/media/) — Which image, video and audio models are in the catalog.
- [Image generation](https://atptoken.ai/docs/media-image/) — Generate images with the same base URL and key.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means and what to check first.
