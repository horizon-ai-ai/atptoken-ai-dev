# ATP Agent Skills

> Source: https://atptoken.ai/zh-cn/docs/agent-skills/

ATP Agent Skills 是提供给 Codex、Claude Code 与其他支持 `SKILL.md` 的 agent 使用的公开操作手册。安装后，agent 会知道 ATP 的验证方式、统一模型名称、API payload、非同步媒体任务与常见错误，不需要把上游供应商的介面写进你的项目（project）。

## 开始之前

Skills 是接上之后的那一层，不是接上本身。先把 agent 指向 Gateway，再安装这些 Skills。

- [先接上你的 agent](https://atptoken.ai/zh-cn/docs/agents/)
  Claude Code、Codex CLI 与其他 agent 的 base URL、密钥与模型设定——另外还有三个需要特别处理的工具。

> **Skills 不会保存你的 API 密钥**
>
> Skills 只有 Markdown 指引。`atp-` 密钥仍应放在环境变数或密钥管理服务，不要写入 `SKILL.md`、程式码或 git。

## 一行安装

安装全部七个官方 Skills：

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

安装器默认不覆写既有文件。更新官方版本时可明确允许替换：

```bash
curl -fsSL https://atptoken.ai/skills/install.sh | ATP_SKILLS_FORCE=1 sh -s -- codex
```

如果你的安全规范不允许 pipe to shell，先下载、检视再执行：

```bash
curl -fsSL https://atptoken.ai/skills/install.sh -o /tmp/install-atptoken-skills.sh
less /tmp/install-atptoken-skills.sh
sh /tmp/install-atptoken-skills.sh codex
```

## Skills 内容

| Skill | 何时使用 |
|---|---|
| `atptoken-gateway` | 验证、模型探索、共通错误、文件与媒体路由 |
| `atptoken-openai` | OpenAI-compatible chat 与 Responses-style 工作流 |
| `atptoken-anthropic` | Anthropic Messages 格式与 Claude 工具 |
| `atptoken-gemini` | Gemini 原生 `generateContent` 格式 |
| `atptoken-image` | 同步图像生成 |
| `atptoken-video` | 文生影／图生影、task 建立与轮询 |
| `atptoken-audio` | TTS、语音与音讯任务 |

直接下载：[Gateway](../../../skills/atptoken-gateway/SKILL.md) · [OpenAI](../../../skills/atptoken-openai/SKILL.md) · [Anthropic](../../../skills/atptoken-anthropic/SKILL.md) · [Gemini](../../../skills/atptoken-gemini/SKILL.md) · [Image](../../../skills/atptoken-image/SKILL.md) · [Video](../../../skills/atptoken-video/SKILL.md) · [Audio](../../../skills/atptoken-audio/SKILL.md)。

机器可读的完整清单在 [`/skills/manifest.json`](../../../skills/manifest.json)。

## 验证安装

```bash
# Codex
find "${CODEX_HOME:-$HOME/.codex}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"

# Claude Code
find "${CLAUDE_HOME:-$HOME/.claude}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"
```

接著在 agent 中要求「使用 ATP 产生一张图片」或「用 ATP 建立 Wan 影片任务」。agent 应先以同一把项目密钥呼叫 `GET https://api.atptoken.ai/v1/models`，再选择该项目已启用的模型——也就是 [把任何 coding agent 接上 ATP](https://atptoken.ai/zh-cn/docs/agents/) 讲的同一个第一步。如果 agent 跳过这一步、自己写死一个模型名，那就是要纠正的行为。

> **模型权限仍由项目控管**
>
> 安装 Skill 不会自动启用模型，也不会绕过 allowed models。`GET /v1/models` 没有出现的模型不能用；请先到控制台的「资源」调整项目模型。

## 下一步

- [把任何 coding agent 接上 ATP](https://atptoken.ai/zh-cn/docs/agents/) — 设好 Skills 依赖的 base URL、密钥与模型。
- [列出平台可用模型](https://atptoken.ai/zh-cn/docs/models/) — agent 选模型之前应该先读的模型清单。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 请求失败时，每个状态码代表什么。
