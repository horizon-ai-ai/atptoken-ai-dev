# 模型目录

> Source: https://atptoken.ai/zh-cn/docs/console-api-models/

`GET /api/video/models`

五个按模态分流的目录端点，各自回传平台上 active 的 `unifiedModelName` 清单（去重、字母排序）：

| 端点 | 模态 |
|---|---|
| `GET /api/chat/models` | Chat／文字 |
| `GET /api/image/models` | 图像生成 |
| `GET /api/video/models` | 影片生成 |
| `GET /api/audio/models` | 语音（TTS） |
| `GET /api/embedding/models` | Embeddings |

> **平台目录 vs 你的专案可用模型**
>
> 这几个端点列的是**平台上存在**的模型。*你的 key* 能呼叫哪些，取决于专案的允许清单——请在资料面用 `atp-` key 打 `GET https://api.atptoken.ai/v1/models` 查（仅 chat 模型）。专案已开通的媒体模型可在 Console 的金钥精灵中查看。
