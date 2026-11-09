# Connect any coding agent

> Source: https://atptoken.ai/docs/agents/

Any agent that speaks the Anthropic or OpenAI wire format can run on a project key. Three values do the whole job: the Gateway base URL, an `atp-` key, and a model id the project has enabled. This page covers the two agents we document end to end (Claude Code and Codex CLI), the general rule for everything else, and the three tools where the general rule breaks.

An agent can also keep its own model and add ATP's MCP server, `atptoken-api-docs`, which gives it the API guide, a live model check and a video-request checker. Adding it needs no key; only the live model check asks for one. Once it is in one agent, its `atptoken_install` tool can add it to another:

```
claude mcp add --transport http atptoken-api-docs https://mcp.atptoken.ai/mcp
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

[connect.md](https://atptoken.ai/connect.md/) walks an agent through both ways.

## Paste this to your agent

Most people never fill in these fields by hand — they ask the agent to do it. Paste the line below as it is. The agent works out which tool it is, asks you for a key only if it has none, lists the models that key can use, and writes the settings.

```
Follow https://atptoken.ai/connect.md to connect my AI tool to ATP Token.
```

> **Every docs page has a plain-Markdown twin**
>
> Append `.md` to any documentation URL to get the source Markdown — no app shell, no HTML to parse.

## Start by checking which models the key can call

Before touching any config file, list what the key can actually call. Guessing a model name is the single most common way an agent gets this wrong. The project's complete list is `GET /v1/project/models`:

```bash
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

It holds every model the project allows — chat, image, video, audio and embeddings — each with only its `id`, so it tells you *what* you may call, not *where*. Copy the id verbatim.

`GET /v1/models` is a different, narrower list. It is OpenAI's list endpoint, so it shows only the chat models served on `/v1/chat/completions` and `/v1/responses`. Most `claude-*` models are not on it (they use `/v1/messages`), Gemini models are on `/v1beta/models`, and media and embedding models appear on neither. Tools that read a model list automatically read this one, so their pickers show only OpenAI-format chat models.

A model missing from a list is not necessarily unusable: it may be served on another entrypoint. If the project really isn't allowed to call it, the request returns `403` at create time and is not billed — enable it in Console under Resources. If you call it on the wrong entrypoint, you get `422` naming the right one.

## Configure your agent

### Claude Code

Set the base URL (no `/v1` — Claude Code appends `/v1/messages` itself) and send the key as the auth token. Clear `ANTHROPIC_API_KEY` so it doesn't take precedence. The model must be one your project allows on `/v1/messages`; pick it from `GET /v1/project/models`, not `GET /v1/models`.

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # a model from GET /v1/project/models
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

`discover_models` defaults to on, so `hermes model` reads the catalogue from `GET /v1/models` — you do not have to list models by hand. That list holds only OpenAI-format chat models, which is what `transport: chat_completions` can call. Set `transport: anthropic_messages` if you would rather speak the Anthropic format; most `claude-*` models won't appear in the discovered list, so take the id from `GET /v1/project/models` and set it by hand.

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

## Every other agent

Almost every tool with an "OpenAI compatible" provider needs the same three values:

- **Base URL** — `https://api.atptoken.ai/v1`. Include `/v1`; do not append `/chat/completions`, the tool adds the path itself.
- **API key** — the `atp-…` project key.
- **Model** — an id returned by `GET /v1/models`. That list is exactly the OpenAI-format chat models, which is what these providers can call; `claude-*` models on `/v1/messages`, Gemini-entrypoint models, and media models won't work through them.

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

> **Choose OpenAI Compatible in Cline**
>
> This guide uses Cline’s OpenAI Compatible provider. Enter the base URL from the table above; do not reuse these settings for its Anthropic provider.

## Agent Skills in one command

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

## Troubleshooting

- **`401 token_revoked`** — the key is missing, wrong, or revoked. Sending no key at all also returns this, so first check that the tool actually sends the header (`Authorization: Bearer` or `x-api-key`).
- **`403`** — the model is not enabled for the key's project. Turn it on in Console under Resources. This is by far the most common failure, and it is not billed.
- **`422`** — the model is served on a different entrypoint than the one the tool calls; the message names the right one. For example, most `claude-*` models need an Anthropic-format provider, not an OpenAI-compatible one.
- **`404`** — the domain serves only `/v1*` and `/omni/*`, so the path is wrong — usually `/v1` is in the wrong position. Some tools split the host and the request path into two separate fields; when they do, `/v1` belongs on the path side, not in the host. Check your tool's row in the table above.
- **The tool says the model does not exist** — most tools need the model id listed by hand; they do not read `GET /v1/models` for you.
- **Roo Code specifically** — Roo only supports native tool calling and has no XML fallback, so the model you pick must support function calling in full.

## Next steps

- [Platforms and workflow tools](https://atptoken.ai/docs/platforms/) — Dify, n8n, and other interface-driven tools
- [Agent Skills](https://atptoken.ai/docs/agent-skills/) — Install the seven official skills and verify them.
- [Authentication](https://atptoken.ai/docs/auth/) — Where your key can go, and what a `401` means.
- [Errors](https://atptoken.ai/docs/errors/) — Every status code the Gateway returns, with the fix for each.
