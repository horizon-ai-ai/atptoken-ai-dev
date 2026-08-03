# Connect any coding agent

> Source: https://atptoken.ai/docs/agents/

Any agent that speaks the Anthropic or OpenAI wire format can run on a project key. Three values do the whole job: the Gateway base URL, an `atp-` key, and a model id the project has enabled. This page covers the two agents we document end to end (Claude Code and Codex CLI), the general rule for everything else, and the three tools where the general rule breaks.

### Paste this to your agent

Most people never fill in these fields by hand — they ask the agent to do it. The block below is written to be pasted verbatim; replace `<your tool>` with the tool you want connected.

```
Read https://atptoken.ai/docs/agents.md and follow it to connect my <your tool> to ATP Token.
My key is in the ATP_API_KEY environment variable.
First call GET https://api.atptoken.ai/v1/models to see which models are available,
then pick one from that list and configure it.
```

> **Every docs page has a plain-Markdown twin**
>
> Append `.md` to any documentation URL to get the source Markdown — no app shell, no HTML to parse. That is what the prompt above points the agent at.

### Start with GET /v1/models

Before touching any config file, list what the key can actually call. Guessing a model name is the single most common way an agent gets this wrong.

```bash
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

Every id in the response is usable by that key. A model that is missing from the list is not enabled for the key's project, and calling it returns `403` — enable it in Console under Resources first, then re-run the request above and copy the id verbatim.

### Claude Code

Set the base URL (no `/v1` — Claude Code appends `/v1/messages` itself) and send the key as the auth token. Clear `ANTHROPIC_API_KEY` so it doesn't take precedence.

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

Or set the same values under the `env` block of `~/.claude/settings.json`:

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

Add the Gateway as a custom OpenAI-compatible provider in `~/.codex/config.toml` (base URL **includes** `/v1`), then export the key named by `env_key`.

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

Both tools authenticate with `Authorization: Bearer atp-…`. The model must be enabled for the key's project, or the Gateway returns `403`.

### Hermes Agent

Hermes keeps secrets in `~/.hermes/.env` and everything else in `~/.hermes/config.yaml`. Add the Gateway as a named provider:

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

`discover_models` defaults to on, so `hermes model` reads the catalogue from `GET /v1/models` — you do not have to list models by hand. Set `transport: anthropic_messages` if you would rather speak the Anthropic format.

Two things to watch. Hermes still accepts an older `custom_providers:` list alongside the newer `providers:` map; keep only `providers:` or the model picker and the runtime can end up reading different entries. And `${VAR}` substitution fails silently — a typo in the variable name leaves the literal string in place with only a warning.

### OpenClaw

OpenClaw keeps its configuration in `~/.openclaw/openclaw.json` (JSON5). Register the Gateway as a provider, then point the agent default at it:

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

Three things that bite. OpenClaw rejects plain HTTP outright, so the URL has to be `https`. The model list is manual — it never calls `GET /v1/models`, and an id you leave out simply is not selectable. And `baseUrl` doubles as a network trust boundary: only that exact `scheme://host:port` origin is allowed through, so a typo reads as a blocked request rather than a wrong URL.

### Every other agent

Almost every tool with an "OpenAI compatible" provider needs the same three values:

- **Base URL** — `https://api.atptoken.ai/v1`. Include `/v1`; do not append `/chat/completions`, the tool adds the path itself.
- **API key** — the `atp-…` project key.
- **Model** — an id returned by `GET /v1/models`.

| Tool | Where to set it | Field or variable | Base URL |
|---|---|---|---|
| Cline | VS Code settings UI → API Provider: OpenAI Compatible | Base URL / API Key / Model | includes `/v1` |
| Roo Code | VS Code settings panel → API Provider: OpenAI Compatible | Base URL / API Key / Model | includes `/v1` |
| Continue.dev | `~/.continue/config.yaml` | `provider: openai` plus `apiBase` | includes `/v1` |
| OpenCode | `opencode.json` or `~/.config/opencode/opencode.json` | `options.baseURL` (npm package `@ai-sdk/openai-compatible`) | includes `/v1` |
| Aider | environment variables | `OPENAI_API_BASE` plus `OPENAI_API_KEY` | includes `/v1` |

Three things bite people repeatedly:

- **Aider** — write the model as `openai/<model-id>`. Without the prefix it routes to the wrong provider.
- **Cline and Roo Code** — fill in the context window and max output tokens by hand. Left blank, they fall back to defaults and the token accounting is wrong.
- **OpenCode** — you have to list the models yourself (`models`). It does not read `GET /v1/models`, so the picker stays empty until you do.

Field names and menu paths move between releases, so treat the table as a starting point and follow your tool's own version.

> **Not verified**
>
> Cline can also be pointed at its Anthropic provider with a custom base URL. We have not verified whether that URL wants `/v1` on the end, so it is deliberately absent from the table above — use the OpenAI Compatible provider instead.

### Agent Skills in one command

Skills are Markdown operating guides that teach an agent ATP authentication, model discovery, media tasks, and error handling before it writes any code.

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

- [ATP Agent Skills](https://atptoken.ai/docs/agent-skills/)
  The seven official skills, install options, and how to verify what landed on disk.

### Troubleshooting

- **`403`** — the model is not enabled for the key's project. Turn it on in Console under Resources. This is by far the most common failure.
- **`404`** — `/v1` is in the wrong position. Some tools split the host and the request path into two separate fields; when they do, `/v1` belongs on the path side, not in the host. Check your tool's row in the table above.
- **The tool says the model does not exist** — most tools need the model id listed by hand; they do not read `GET /v1/models` for you.
- **Roo Code specifically** — Roo only supports native tool calling and has no XML fallback, so the model you pick must support function calling in full.

## Next steps

- [Platforms and workflow tools](https://atptoken.ai/docs/platforms/) — Dify, n8n, and other interface-driven tools
- [Agent Skills](https://atptoken.ai/docs/agent-skills/) — Install the seven official skills and verify them.
- [Authentication](https://atptoken.ai/docs/auth/) — The three accepted key locations, and what a `401` means.
- [Errors](https://atptoken.ai/docs/errors/) — Every status code the Gateway returns, with the fix for each.
