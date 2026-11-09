# 媒体模型（preview）

> Source: https://atptoken.ai/zh-cn/docs/media/

除了文字之外，目录还包含**图像、影片、语音（text-to-speech）与 embedding** 模型。它们与文字模型共用同一套账号、点数与项目（project）控管，但每种模态有自己的计费单位，不是 input + output tokens。模型与定价见[价格页](https://atptoken.ai/zh-cn/pricing/)。

> **Preview 状态**
>
> 媒体生成正以 preview 形式陆续开放。价格页上标示 **Preview** 的模型已在测试中上线，但价格尚未公布。若你的团队想要规模化抢先使用，[告诉我们你的使用情境](https://atptoken.ai/zh-cn/enterprise-plan/)。

## 先确认能用哪些模型

用你的密钥呼叫 `GET https://api.atptoken.ai/v1/project/models`，这是项目能用的完整清单，文字、图像、影片、语音、embedding 都在里面。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，媒体模型不在上面。清单上没有不代表不能用；没有权限时，建立任务会回 `403`，不收费。

## 图像、影片、语音都是非同步的

三种媒体都没有同步版本，流程一样：建立任务 → 轮询到终态 → 在签章 URL 过期前下载。**只有拿结果的栏位不同：**

| 模态 | 端点 | task id | 结果在哪 |
| --- | --- | --- | --- |
| 影片 | `/omni/media/v1/contents/generations/tasks` | `cgt_…` | `content.video_url` |
| 图像 | `/omni/media/v1/images/generations/tasks` | `img_…` | `data[].url`（阵列） |
| 语音 | `/omni/media/v1/audio/generations/tasks` | `aud_…` | `audio_url`（顶层） |

- 状态都是 `queued`、`running`、`succeeded`、`failed`、`expired`、`cancelled`，后四个是终态。
- **签章 URL 24 小时后失效。** 之后状态仍是 `succeeded`，但网址变成 `null`、另有 `expired: true`。
- 没有 webhook，`callback_url` 不会被使用，必须轮询。
- `Idempotency-Key` 每种媒体各用各的；同一把 key 用在两种媒体会回 `409`。

## 影片

影片模型包含 Seedance（`seedance-2-0`、`-fast`、`-mini`、`seedance-2-5`）、Kling、Wan、HappyHorse 与 MiniMax 系列。不同系列的请求格式不一样，完整清单与写法见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)。各模型费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

影片生成按 **video tokens** 计费，任务结束后依实际用量结算：

```
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

`in_dur` 是输入影片秒数、`out_dur` 是输出秒数、`W × H` 是输出宽高。模型自己回报用量时，以回报的为准。

每秒单价速查（牌价，16:9、无影片输入）：

| 解析度 | 约略单价 / 秒 |
| --- | --- |
| 480p（草稿） | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

下单前值得知道的事：

- **长宽比会影响价格。** 费用按实际的宽 × 高计算——同为 720p，1:1 比 16:9 便宜约 44%。
- **时长交给模型决定时，按实际秒数计费**，不是按请求上的数字。
- **带参考影片会切换费率档。** 加入输入影片后改按 with-input 档计费，且输入秒数会进公式。
- **可用解析度依模型而定**，见[影片生成](https://atptoken.ai/zh-cn/docs/media-video/)各系列的说明；费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。
- **余额耗尽时建立任务回 `402`。** 结算时余额不足会扣成负值，下一个请求会被挡住。
- **任务失败不计费。**

Seedance 的参数与范例见 [Seedance](https://atptoken.ai/zh-cn/docs/seedance-2-0/)。

## 图像

文生图也是非同步任务：建立任务后轮询，结果在 `data[].url`。价格将于正式上线时公布；在那之前模型在价格页标示为 **Preview**。

## 语音（text-to-speech）

TTS 是非同步任务，结果在 `audio_url`。按输入文字的**字元数**计费，不是 token。价格将于正式上线时公布。

## Embeddings

Embedding 是同步的一步呼叫（`POST /v1/embeddings`），只按 **input tokens** 计费——没有 output 计量。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

## 下一步

- [Seedance](https://atptoken.ai/zh-cn/docs/seedance-2-0/) — Seedance 的参数、范例与限制。
- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 建立影片任务并轮询结果。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 用 prompt 生成图片。
- [语音生成 (TTS)](https://atptoken.ai/zh-cn/docs/media-audio/) — 把文字转成语音。
