# Run Claude Code on ATP

> Source: https://atptoken.ai/docs/cb-claude-code/

Point Claude Code at the Gateway and drive any allowed model through a project key — no code changes, just environment variables.

## 1. Create a project API key

Sign in at atptoken.ai and create (or choose) an organization, then a workspace, then a project — all three must exist before you can create a key — and issue an API key from that project. One key is bound to one project: it inherits that project's allowed models and credit balance. Copy the full secret — it's shown only once. See [Managing API keys](https://atptoken.ai/docs/console-keys/).

## 2. Point Claude Code at the Gateway

Set the base URL (no `/v1` — Claude Code appends `/v1/messages` itself), send the key as the auth token, and clear `ANTHROPIC_API_KEY` so it doesn't take precedence.

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # a model from GET /v1/project/models
claude
```

Prefer a config file? Put the same values under the `env` block of `~/.claude/settings.json`.

## 3. Pick an allowed model

`ANTHROPIC_MODEL` must be enabled for the key's project and served on `/v1/messages`. Don't look for it in `GET /v1/models`: that is OpenAI's list, and most `claude-*` models are not on it. Call `GET /v1/project/models` with the same key for the project's complete list.

```
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN"
```

A model the project isn't allowed to call returns `403` (not billed); a model served on a different entrypoint returns `422` naming that entrypoint. See [Model discovery](https://atptoken.ai/docs/models/).

## 4. Verify

Run a prompt in Claude Code, then open the console: the call shows up under Request logs, and the credits it spent appear on the Usage page. See [Usage & logs](https://atptoken.ai/docs/monitoring/).

> **Codex too**
>
> The same idea works for Codex and other agents that speak the OpenAI or Anthropic wire format — see [Coding agents](https://atptoken.ai/docs/agents/) for the Codex config.

## Next steps

- [Coding agents](https://atptoken.ai/docs/agents/) — Codex, Cline, and other agents on the same Gateway.
- [Model discovery](https://atptoken.ai/docs/models/) — List the model ids you can set as `ANTHROPIC_MODEL`.
- [Usage & logs](https://atptoken.ai/docs/monitoring/) — Find each Claude Code call and the credits it used.
