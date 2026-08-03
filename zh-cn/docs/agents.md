# 把任何 coding agent 接上 ATP

> Source: https://atptoken.ai/zh-cn/docs/agents/

任何会说 Anthropic 或 OpenAI wire format 的 agent 都能跑在 project key 上。真正要填的只有三个值：Gateway 的 base URL、一把 `atp-` 开头的 key，以及该 project 已启用的 model id。这一页涵盖我们完整记录的两个 agent（Claude Code 与 Codex CLI）、其他工具共用的通用规则，以及三个套用通用规则会坏掉的工具。

### 贴给你的 agent

多数人不会自己一格一格填，而是直接叫 agent 去接。下面这段就是为了整段复制而写的，把 `<你的工具名>` 换成你要接的工具即可。

```
Read https://atptoken.ai/docs/agents.md and follow it to connect my <your tool> to ATP Token.
My key is in the ATP_API_KEY environment variable.
First call GET https://api.atptoken.ai/v1/models to see which models are available,
then pick one from that list and configure it.
```

指令维持英文、指向英文版页面，是因为那份纯 markdown 是给机器读的正规来源；你要改成中文照样可以。

> **每一页都有纯 markdown 版本**
>
> 任何文件网址后面加上 `.md`，就会拿到这一页的 markdown 原始码 — 没有页面外框、不需要剖析 HTML。上面那段指令要 agent 读的就是它。

### 第一步永远是 GET /v1/models

碰任何设定档之前，先列出这把 key 实际能呼叫哪些模型。agent 最常见的失败，就是自己猜一个模型名。

```bash
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

回传里的每一个 id，这把 key 都能用。清单上没有的模型，代表它没有在该 key 所属的 project 启用，呼叫下去会拿到 `403` — 请先到 Console 的 Resources 开启，再跑一次上面的请求，把 id 原样抄过去。

### Claude Code

设定 base URL（不用加 `/v1` — Claude Code 会自己补上 `/v1/messages`），并把 key 当成 auth token 送出。清掉 `ANTHROPIC_API_KEY`，避免它盖过去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

或把相同的值写进 `~/.claude/settings.json` 的 `env` 区块：

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

在 `~/.codex/config.toml` 把 Gateway 加成自订的 OpenAI-compatible provider（base URL **要包含** `/v1`），再 export `env_key` 指定的那把 key。

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

两个工具都用 `Authorization: Bearer atp-…` 验证。模型必须在该 key 所属 project 已启用，否则 Gateway 回传 `403`。

### Hermes Agent

Hermes 把密钥放在 `~/.hermes/.env`，其余设定放 `~/.hermes/config.yaml`。把 Gateway 加成一个具名 provider：

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

`discover_models` 预设开启，所以 `hermes model` 会直接从 `GET /v1/models` 读型录，不用自己列模型。想改走 Anthropic 格式就把 `transport` 换成 `anthropic_messages`。

有两件事要留意。Hermes 同时还接受旧版的 `custom_providers:` 清单，跟新的 `providers:` 并存时，模型选单与实际执行可能读到不同来源——只留 `providers:` 就好。另外 `${VAR}` 代换失败不会报错，变数名打错只会留下原字串加一则警告，很难查。

### OpenClaw

OpenClaw 的设定在 `~/.openclaw/openclaw.json`（JSON5 格式）。把 Gateway 注册成一个 provider，再把 agent 的预设模型指过去：

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

有三个地方会咬人。OpenClaw 直接拒绝纯 HTTP，网址一定要是 `https`。模型清单要手动列——它不会去打 `GET /v1/models`，没列到的 id 就是选不到。还有 `baseUrl` 同时是网路信任边界，只有那个完全相符的 `scheme://host:port` 会被放行，所以打错字的症状是「请求被挡」而不是「网址错误」。

### 其他 agent 的通用规则

只要工具有「OpenAI compatible」这一类的 provider，要填的几乎都是同样三个值：

- **Base URL** — 填 `https://api.atptoken.ai/v1`。要含 `/v1`，但不要接 `/chat/completions`，路径由工具自己补。
- **API Key** — 那把 `atp-…` 开头的 project key。
- **Model** — `GET /v1/models` 回传的其中一个 id。

| 工具 | 设定位置 | 栏位或变数 | Base URL |
|---|---|---|---|
| Cline | VS Code 设定介面 → API Provider 选 OpenAI Compatible | Base URL / API Key / Model | 含 `/v1` |
| Roo Code | VS Code 设定面板 → API Provider 选 OpenAI Compatible | Base URL / API Key / Model | 含 `/v1` |
| Continue.dev | `~/.continue/config.yaml` | `provider: openai` 加上 `apiBase` | 含 `/v1` |
| OpenCode | `opencode.json` 或 `~/.config/opencode/opencode.json` | `options.baseURL`（npm 套件用 `@ai-sdk/openai-compatible`） | 含 `/v1` |
| Aider | 环境变数 | `OPENAI_API_BASE` 加上 `OPENAI_API_KEY` | 含 `/v1` |

有三件事特别常踩：

- **Aider** — model 要写成 `openai/<model-id>`。少了这个前缀，请求会被路由到错的 provider。
- **Cline 与 Roo Code** — context window 与 max output tokens 必须自己手动填。留白的话工具会套预设值，token 帐就算错了。
- **OpenCode** — 模型清单要自己列（`models`）。它不会去读 `GET /v1/models`，没列之前模型选单是空的。

栏位名称与选单位置会随版本改动，这张表只是起点，实际以你的工具版本为准。

> **未查证**
>
> Cline 也可以改用它的 Anthropic provider 并填自订 base URL。那个网址结尾要不要加 `/v1`，我们没有查证过，所以刻意不写进上面的表 — 请改用 OpenAI Compatible provider。

### Agent Skills 一行安装

Skills 是 markdown 格式的操作手册，让 agent 在动手写代码之前，先知道 ATP 的验证方式、模型查询、媒体任务与错误处理。

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

- [ATP Agent Skills](https://atptoken.ai/zh-cn/docs/agent-skills/)
  七个官方 Skills 的内容、安装方式，以及怎么确认装到哪里了。

### 排错

- **`403`** — 模型没有在该 key 所属的 project 启用。到 Console 的 Resources 开启即可。这是最常见的失败。
- **`404`** — `/v1` 加错位置。有些工具会把 host 与路径分成两个栏位填，这时 `/v1` 要放在路径那一边，不要放进 host。对照上面表格里你那个工具的那一列。
- **工具说找不到这个模型** — 多数工具需要你手动列出 model id，它们不会自己去读 `GET /v1/models`。
- **Roo Code 专属** — Roo 只支援 native tool calling，没有 XML fallback，所以挑的模型必须完整支援 function calling。

## 后续步骤

- [平台与工作流工具](https://atptoken.ai/zh-cn/docs/platforms/) — Dify、n8n 等用介面组装的工具
- [Agent Skills](https://atptoken.ai/zh-cn/docs/agent-skills/) — 安装七个官方 Skills 并验证安装结果。
- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 三种可接受的 key 放置位置，以及 `401` 代表什么。
- [Errors](https://atptoken.ai/zh-cn/docs/errors/) — Gateway 会回传的每一个状态码，以及各自的处理方式。
