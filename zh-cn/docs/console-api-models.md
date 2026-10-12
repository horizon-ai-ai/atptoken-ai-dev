# 模型目录

> Source: https://atptoken.ai/zh-cn/docs/console-api-models/

`GET /api/video/models`

五个按模态分流的目录端点，各自回传平台上 active 的 `unifiedModelName` 清单（去重、字母排序）。

## 各模态的目录端点

| 端点 | 模态 |
|---|---|
| `GET /api/chat/models` | Chat／文字 |
| `GET /api/image/models` | 图像生成 |
| `GET /api/video/models` | 影片生成 |
| `GET /api/audio/models` | 语音（TTS） |
| `GET /api/embedding/models` | Embeddings |

## 平台目录 vs 你的项目可用模型

这几个端点列的是**平台上存在**的模型。*你的密钥* 能呼叫哪些，取决于项目（project）的允许清单——请在数据面用 `atp-` 密钥打 `GET https://api.atptoken.ai/v1/models` 查（仅 chat 模型）。项目已开通的媒体模型可在控制台的密钥精灵中查看。

## 下一步

- [列出平台可用模型](https://atptoken.ai/zh-cn/docs/models/) — 在数据面用 `atp-` 密钥查模型 ID。
- [资源与成员](https://atptoken.ai/zh-cn/docs/console-api-resources/) — 项目明细含该项目的允许模型清单。
- [媒体模型](https://atptoken.ai/zh-cn/docs/media/) — 图像、影片、语音与 embedding 模型怎么计费。
