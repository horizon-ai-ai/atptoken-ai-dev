---
name: atptoken-audio
description: Generate speech (text-to-speech / TTS) through the Atptoken LLM Gateway media surface at /omni/media/v1/audio/generations/tasks. Asynchronous — POST returns 202 + an aud_ task id; poll until terminal, then download the top-level audio_url (signed, 24 hours). Required fields are model and text. Use for fish-s2-pro / gemini-3-1-flash-tts via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken audio generation (text-to-speech)

TTS is **asynchronous** — there is no synchronous version. Create a task (`202` + an
`aud_…` id), poll until the status is terminal, then download the **top-level
`audio_url`**. The flow is the same as image and video; only the result field differs
(image `data[].url`, video `content.video_url`, audio `audio_url`).

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` (or `x-api-key: atp-...`) + `Content-Type: application/json`
- **Models:** `fish-s2-pro`, `gemini-3-1-flash-tts`.

**Which models can this key use?** `GET /v1/project/models` is the complete list for
the key's project. `GET /v1/models` lists only openai-dialect chat models — **speech
models are never on it**. Not being on a list does not mean unusable; an unauthorized
model is refused at create with `403 permission_denied`, and you are not billed.

**Output delivery:** signed URL `https://media-<env>.atptoken.ai/v/audio/...?exp=&sig=`
valid for **24 hours**. Download it to keep it.

**No webhooks:** `callback_url` is accepted but never called. You must poll.

**Balance gate:** refused with `402 insufficient_quota` when the project balance is ≤ 0.

**Why async:** TTS sends no bytes until the whole clip is synthesized, so a synchronous
call could not survive the ingress idle timeout on long text. Queue + poll is the only
shape that serves long text.

---

## Create → poll → download

```bash
# 1) enqueue — 202; synthesis has not started yet
TASK=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer $ATPTOKEN_KEY" -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from Atptoken.", "format": "mp3" }' \
  | jq -r '.id')          # aud_…

# 2) poll until terminal — break on ALL four terminal statuses
while true; do
  RESP=$(curl -s https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/$TASK \
           -H "Authorization: Bearer $ATPTOKEN_KEY")
  S=$(echo "$RESP" | jq -r '.status'); echo "status = $S"
  case "$S" in
    succeeded) break ;;
    failed|expired|cancelled) echo "$RESP" | jq '.error'; exit 1 ;;
  esac
  sleep 3
done

# 3) download — the result is the TOP-LEVEL audio_url (not content.audio_url)
URL=$(echo "$RESP" | jq -r '.audio_url')
[ "$URL" = "null" ] && { echo "succeeded but expired (expired=$(echo "$RESP" | jq -r '.expired'))"; exit 1; }
curl -s -o out.mp3 "$URL"
```

- `status` ∈ `queued | running | succeeded | failed | expired | cancelled`; the last
  four are terminal.
- **`succeeded` does not guarantee a file.** After 24 hours the task still reports
  `succeeded`, but `audio_url` is `null` and `expired: true` is set.
- `status: "failed"` → `error: { code, message }`.
- `GET …/tasks/{id}` for a task that doesn't exist or isn't yours → `404`.

| Method | Path | Action |
|---|---|---|
| `POST` | `/omni/media/v1/audio/generations/tasks` | create → `202 { "id": "aud_..." }` |
| `GET` | `/omni/media/v1/audio/generations/tasks/{id}` | poll |
| `GET` | `/omni/media/v1/audio/generations/tasks` | list your project's tasks |
| `DELETE` | `/omni/media/v1/audio/generations/tasks/{id}` | `queued` → cancelled; terminal → record deleted; `running` → `409`; `503` = cancel **not delivered** (the task will still run and bill) — retry, never treat as cancelled |

**Idempotency:** keys are per media surface. A key already used for an image or video
task returns `409` here — use a new key.

### Request body

`model` and **`text`** are required. The field is `text` — **not `input`, not
`prompt`**. The table is the full parameter set; each model uses the subset that maps
and applies its own defaults for the rest. As everywhere on the media surface, a field a
model doesn't read is ignored silently — compare the output to confirm. These fields
come from the endpoint contract and have not been checked model by model.

| Field | Type | Req | Default | Notes |
|---|---|:--:|---|---|
| `model` | string | ✅ | | speech model name |
| `text` | string | ✅ | | text to speak |
| `format` | string | | `mp3` | `wav` / `pcm` / `mp3` / `opus` — sets the extension and content-type (invalid → `400`) |
| `reference_id` | string / array | | | voice model id; array of strings for multi-speaker |
| `references` | array | | | zero-shot inline voice samples `{ "audio", "text" }`; nested arrays for multi-speaker |
| `sample_rate` | int | | null (format default) | Hz |
| `mp3_bitrate` | int | | `128` | `64` / `128` / `192` (only `format=mp3`) |
| `opus_bitrate` | int | | `-1000` (auto) | `-1000` / `24000` / `32000` / `48000` / `64000` bps (only `format=opus`) |
| `temperature` | number | | `0.7` | expressiveness 0–1 |
| `top_p` | number | | `0.7` | diversity 0–1 |
| `prosody` | object | | | `{ "speed": 1 (0.5–2.0), "volume": 0 (dB), "normalize_loudness": true }` |
| `chunk_length` | int | | `300` | text chunk size 100–300 |
| `min_chunk_length` | int | | `50` | min chars before a new chunk 0–100 |
| `max_new_tokens` | int | | `1024` | max audio tokens per chunk |
| `normalize` | bool | | `true` | text normalization (number stability) |
| `condition_on_previous_chunks` | bool | | `true` | use prior audio as consistency context |
| `latency` | string | | `normal` | `low` / `balanced` / `normal` |
| `repetition_penalty` | number | | `1.2` | >1 reduces repetition |
| `early_stop_threshold` | number | | `1` | batch early-stop 0–1 |

**Voice cloning:** either `reference_id` (a registered voice model id) or `references`
(inline sample clip + its transcript). Both accept arrays for multi-speaker.

---

## Errors

| Status | Meaning | Action |
|---|---|---|
| `400` | missing `model` / `text`, or an invalid `format` | read the message |
| `401` `token_revoked` | bad key — **also what you get when no key was sent** | check the header actually went out |
| `402` `insufficient_quota` | project balance exhausted | not a transient limit — **don't retry**; top up first |
| `403` `permission_denied` | model is restricted; your project isn't on its allow-list | not a key or balance problem. Not billed |
| `404` | task not found / not yours | check the id |
| `409` | `Idempotency-Key` already points at a task on another media surface; or DELETE on a `running` task | use a new key |
| `422` | the model has no available capacity | switch models |
| `503` | enqueue failed, or `balance_check_unavailable` (balance **read** failed — not insufficient; nothing started, nothing charged) | retryable |

Quote the response's `x-request-id` when reporting a problem. For video or image see the
**atptoken-video** / **atptoken-image** skills; for auth and the cross-surface error
table see **atptoken-gateway**.
