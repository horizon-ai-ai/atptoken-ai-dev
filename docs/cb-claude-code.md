# Run Claude Code on ATP

> Source: https://atptoken.ai/docs/cb-claude-code/

Point Claude Code at the Gateway and drive any allowed model through a project key — no code changes, just environment variables.

## 1. Create a project API key

In the console, create (or choose) an organization, workspace, and project, then issue an API key from that project. The key inherits the project's allowed models and credit balance. Copy the full secret — it's shown only once. See [Managing API keys](https://atptoken.ai/docs/console-keys/).

## 2. Point Claude Code at the Gateway

Set the base URL (no `/v1` — Claude Code appends `/v1/messages` itself), send the key as the auth token, and clear `ANTHROPIC_API_KEY` so it doesn't take precedence.

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

Prefer a config file? Put the same values under the `env` block of `~/.claude/settings.json`.

## 3. Pick an allowed model

`ANTHROPIC_MODEL` must be a model id returned by [GET /v1/models](https://atptoken.ai/docs/models/) and enabled for the key's project — otherwise the Gateway returns `403`. List the ids first if you're unsure.

## 4. Verify

Run a prompt in Claude Code, then open the console: the call shows up under Request logs, and the credits it spent appear on the Usage page. See [Usage & logs](https://atptoken.ai/docs/monitoring/).

> **Codex too**
>
> The same idea works for Codex and other agents that speak the OpenAI or Anthropic wire format — see [Coding agents](https://atptoken.ai/docs/agents/) for the Codex config.
