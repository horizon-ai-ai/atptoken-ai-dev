# ATP Agent Skills

> Source: https://atptoken.ai/zh-tw/docs/agent-skills/

ATP Agent Skills 是提供給 Codex、Claude Code 與其他支援 `SKILL.md` 的 agent 使用的公開操作手冊。安裝後，agent 會知道 ATP 的驗證方式、統一模型名稱、API payload、非同步媒體任務與常見錯誤，不需要把上游 provider 的介面寫進你的專案。

Skills 是接上之後的那一層，不是接上本身。先把 agent 指向 Gateway，再安裝這些 Skills。

- [先接上你的 agent](https://atptoken.ai/zh-tw/docs/agents/)
  Claude Code、Codex CLI 與其他 agent 的 base URL、key 與模型設定 — 另外還有三個需要特別處理的工具。

> **Skills 不會保存你的 API key**
>
> Skills 只有 Markdown 指引。`atp-` key 仍應放在環境變數或密鑰管理服務，不要寫入 `SKILL.md`、程式碼或 git。

### 一行安裝

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

### Skills 內容

| Skill | 何時使用 |
|---|---|
| `atptoken-gateway` | 驗證、模型探索、共通錯誤、檔案與媒體路由 |
| `atptoken-openai` | OpenAI-compatible chat 與 Responses-style 工作流 |
| `atptoken-anthropic` | Anthropic Messages 格式與 Claude 工具 |
| `atptoken-gemini` | Gemini 原生 `generateContent` 格式 |
| `atptoken-image` | 同步圖像生成 |
| `atptoken-video` | 文生影／圖生影、task 建立與輪詢 |
| `atptoken-audio` | TTS、語音與音訊任務 |

直接下載：[Gateway](../../../skills/atptoken-gateway/SKILL.md) · [OpenAI](../../../skills/atptoken-openai/SKILL.md) · [Anthropic](../../../skills/atptoken-anthropic/SKILL.md) · [Gemini](../../../skills/atptoken-gemini/SKILL.md) · [Image](../../../skills/atptoken-image/SKILL.md) · [Video](../../../skills/atptoken-video/SKILL.md) · [Audio](../../../skills/atptoken-audio/SKILL.md)。

機器可讀的完整清單在 [`/skills/manifest.json`](../../../skills/manifest.json)。

### 驗證安裝

```bash
# Codex
find "${CODEX_HOME:-$HOME/.codex}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"

# Claude Code
find "${CLAUDE_HOME:-$HOME/.claude}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"
```

接著在 agent 中要求「使用 ATP 產生一張圖片」或「用 ATP 建立 Wan 影片任務」。agent 應先以同一把 project key 呼叫 `GET https://api.atptoken.ai/v1/models`，再選擇該 project 已啟用的模型 — 也就是 [把任何 coding agent 接上 ATP](https://atptoken.ai/zh-tw/docs/agents/) 講的同一個第一步。如果 agent 跳過這一步、自己寫死一個模型名，那就是要糾正的行為。

> **模型權限仍由 project 控管**
>
> 安裝 Skill 不會自動啟用模型，也不會繞過 allowed models。`GET /v1/models` 沒有出現的模型不能用；請先到 Console 的 Resources 調整 project 模型。
