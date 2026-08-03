# 平台與工作流工具

> Source: https://atptoken.ai/zh-tw/docs/platforms/

用介面組裝 AI、不自己寫程式的工具——應用建構平台、工作流自動化——接 Gateway 的方式跟 SDK 一樣。把工具裡的 OpenAI 相容 provider 指向 Gateway，這個 project 允許的模型就全部在裡面可用，共用一把金鑰、一張帳單。

> **這一頁也有純 markdown 版本**
>
> 任何文件網址加上 `.md` 就能讀到純文字版：`https://atptoken.ai/docs/platforms.md`。想把整頁餵給 AI 助理時很好用。

### 開始之前

三個值，到哪裡都一樣：

- **Base URL** — 填 `https://api.atptoken.ai/v1`。要含 `/v1`，但不要接 `/chat/completions`。
- **API Key** — 那把 `atp-…` 開頭的 project key。
- **Model** — `GET /v1/models` 回傳的其中一個 id。

工具之間的差別，在於它能不能自己去讀你的模型清單：

| 工具 | 設定位置 | 模型清單 |
|---|---|---|
| Dify | Settings → Model Providers | 一次加一個，手動 |
| n8n | OpenAI credential 的 Base URL 欄位 | 從 `GET /v1/models` 自動讀 |

如果你要接的是 coding agent——Claude Code、Codex、Cline 那一類——請看 [Coding agents](https://atptoken.ai/zh-tw/docs/agents/)。

### Dify

從 marketplace 安裝 **OpenAI-API-compatible** 這個 model provider，然後在它的卡片上按 **Add Model**。要填的欄位：

| 欄位 | 值 |
|---|---|
| Model Name | `GET /v1/models` 回傳的模型 id |
| API Key | 你的 `atp-…` 金鑰 |
| API Base URL | `https://api.atptoken.ai/v1` |
| Model context size | 該模型真正的 context window |
| Upper bound for max tokens | 該模型真正的輸出上限 |
| Function Call Type | 想讓 agent 使用工具就選 `Tool Call` |
| Vision Support | 吃圖片的模型選 `Support` |

多數卡關來自兩個預設值。**Model context size 預設只有 4096**，超過就被靜默截斷，所以每個模型都要照實填。還有 **Function Call Type 預設是 `no_call`**，代表 Dify 根本不會送出 tools 陣列——建在這個模型上的 agent 會安靜地不呼叫任何工具，直到你改掉它。

Dify 不會去讀 `GET /v1/models`，每個模型都要獨立 Add Model 一次。先打那支端點，照它回傳的清單一個個加。

Dify Cloud 與自架版的設定方式相同。

### n8n

n8n 用它內建的 **OpenAI** credential。建一組，在 **Add option** 裡把 **Base URL** 設成 `https://api.atptoken.ai/v1`，**API Key** 貼上 `atp-…` 金鑰。

之後模型下拉選單就會透過這個 base URL 去讀 `GET /v1/models`，你 project 的模型會自己出現，不用手動列。

使用時，在 **AI Agent** 或 **Basic LLM Chain** 節點底下掛一個 **OpenAI Chat Model** 子節點，選這組 credential。

> **要用 AI Agent 節點，不要用 OpenAI 節點的 Message a model**
>
> OpenAI 節點自己的 `Message a model` 動作，配自訂 Base URL 時有一個尚未修復的問題：credential 測試會過，但實際執行回 `404`。走 `AI Agent` 加 `OpenAI Chat Model` 子節點才是可行的路。

還有兩點。Base URL 欄位在 credential 上，不在節點上——它在後來的版本被從節點隱藏了，所以會給人「找不到這個欄位」的感覺。另外 n8n 官方文件沒有列出這個欄位，它只存在於 credential 介面的 **Add option** 裡。

n8n Cloud 與自架版的行為相同。

### 排錯

- **`403`** — 模型沒有在這把 key 所屬的 project 啟用。到 Console 的該 project Resources 開啟。
- **`404`** — `/v1` 位置放錯，或工具在已經以 `/chat/completions` 結尾的網址後面又接了一次。
- **模型選單是空的** — Dify 本來就不會替你列模型，要一個個加。n8n 如果是空的，通常代表金鑰或 base URL 有誤，因為那個下拉是由 `GET /v1/models` 填的。
- **工具都沒有被呼叫** — Dify 那邊的 `Function Call Type` 還停在 `no_call`。

## 後續步驟

- [Coding agents](https://atptoken.ai/zh-tw/docs/agents/) — Claude Code、Codex 與其他終端機 agent
- [管理 API keys](https://atptoken.ai/zh-tw/docs/console-keys/) — 接進共用工具之前，先把金鑰限定在單一 project
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 這些工具的用量怎麼計費
