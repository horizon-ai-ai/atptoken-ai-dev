# 把任何 coding agent 接上 ATP

> Source: https://atptoken.ai/zh-tw/docs/agents/

任何會說 Anthropic 或 OpenAI wire format 的 agent 都能跑在專案（project）金鑰上。真正要填的只有三個值：Gateway 的 base URL、一把 `atp-` 開頭的金鑰，以及該專案已啟用的模型 ID。這一頁涵蓋我們完整記錄的兩個 agent（Claude Code 與 Codex CLI）、其他工具共用的通用規則，以及三個套用通用規則會壞掉的工具。

agent 也可以保留原本的模型，改加上 ATP 的 MCP 伺服器 `atptoken-api-docs`：它提供 API 文件、即時查模型、送影片任務前的檢查。加上它不需要金鑰，只有「即時查模型」要帶金鑰。裝進一個 agent 之後，它的 `atptoken_install` 工具可以再幫你裝到別的 agent：

```
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

Claude 應用程式、ChatGPT、Cursor 等工具的設定見[加入 ATP MCP 伺服器](https://atptoken.ai/zh-tw/docs/mcp/)。[connect.md](https://atptoken.ai/zh-tw/connect.md/) 會帶 agent 走完這兩種接法。

## 貼給你的 agent

多數人不會自己一格一格填，而是直接叫 agent 去接。下面這一行原樣貼上就好：agent 會自己判斷是哪個工具、沒有金鑰才跟你要、列出這把金鑰能用的模型，再把設定寫好。

```
Follow https://atptoken.ai/connect.md to connect my AI tool to ATP Token.
```

指令維持英文，是因為 connect.md 是寫給機器照做的正規來源；你要改成中文照樣可以，agent 會用你的語言回你。

> **每一頁都有純 markdown 版本**
>
> 任何文件網址後面加上 `.md`，就會拿到這一頁的 markdown 原始碼——沒有頁面外框、不需要剖析 HTML。

## 第一步：先查這把金鑰能呼叫哪些模型

碰任何設定檔之前，先列出這把金鑰實際能呼叫哪些模型。agent 最常見的失敗，就是自己猜一個模型名。專案的完整清單是 `GET /v1/project/models`：

```bash
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

這份清單包含專案允許的所有模型——文字、圖像、影片、語音、向量都在裡面——每筆只有 `id`，所以它告訴你「能用什麼」，不告訴你「打哪個入口」。id 請原樣抄過去。

`GET /v1/models` 是另一份、比較窄的清單。它是 OpenAI 自己的清單端點，只列 `/v1/chat/completions` 與 `/v1/responses` 收的 chat 模型。多數 `claude-*` 不在上面（它們走 `/v1/messages`），Gemini 的在 `/v1beta/models`，媒體與向量模型兩份都沒有。會自動讀模型清單的工具讀的就是這一份，所以它們的選單只會出現 OpenAI 格式的 chat 模型。

清單上沒有，不代表不能用：它可能在別的入口服務。專案真的沒開權限，建立請求時會回 `403`，不收費——請到主控台的「資源」開啟。打錯入口則會回 `422`，訊息會指名正確的入口。

## 設定你的 agent

### Claude Code

設定 base URL（不用加 `/v1`——Claude Code 會自己補上 `/v1/messages`），並把金鑰當成 auth token 送出。清掉 `ANTHROPIC_API_KEY`，避免它蓋過去。模型必須是專案允許、在 `/v1/messages` 服務的模型；從 `GET /v1/project/models` 挑，不要從 `GET /v1/models` 挑。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # a model from GET /v1/project/models
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

在 `~/.codex/config.toml` 把 Gateway 加成自訂的 OpenAI-compatible 供應商（base URL **要包含** `/v1`），再 export `env_key` 指定的那把金鑰。

```
# ~/.codex/config.toml
model = "gpt-5.4"            # a model from GET /v1/models (OpenAI format)
model_provider = "atp"

[model_providers.atp]
name = "ATP"
base_url = "https://api.atptoken.ai/v1"
env_key = "ATP_API_KEY"
wire_api = "responses"
```

```
export ATP_API_KEY="atp-..."
codex
```

兩個工具都用 `Authorization: Bearer atp-…` 驗證。模型必須在該金鑰所屬專案已啟用，否則 Gateway 回傳 `403`。

### Hermes Agent

Hermes 把密鑰放在 `~/.hermes/.env`，其餘設定放 `~/.hermes/config.yaml`。把 Gateway 加成一個具名供應商：

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

`discover_models` 預設開啟，所以 `hermes model` 會直接從 `GET /v1/models` 讀型錄，不用自己列模型。這份清單只有 OpenAI 格式的 chat 模型，也就是 `transport: chat_completions` 能呼叫的那些。想改走 Anthropic 格式就把 `transport` 換成 `anthropic_messages`；多數 `claude-*` 不會出現在自動讀到的清單裡，請從 `GET /v1/project/models` 找 id、手動填。

有兩件事要留意。Hermes 同時還接受舊版的 `custom_providers:` 清單，跟新的 `providers:` 並存時，模型選單與實際執行可能讀到不同來源——只留 `providers:` 就好。另外 `${VAR}` 代換失敗不會報錯，變數名打錯只會留下原字串加一則警告，很難查。

### OpenClaw

OpenClaw 的設定在 `~/.openclaw/openclaw.json`（JSON5 格式）。把 Gateway 註冊成一個供應商，再把 agent 的預設模型指過去：

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

## 其他 agent 的通用規則

只要工具有「OpenAI compatible」這一類的供應商，要填的幾乎都是同樣三個值：

- **Base URL**——填 `https://api.atptoken.ai/v1`。要含 `/v1`，但不要接 `/chat/completions`，路徑由工具自己補。
- **API 金鑰**——那把 `atp-…` 開頭的專案金鑰。
- **Model**——`GET /v1/models` 回傳的其中一個 id。這份清單剛好就是 OpenAI 格式的 chat 模型，也就是這類供應商能呼叫的；走 `/v1/messages` 的 `claude-*`、走 Gemini 入口的模型，以及媒體模型，都不能從這裡接。

| 工具 | 設定位置 | 欄位或變數 | Base URL |
|---|---|---|---|
| Cline | VS Code 設定介面 → API 供應商選 OpenAI Compatible | Base URL / API 金鑰 / Model | 含 `/v1` |
| Roo Code | VS Code 設定面板 → API 供應商選 OpenAI Compatible | Base URL / API 金鑰 / Model | 含 `/v1` |
| Continue.dev | `~/.continue/config.yaml` | `provider: openai` 加上 `apiBase` | 含 `/v1` |
| OpenCode | `opencode.json` 或 `~/.config/opencode/opencode.json` | `options.baseURL`（npm 套件用 `@ai-sdk/openai-compatible`） | 含 `/v1` |
| Aider | 環境變數 | `OPENAI_API_BASE` 加上 `OPENAI_API_KEY` | 含 `/v1` |

有三件事特別常踩：

- **Aider**——model 要寫成 `openai/<model-id>`。少了這個前綴，請求會被路由到錯的供應商。
- **Cline 與 Roo Code**——context window 與 max output tokens 必須自己手動填。留白的話工具會套預設值，token 帳就算錯了。
- **OpenCode**——模型清單要自己列（`models`）。它不會去讀 `GET /v1/models`，沒列之前模型選單是空的。

欄位名稱與選單位置會隨版本改動，這張表只是起點，實際以你的工具版本為準。

> **Cline 請選 OpenAI Compatible**
>
> 本頁的 Cline 設定使用 OpenAI Compatible 供應商；請依上表填入 base URL，不要直接套用到 Anthropic 供應商設定。

## Agent Skills 一行安裝

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

## 疑難排解

- **`401 token_revoked`**——金鑰沒送、打錯或已撤銷。完全沒送金鑰也是這個，所以先確認工具真的有送出 header（`Authorization: Bearer` 或 `x-api-key`）。
- **`403`**——模型沒有在該金鑰所屬的專案啟用。到主控台的「資源」開啟即可。這是最常見的失敗，而且不收費。
- **`422`**——這個模型在別的入口服務，不是工具打的那一個；訊息會指名正確的入口。例如多數 `claude-*` 要用 Anthropic 格式的供應商，不能用 OpenAI 相容供應商。
- **`404`**——這個網域只服務 `/v1*` 與 `/omni/*`，所以是路徑錯了，通常是 `/v1` 加錯位置。有些工具會把 host 與路徑分成兩個欄位填，這時 `/v1` 要放在路徑那一邊，不要放進 host。對照上面表格裡你那個工具的那一列。
- **工具說找不到這個模型**——多數工具需要你手動列出模型 ID，它們不會自己去讀 `GET /v1/models`。
- **Roo Code 專屬**——Roo 只支援 native tool calling，沒有 XML 自動備援（fallback），所以挑的模型必須完整支援 function calling。

## 下一步

- [平台與工作流工具](https://atptoken.ai/zh-tw/docs/platforms/) — Dify、n8n 等用介面組裝的工具
- [Agent Skills](https://atptoken.ai/zh-tw/docs/agent-skills/) — 安裝七個官方 Skills 並驗證安裝結果。
- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 金鑰可以放在哪些位置，以及 `401` 代表什麼。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — Gateway 會回傳的每一個狀態碼，以及各自的處理方式。
