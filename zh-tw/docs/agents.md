# 把任何 coding agent 接上 ATP

> Source: https://atptoken.ai/zh-tw/docs/agents/

任何會說 Anthropic 或 OpenAI wire format 的 agent 都能跑在 project key 上。真正要填的只有三個值：Gateway 的 base URL、一把 `atp-` 開頭的 key，以及該 project 已啟用的 model id。這一頁涵蓋我們完整記錄的兩個 agent（Claude Code 與 Codex CLI）、其他工具共用的通用規則，以及三個套用通用規則會壞掉的工具。

### 貼給你的 agent

多數人不會自己一格一格填，而是直接叫 agent 去接。下面這段就是為了整段複製而寫的，把 `<你的工具名>` 換成你要接的工具即可。

```
Read https://atptoken.ai/docs/agents.md and follow it to connect my <your tool> to ATP Token.
My key is in the ATP_API_KEY environment variable.
First call GET https://api.atptoken.ai/v1/models to see which models are available,
then pick one from that list and configure it.
```

指令維持英文、指向英文版頁面，是因為那份純 markdown 是給機器讀的正規來源；你要改成中文照樣可以。

> **每一頁都有純 markdown 版本**
>
> 任何文件網址後面加上 `.md`，就會拿到這一頁的 markdown 原始碼 — 沒有頁面外框、不需要剖析 HTML。上面那段指令要 agent 讀的就是它。

### 第一步永遠是 GET /v1/models

碰任何設定檔之前，先列出這把 key 實際能呼叫哪些模型。agent 最常見的失敗，就是自己猜一個模型名。

```bash
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

回傳裡的每一個 id，這把 key 都能用。清單上沒有的模型，代表它沒有在該 key 所屬的 project 啟用，呼叫下去會拿到 `403` — 請先到 Console 的 Resources 開啟，再跑一次上面的請求，把 id 原樣抄過去。

### Claude Code

設定 base URL（不用加 `/v1` — Claude Code 會自己補上 `/v1/messages`），並把 key 當成 auth token 送出。清掉 `ANTHROPIC_API_KEY`，避免它蓋過去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

或把相同的值寫進 `~/.claude/settings.json` 的 `env` 區塊：

```
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.atptoken.ai",
    "ANTHROPIC_AUTH_TOKEN": "atp-...",
    "ANTHROPIC_API_KEY": ""
  },
  "model": "claude-sonnet-4-6"
}
```

### Codex CLI

在 `~/.codex/config.toml` 把 Gateway 加成自訂的 OpenAI-compatible provider（base URL **要包含** `/v1`），再 export `env_key` 指定的那把 key。

```
# ~/.codex/config.toml
model = "gpt-5.4"            # any model from GET /v1/models
model_provider = "atp"

[model_providers.atp]
name = "ATP"
base_url = "https://api.atptoken.ai/v1"
env_key = "ATP_API_KEY"
wire_api = "chat"
```

```
export ATP_API_KEY="atp-..."
codex
```

兩個工具都用 `Authorization: Bearer atp-…` 驗證。模型必須在該 key 所屬 project 已啟用，否則 Gateway 回傳 `403`。

### Hermes Agent

Hermes 把密鑰放在 `~/.hermes/.env`，其餘設定放 `~/.hermes/config.yaml`。把 Gateway 加成一個具名 provider：

```
# ~/.hermes/config.yaml
providers:
  atp:
    api: https://api.atptoken.ai/v1
    key_env: ATP_API_KEY
    transport: chat_completions
    default_model: <model from GET /v1/models>
```

```
# ~/.hermes/.env
ATP_API_KEY=atp-...
```

`discover_models` 預設開啟，所以 `hermes model` 會直接從 `GET /v1/models` 讀型錄，不用自己列模型。想改走 Anthropic 格式就把 `transport` 換成 `anthropic_messages`。

有兩件事要留意。Hermes 同時還接受舊版的 `custom_providers:` 清單，跟新的 `providers:` 並存時，模型選單與實際執行可能讀到不同來源——只留 `providers:` 就好。另外 `${VAR}` 代換失敗不會報錯，變數名打錯只會留下原字串加一則警告，很難查。

### OpenClaw

OpenClaw 的設定在 `~/.openclaw/openclaw.json`（JSON5 格式）。把 Gateway 註冊成一個 provider，再把 agent 的預設模型指過去：

```
{
  models: {
    mode: "merge",
    providers: {
      atp: {
        baseUrl: "https://api.atptoken.ai/v1",
        apiKey: "${ATP_API_KEY}",
        api: "openai-completions",
        models: [
          { id: "<model from GET /v1/models>", contextWindow: 128000, maxTokens: 32000 },
        ],
      },
    },
  },
  agents: { defaults: { model: { primary: "atp/<model-id>" } } },
}
```

有三個地方會咬人。OpenClaw 直接拒絕純 HTTP，網址一定要是 `https`。模型清單要手動列——它不會去打 `GET /v1/models`，沒列到的 id 就是選不到。還有 `baseUrl` 同時是網路信任邊界，只有那個完全相符的 `scheme://host:port` 會被放行，所以打錯字的症狀是「請求被擋」而不是「網址錯誤」。

### 其他 agent 的通用規則

只要工具有「OpenAI compatible」這一類的 provider，要填的幾乎都是同樣三個值：

- **Base URL** — 填 `https://api.atptoken.ai/v1`。要含 `/v1`，但不要接 `/chat/completions`，路徑由工具自己補。
- **API Key** — 那把 `atp-…` 開頭的 project key。
- **Model** — `GET /v1/models` 回傳的其中一個 id。

| 工具 | 設定位置 | 欄位或變數 | Base URL |
|---|---|---|---|
| Cline | VS Code 設定介面 → API Provider 選 OpenAI Compatible | Base URL / API Key / Model | 含 `/v1` |
| Roo Code | VS Code 設定面板 → API Provider 選 OpenAI Compatible | Base URL / API Key / Model | 含 `/v1` |
| Continue.dev | `~/.continue/config.yaml` | `provider: openai` 加上 `apiBase` | 含 `/v1` |
| OpenCode | `opencode.json` 或 `~/.config/opencode/opencode.json` | `options.baseURL`（npm 套件用 `@ai-sdk/openai-compatible`） | 含 `/v1` |
| Aider | 環境變數 | `OPENAI_API_BASE` 加上 `OPENAI_API_KEY` | 含 `/v1` |

有三件事特別常踩：

- **Aider** — model 要寫成 `openai/<model-id>`。少了這個前綴，請求會被路由到錯的 provider。
- **Cline 與 Roo Code** — context window 與 max output tokens 必須自己手動填。留白的話工具會套預設值，token 帳就算錯了。
- **OpenCode** — 模型清單要自己列（`models`）。它不會去讀 `GET /v1/models`，沒列之前模型選單是空的。

欄位名稱與選單位置會隨版本改動，這張表只是起點，實際以你的工具版本為準。

> **未查證**
>
> Cline 也可以改用它的 Anthropic provider 並填自訂 base URL。那個網址結尾要不要加 `/v1`，我們沒有查證過，所以刻意不寫進上面的表 — 請改用 OpenAI Compatible provider。

### Agent Skills 一行安裝

Skills 是 markdown 格式的操作手冊，讓 agent 在動手寫程式之前，先知道 ATP 的驗證方式、模型查詢、媒體任務與錯誤處理。

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

- [ATP Agent Skills](https://atptoken.ai/zh-tw/docs/agent-skills/)
  七個官方 Skills 的內容、安裝方式，以及怎麼確認裝到哪裡了。

### 排錯

- **`403`** — 模型沒有在該 key 所屬的 project 啟用。到 Console 的 Resources 開啟即可。這是最常見的失敗。
- **`404`** — `/v1` 加錯位置。有些工具會把 host 與路徑分成兩個欄位填，這時 `/v1` 要放在路徑那一邊，不要放進 host。對照上面表格裡你那個工具的那一列。
- **工具說找不到這個模型** — 多數工具需要你手動列出 model id，它們不會自己去讀 `GET /v1/models`。
- **Roo Code 專屬** — Roo 只支援 native tool calling，沒有 XML fallback，所以挑的模型必須完整支援 function calling。

## 後續步驟

- [平台與工作流工具](https://atptoken.ai/zh-tw/docs/platforms/) — Dify、n8n 等用介面組裝的工具
- [Agent Skills](https://atptoken.ai/zh-tw/docs/agent-skills/) — 安裝七個官方 Skills 並驗證安裝結果。
- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 三種可接受的 key 放置位置，以及 `401` 代表什麼。
- [Errors](https://atptoken.ai/zh-tw/docs/errors/) — Gateway 會回傳的每一個狀態碼，以及各自的處理方式。
