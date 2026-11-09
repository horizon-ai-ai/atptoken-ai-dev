# 语音生成 (TTS)

> Source: https://atptoken.ai/zh-cn/docs/media-audio/

`POST /omni/media/v1/audio/generations/tasks`

文字转语音是**非同步**的，没有同步版本。流程和图像、影片一样是三步：建立任务（回 `202` + `aud_…` 任务 id）→ 轮询到终态 → 在 24 小时内下载**顶层的 `audio_url`**。base URL 与 `atp-` 密钥同图像生成。

- **输出是签章 URL（`https://media-<env>.atptoken.ai/v/...`），效期 24 小时**，不会内嵌 base64。要留存就下载。
- 项目（project）余额 ≤ 0 时，请求会以 `402 insufficient_quota` 拒绝。
- `callback_url` 会被接受，但**不会有 webhook**。一定要轮询。

为什么是非同步：语音要整段算完才会送出第一个字节，长文本撑不过连线的闲置断线。改成入列＋轮询，长文本才服务得了。

## 建立任务

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: tts-job-001" \
  -d '{ "model": "fish-s2-pro", "text": "Hello from ATP Token.", "format": "mp3" }'
# → 202 { "id": "aud_..." }
```

回 `202` 时**还没开始合成**，拿到的是任务 id。

可用模型：`fish-s2-pro`、`gemini-3-1-flash-tts`。这把密钥实际放行哪些模型，以 `GET /v1/project/models` 为准；`GET /v1/models` 只列 chat 模型，语音模型不在里面。没有授权的模型会在建立时回 `403`，不收费。

**必填只有两个：`model` 和 `text`。** 栏位名是 `text`，不是 `input`，也不是 `prompt`。

下表是完整参数集。不同模型取用其中能对应的部分，其余套用模型自己的默认。**送了不报错不代表有读到**，要确认就比对输出。

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | 语音模型名称 |
| text | string · 必填 | 要转成语音的文字 |
| format | string | `mp3`（默认）／ `wav` ／ `pcm` ／ `opus`。决定副档名与 content-type，无效值回 `400` |
| reference_id | string / array | 语音模型 ID；多说话者可传阵列 |
| references | array | 直接内嵌的声音样本 `{audio, text}`（音档＋逐字稿）；多说话者可为巢状阵列 |
| sample_rate | integer | 取样率 Hz；不填用格式默认 |
| mp3_bitrate | integer | `64` ／ `128`（默认）／ `192`，只用于 `format=mp3` |
| opus_bitrate | integer | `-1000`（自动，默认）／ `24000` ／ `32000` ／ `48000` ／ `64000`，只用于 `format=opus` |
| temperature | number | 表现力，0–1（默认 `0.7`） |
| top_p | number | 多样性，0–1（默认 `0.7`） |
| prosody | object | `{ "speed": 1, "volume": 0, "normalize_loudness": true }`：语速倍率 0.5–2.0、音量调整 dB、响度正规化 |
| chunk_length | integer | 文字分段大小，100–300（默认 `300`） |
| min_chunk_length | integer | 分新段前最少字元，0–100（默认 `50`） |
| max_new_tokens | integer | 每段最多生成的音讯 token（默认 `1024`） |
| normalize | boolean | 文字正规化，让数字念法稳定（默认 `true`） |
| condition_on_previous_chunks | boolean | 参考前段音讯，维持声音一致（默认 `true`） |
| latency | string | `low` ／ `balanced` ／ `normal`（默认），延迟与品质的取舍 |
| repetition_penalty | number | 大于 1 降低重复（默认 `1.2`） |
| early_stop_threshold | number | 批次早停门槛，0–1（默认 `1`） |

**想用特定声音**有两种做法：`reference_id`（已注册的语音模型 ID），或 `references`（直接内嵌样本音档和它的逐字稿）。多说话者时两者都可以传阵列。

**幂等键：** 网络失败重试建立时沿用同一个 `Idempotency-Key`。图像、影片、语音要各用各的键：同一把键已用在别的媒体介面，会回 `409`。

## 轮询至终态

```
curl https://api.atptoken.ai/omni/media/v1/audio/generations/tasks/aud_... \
  -H "Authorization: Bearer atp-..."
# → { "id": "aud_...", "status": "succeeded", "audio_url": "https://media-prod.atptoken.ai/v/audio/aud_....mp3?exp=...&sig=..." }
```

- 状态：`queued`、`running`、`succeeded`、`failed`、`expired`、`cancelled`。后四个是终态，**四个都要跳出回圈**。
- **结果在顶层 `audio_url`**，不是 `content.audio_url`，也不是 `data[].url`。
- **`succeeded` 不保证拿得到文件。** 超过 24 小时后，状态仍是 `succeeded`，但 `audio_url` 变成 `null`，另外多一个 `expired: true`。判完 `succeeded` 还要检查 `audio_url` 是不是 `null`。
- `failed` 任务带 `error: { code, message }`。
- 任务一建立就查得到；查不到或不属于你的项目回 `404`。

完整的建立＋轮询＋下载：

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

| Method | Path | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/audio/generations/tasks | 建立 |
| GET | /omni/media/v1/audio/generations/tasks/{id} | 轮询 |
| GET | /omni/media/v1/audio/generations/tasks | 列出这个项目的任务 |
| DELETE | /omni/media/v1/audio/generations/tasks/{id} | `queued` 会取消；已终态会删除记录；`running` 回 `409` |

取消时若回 `503`，代表取消**没有送达**：任务会照常生成并计费。请重试取消，不要当成已取消。

## 错误

- 400 — 缺 `model` 或 `text`，或 `format` 无效。读消息修正。
- 401 — `token_revoked`：密钥无效，**完全没送密钥也会得到这个**。先确认 header 有送出去。
- 402 — `insufficient_quota`：项目余额耗尽。不是暂时性限流，**不要重试**；充值后再送。
- 403 — `permission_denied`：这个模型受控，你的项目不在白名单。不是密钥也不是余额问题。不收费。
- 404 — 轮询时：任务不存在或不属于此项目。
- 409 — 这把 `Idempotency-Key` 已用在另一个媒体介面的任务上，请换一把；或取消 `running` 中的任务。
- 422 — 这个模型没有可用容量。换模型。
- 503 — 任务无法入列，或 `balance_check_unavailable`（**余额读取失败，不是余额不足**，请求没有开始、没有扣款）。两种都可重试。

## 下一步

- [媒体模型](https://atptoken.ai/zh-cn/docs/media/) — 目录里有哪些图像、影片与语音模型。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 用同一组 base URL 与密钥生成图片。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
