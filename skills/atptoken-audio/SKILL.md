---
name: atptoken-audio
description: Generate speech (text-to-speech / TTS) through the Atptoken LLM Gateway media surface at /omni/media/v1/audio/generations. Synchronous — text in, a short-lived signed audio URL out. Use for gpt-4o-mini-tts / gemini-tts / Fish Audio voices via Atptoken with an atp- key. See atptoken-gateway for auth and errors.
---

# Atptoken audio generation (text-to-speech)

TTS is **synchronous** — text goes in, one audio file comes back (as a signed URL). The gateway routes your unified `model` to a real audio provider from the `audio` pool and speaks the appropriate dialect: `fish_tts` (Fish Audio), `openai_tts` (OpenAI `/audio/speech`), `gemini_tts` (Gemini).

- **Base URL:** `https://api.atptoken.ai/omni/media/v1`
- **Auth:** `Authorization: Bearer atp-...` + `Content-Type: application/json`
- **Model:** a unified audio model name — confirm with `GET /v1/models`. Examples: `gpt-4o-mini-tts`, `gemini-2.5-flash-tts`, and Fish models (`s1`, `s2-pro`).

**Output delivery:** signed edge URL `https://media-<env>.atptoken.ai/v/audio/...?exp=&sig=` with a **30-minute TTL**. Audio is synchronous — there is **no async task**; `GET /omni/media/v1/audio/tasks/{id}` always returns `404`.

**Balance gate:** refused with `402 insufficient_quota` when the project balance is ≤ 0.

---

## `POST /omni/media/v1/audio/generations`

```bash
curl https://api.atptoken.ai/omni/media/v1/audio/generations \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -d '{ "model": "gpt-4o-mini-tts", "text": "Hello from Atptoken.", "format": "mp3" }'
```

**Response `200`:**
```json
{ "created": 1781776187,
  "data": [ { "url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." } ] }
```

### Request body

`model` and `text` are required. The full field set below is the **Fish Audio** parameter set (the richest dialect); other dialects use the subset that maps, and apply their own defaults for anything you omit. `format` sets both the output file extension and content-type.

| Field | Type | Req | Default | Notes |
|---|---|:--:|---|---|
| `model` | string | ✅ | | unified audio model (`audio` pool) |
| `text` | string | ✅ | | text to speak |
| `reference_id` | string | | | voice id; string, or array of strings for multi-speaker (S2-Pro) |
| `references` | array | | | zero-shot voice samples `[{ "audio": <bytes>, "text": <transcript> }]` |
| `format` | string | | `mp3` | `wav` / `pcm` / `mp3` / `opus` (invalid → `400`) |
| `sample_rate` | int | | (format default) | Hz |
| `mp3_bitrate` | int | | `128` | `64` / `128` / `192` (only `format=mp3`) |
| `opus_bitrate` | int | | `-1000` (auto) | `24000` / `32000` / `48000` / `64000` (only `format=opus`) |
| `temperature` | number | | `0.7` | expressiveness 0–1 |
| `top_p` | number | | `0.7` | nucleus sampling 0–1 |
| `prosody` | object | | | `{ "speed": 1 (0.5–2.0), "volume": 0 (dB), "normalize_loudness": true }` |
| `chunk_length` | int | | `300` | text chunk size 100–300 |
| `min_chunk_length` | int | | `50` | min chars before a new chunk 0–100 |
| `max_new_tokens` | int | | `1024` | max audio tokens per chunk |
| `normalize` | bool | | `true` | text normalization (number stability) |
| `condition_on_previous_chunks` | bool | | `true` | use prior audio as consistency context |
| `latency` | string | | `normal` | `low` / `balanced` / `normal` |
| `repetition_penalty` | number | | `1.2` | >1 reduces repetition |
| `early_stop_threshold` | number | | `1` | batch early-stop 0–1 |

> **OpenAI-style clients:** the `openai_tts` dialect also accepts the OpenAI shape — `input` (text), `voice` (e.g. `alloy`), and `response_format`. When targeting an OpenAI TTS model you can send those instead of the Fish fields; the gateway maps them.

---

## Errors

| Status | Meaning |
|---|---|
| `400` | missing `model` / `text`, or an invalid `format` |
| `402` `insufficient_quota` | project balance ≤ 0 — top up and retry (don't hammer) |
| `422` | the model has no audio provider |
| `502` | upstream generation failed |

Model names are configuration — confirm the live catalogue with `GET /v1/models`. For video or image see the **atptoken-video** / **atptoken-image** skills; for auth and the cross-surface error table see **atptoken-gateway**.
