# 媒体模型（preview）

> Source: https://atptoken.ai/zh-cn/docs/media/

除了文本之外，目录还包含**图像、视频、语音（text-to-speech）与 embedding** 模型。它们与文本模型共用同一套账号、credits 与 project 控管，但每种模态有自己的计费单位，不是 input + output tokens。目前的模型与刊例见[价格页](https://atptoken.ai/zh-cn/pricing/)。

> **Preview 状态**
>
> 媒体生成正以 preview 形式陆续开放。价格页上标示 **Preview** 的模型已在测试中上线，但刊例尚未公布。若你的团队想要规模化抢先使用，[告诉我们你的使用场景](https://atptoken.ai/zh-cn/enterprise-plan/)。

### 视频

视频模型：**seedance-2-0**（标准）、**seedance-2-0-mini**（轻量、较省）与 **seedance-2-0-fast**（加速）。各模型费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

视频生成按 **video tokens** 计费，由渲染的像素与秒数计算：

```
video_tokens = width × height × (input seconds + output seconds) × 24 ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

每秒单价速查（刊例，16:9、无视频输入）：

| 分辨率 | 约略单价 / 秒 |
| --- | --- |
| 480p（草稿） | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

下单前值得知道的事：

- **长宽比会影响价格。** 费用按实际的宽 × 高计算——同为 720p，1:1 比 16:9 便宜约 44%。
- **duration 设 auto 时按实际秒数计费**，不是按请求上的数字。
- **带参考视频会切换费率档。** 加入输入视频后改按 with-input 档计费，且输入秒数会进公式。
- **4K 尚未开放**；超过 1080p 的请求会在创建任务前被拒绝。
- **任务失败不计费。**

目前视频模型的参数与范例见 [Seedance 2.0](https://atptoken.ai/zh-cn/docs/seedance-2-0/)。

### 图像

文生图为同步生成——送出 prompt、回传图片 URL。刊例将于正式上线时公布；在那之前模型在价格页标示为 **Preview**。

### 语音（text-to-speech）

TTS 按输入文本的**字符数**计费，不是 token。刊例将于正式上线时公布。

### Embeddings

Embedding 模型只按 **input tokens** 计费——没有 output 计量。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。
