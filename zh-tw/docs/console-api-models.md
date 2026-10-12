# 模型目錄

> Source: https://atptoken.ai/zh-tw/docs/console-api-models/

`GET /api/video/models`

五個按模態分流的目錄端點，各自回傳平台上 active 的 `unifiedModelName` 清單（去重、字母排序）。

## 各模態的目錄端點

| 端點 | 模態 |
|---|---|
| `GET /api/chat/models` | Chat／文字 |
| `GET /api/image/models` | 圖像生成 |
| `GET /api/video/models` | 影片生成 |
| `GET /api/audio/models` | 語音（TTS） |
| `GET /api/embedding/models` | Embeddings |

## 平台目錄 vs 你的專案可用模型

這幾個端點列的是**平台上存在**的模型。*你的金鑰* 能呼叫哪些，取決於專案（project）的允許清單——請在資料面用 `atp-` 金鑰打 `GET https://api.atptoken.ai/v1/models` 查（僅 chat 模型）。專案已開通的媒體模型可在主控台的金鑰精靈中查看。

## 下一步

- [列出平台可用模型](https://atptoken.ai/zh-tw/docs/models/) — 在資料面用 `atp-` 金鑰查模型 ID。
- [資源與成員](https://atptoken.ai/zh-tw/docs/console-api-resources/) — 專案明細含該專案的允許模型清單。
- [媒體模型](https://atptoken.ai/zh-tw/docs/media/) — 圖像、影片、語音與 embedding 模型怎麼計費。
