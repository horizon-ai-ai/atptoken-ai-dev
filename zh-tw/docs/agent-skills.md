# ATP Agent Skills

> Source: https://atptoken.ai/zh-tw/docs/agent-skills/

ATP Agent Skills 是提供給 Codex、Claude Code 與其他支援 `SKILL.md` 的 agent 使用的公開操作手冊。安裝後，agent 會知道 ATP 的驗證方式、統一模型名稱、API payload、非同步媒體任務與常見錯誤，不需要把上游供應商的介面寫進你的專案（project）。

## 想用 MCP？ATP 有 MCP 伺服器

同一套指引也有 MCP 版本：`atptoken-api-docs`，網址 `https://mcp.atptoken.ai/mcp`（Streamable HTTP）。它提供 API 文件、即時查模型、送影片任務前的檢查。加上它不需要金鑰，只有「即時查模型」要帶金鑰。裝進一個 agent 之後，它的 `atptoken_install` 工具可以再幫你裝到別的 agent：

```
claude mcp add --transport http atptoken-api-docs https://mcp.atptoken.ai/mcp
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

想讓 agent 自己接好，把這句話貼給它：`照 https://atptoken.ai/connect.md 的步驟，幫我把 ATP Token 接上。`

## 開始之前

Skills 是接上之後的那一層，不是接上本身。先把 agent 指向 Gateway，再安裝這些 Skills。

- [先接上你的 agent](https://atptoken.ai/zh-tw/docs/agents/)
  Claude Code、Codex CLI 與其他 agent 的 base URL、金鑰與模型設定——另外還有三個需要特別處理的工具。

> **Skills 不會保存你的 API 金鑰**
>
> Skills 只有 Markdown 指引。`atp-` 金鑰仍應放在環境變數或密鑰管理服務，不要寫入 `SKILL.md`、程式碼或 git。

## 一行安裝

安裝全部七個官方 Skills：

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

安裝器預設不覆寫既有檔案。更新官方版本時可明確允許替換：

```bash
curl -fsSL https://atptoken.ai/skills/install.sh | ATP_SKILLS_FORCE=1 sh -s -- codex
```

如果你的安全規範不允許 pipe to shell，先下載、檢視再執行：

```bash
curl -fsSL https://atptoken.ai/skills/install.sh -o /tmp/install-atptoken-skills.sh
less /tmp/install-atptoken-skills.sh
sh /tmp/install-atptoken-skills.sh codex
```

## Skills 內容

| Skill | 何時使用 |
|---|---|
| `atptoken-gateway` | 驗證、模型探索、共通錯誤、檔案與媒體路由 |
| `atptoken-openai` | OpenAI-compatible chat 與 Responses-style 工作流 |
| `atptoken-anthropic` | Anthropic Messages 格式與 Claude 工具 |
| `atptoken-gemini` | Gemini 原生 `generateContent` 格式 |
| `atptoken-image` | 圖像生成與改圖（非同步任務） |
| `atptoken-video` | 文生影／圖生影、task 建立與輪詢 |
| `atptoken-audio` | TTS、語音與音訊任務 |

直接下載：[Gateway](../../../skills/atptoken-gateway/SKILL.md) · [OpenAI](../../../skills/atptoken-openai/SKILL.md) · [Anthropic](../../../skills/atptoken-anthropic/SKILL.md) · [Gemini](../../../skills/atptoken-gemini/SKILL.md) · [Image](../../../skills/atptoken-image/SKILL.md) · [Video](../../../skills/atptoken-video/SKILL.md) · [Audio](../../../skills/atptoken-audio/SKILL.md)。

機器可讀的完整清單在 [`/skills/manifest.json`](../../../skills/manifest.json)。

## 驗證安裝

```bash
# Codex
find "${CODEX_HOME:-$HOME/.codex}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"

# Claude Code
find "${CLAUDE_HOME:-$HOME/.claude}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"
```

接著在 agent 中要求「使用 ATP 產生一張圖片」或「用 ATP 建立 Wan 影片任務」。agent 應先以同一把專案金鑰呼叫 `GET https://api.atptoken.ai/v1/project/models`（專案的完整清單，媒體模型也在裡面），再選擇該專案已啟用的模型——也就是 [把任何 coding agent 接上 ATP](https://atptoken.ai/zh-tw/docs/agents/) 講的同一個第一步。這裡不能用 `GET /v1/models`：它只列 OpenAI 格式的 chat 模型，圖像與影片模型永遠不會出現在上面。如果 agent 跳過這一步、自己寫死一個模型名，那就是要糾正的行為。

> **模型權限仍由專案控管**
>
> 安裝 Skill 不會自動啟用模型，也不會繞過 allowed models。專案沒開權限的模型，建立請求時會回 `403`（不收費）；請先到主控台的「資源」調整專案模型。專案允許哪些模型，看 `GET /v1/project/models`——`GET /v1/models` 上沒有的模型，可能只是走別的入口。

## 下一步

- [把任何 coding agent 接上 ATP](https://atptoken.ai/zh-tw/docs/agents/) — 設好 Skills 依賴的 base URL、金鑰與模型。
- [列出平台可用模型](https://atptoken.ai/zh-tw/docs/models/) — agent 選模型之前應該先讀的模型清單。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 請求失敗時，每個狀態碼代表什麼。
