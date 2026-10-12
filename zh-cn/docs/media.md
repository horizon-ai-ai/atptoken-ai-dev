# 媒体模型（preview）

> Source: https://atptoken.ai/zh-cn/docs/media/

除了文字之外，目录还包含**图像、影片、语音（text-to-speech）与 embedding** 模型。它们与文字模型共用同一套账号、点数与项目（project）控管，但每种模态有自己的计费单位，不是 input + output tokens。模型与定价见[价格页](https://atptoken.ai/zh-cn/pricing/)。

> **Preview 状态**
>
> 媒体生成正以 preview 形式陆续开放。价格页上标示 **Preview** 的模型已在测试中上线，但价格尚未公布。若你的团队想要规模化抢先使用，[告诉我们你的使用情境](https://atptoken.ai/zh-cn/enterprise-plan/)。

## 影片

影片模型：**seedance-2-0**（标准）、**seedance-2-0-mini**（轻量、较省）与 **seedance-2-0-fast**（加速）。各模型费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

影片生成按 **video tokens** 计费，由渲染的像素与秒数计算：

```
video_tokens = width × height × (input seconds + output seconds) × 24 ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

每秒单价速查（牌价，16:9、无影片输入）：

| 解析度 | 约略单价 / 秒 |
| --- | --- |
| 480p（草稿） | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

下单前值得知道的事：

- **长宽比会影响价格。** 费用按实际的宽 × 高计算——同为 720p，1:1 比 16:9 便宜约 44%。
- **duration 设 auto 时按实际秒数计费**，不是按请求上的数字。
- **带参考影片会切换费率档。** 加入输入影片后改按 with-input 档计费，且输入秒数会进公式。
- **4K 尚未开放**；超过 1080p 的请求会在建立任务前被拒绝。
- **任务失败不计费。**

影片模型的参数与范例见 [Seedance 2.0](https://atptoken.ai/zh-cn/docs/seedance-2-0/)。

## 图像

文生图为同步生成——送出 prompt、回传图片 URL。价格将于正式上线时公布；在那之前模型在价格页标示为 **Preview**。

## 语音（text-to-speech）

TTS 按输入文字的**字元数**计费，不是 token。价格将于正式上线时公布。

## Embeddings

Embedding 模型只按 **input tokens** 计费——没有 output 计量。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

## 下一步

- [Seedance 2.0](https://atptoken.ai/zh-cn/docs/seedance-2-0/) — 影片模型的参数、范例与限制。
- [影片生成](https://atptoken.ai/zh-cn/docs/media-video/) — 建立影片任务并轮询结果。
- [图像生成](https://atptoken.ai/zh-cn/docs/media-image/) — 用 prompt 生成图片。
- [语音生成 (TTS)](https://atptoken.ai/zh-cn/docs/media-audio/) — 把文字转成语音。
