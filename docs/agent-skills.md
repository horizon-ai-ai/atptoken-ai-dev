# ATP Agent Skills

> Source: https://atptoken.ai/docs/agent-skills/

ATP Agent Skills are public operating guides for Codex, Claude Code, and other agents that support `SKILL.md`. They teach an agent ATP authentication, unified model names, request payloads, asynchronous media tasks, and common errors without exposing provider-specific APIs in your application.

## Prefer MCP? Use the ATP MCP server

The same guidance is also an MCP server: `atptoken-api-docs` at `https://mcp.atptoken.ai/mcp` (Streamable HTTP). It gives an agent the API guide, a live model check and a checker for video requests. Adding it needs no key; only the live model check asks for one. Once it is in one agent, its `atptoken_install` tool can add it to another:

```
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

Setup for the Claude app, ChatGPT, Cursor and other tools is in [Add the ATP MCP server](https://atptoken.ai/docs/mcp/). To have an agent set up either way for you, paste this to it: `Follow https://atptoken.ai/connect.md to connect ATP Token for me.`

## Before you start

Skills are the layer above the connection, not a replacement for it. Point the agent at the Gateway first, then install these.

- [Connect your agent first](https://atptoken.ai/docs/agents/)
  Base URL, key, and model for Claude Code, Codex CLI, and every other agent — plus the three tools that need special handling.

> **Skills never store your API key**
>
> Skills are Markdown instructions only. Keep the `atp-` key in an environment variable or secret manager; never put it in `SKILL.md`, source code, or git.

## One-command install

Install all seven official skills:

```bash
# Codex
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- codex

# Claude Code
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude

# Install for both
curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- both
```

The installer does not overwrite existing files by default. Explicitly allow replacement when updating:

```bash
curl -fsSL https://atptoken.ai/skills/install.sh | ATP_SKILLS_FORCE=1 sh -s -- codex
```

If your security policy disallows piping into a shell, download, inspect, and run:

```bash
curl -fsSL https://atptoken.ai/skills/install.sh -o /tmp/install-atptoken-skills.sh
less /tmp/install-atptoken-skills.sh
sh /tmp/install-atptoken-skills.sh codex
```

## Included skills

| Skill | Use it for |
|---|---|
| `atptoken-gateway` | Authentication, model discovery, shared errors, files, and media routing |
| `atptoken-openai` | OpenAI-compatible chat and Responses-style workflows |
| `atptoken-anthropic` | Anthropic Messages format and Claude tools |
| `atptoken-gemini` | Native Gemini `generateContent` format |
| `atptoken-image` | Image generation and editing as asynchronous tasks |
| `atptoken-video` | Text/image-to-video, task creation, and polling |
| `atptoken-audio` | TTS, speech, and audio tasks |

Direct downloads: [Gateway](../../../skills/atptoken-gateway/SKILL.md) · [OpenAI](../../../skills/atptoken-openai/SKILL.md) · [Anthropic](../../../skills/atptoken-anthropic/SKILL.md) · [Gemini](../../../skills/atptoken-gemini/SKILL.md) · [Image](../../../skills/atptoken-image/SKILL.md) · [Video](../../../skills/atptoken-video/SKILL.md) · [Audio](../../../skills/atptoken-audio/SKILL.md).

The machine-readable catalogue is available at [`/skills/manifest.json`](../../../skills/manifest.json).

## Verify the install

```bash
# Codex
find "${CODEX_HOME:-$HOME/.codex}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"

# Claude Code
find "${CLAUDE_HOME:-$HOME/.claude}/skills" -maxdepth 2 -name SKILL.md \
  -path "*/atptoken-*"
```

Then ask the agent to “generate an image with ATP” or “create a Wan video task with ATP.” It should first call `GET https://api.atptoken.ai/v1/project/models` with the same project key — the project's complete list, media models included — then choose a model enabled for that project: the same opening move described in [Connect any coding agent](https://atptoken.ai/docs/agents/). `GET /v1/models` won't do here: it lists only OpenAI-format chat models, so image and video models never appear on it. If the agent skips it and hard-codes a model name instead, that is the behaviour to correct.

> **Project permissions still apply**
>
> Installing a skill does not enable a model or bypass allowed models. A model the project isn't allowed to call returns `403` at create time (not billed); enable it for the project in Console Resources first. Check `GET /v1/project/models` for what the project allows — a model missing from `GET /v1/models` may simply be served on another entrypoint.

## Next steps

- [Connect any coding agent](https://atptoken.ai/docs/agents/) — Set the base URL, key and model the skills rely on.
- [List available models](https://atptoken.ai/docs/models/) — The model list an agent should read before it picks a model.
- [Error codes](https://atptoken.ai/docs/errors/) — What each status code means when a request fails.
