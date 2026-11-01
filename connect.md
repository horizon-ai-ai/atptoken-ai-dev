# Connect ATP Token — steps for an AI assistant

You are an AI assistant (Claude Code, Codex or another coding agent), and the
person you work for wants their AI tool to run on ATP Token
(https://atptoken.ai): one API key and one endpoint for OpenAI, Anthropic,
Gemini, DeepSeek, Qwen, Kimi and more, billed against their ATP project.

This page is the whole setup. Do not crawl the rest of atptoken.ai to work it
out: the website and the console are written for people, and the console needs
a browser sign-in you do not have. Every fact you need is here or at a `.md`
link below.

Talk to the person in their own language, in plain words: they may not be a
programmer. Do the steps yourself; ask the person only for what is marked
**Person**.

## The three values

| Value | Claude Code | Codex and OpenAI-compatible tools |
|---|---|---|
| Base URL | `https://api.atptoken.ai` (no `/v1`) | `https://api.atptoken.ai/v1` |
| API key | an `atp-…` project key | the same key |
| Model | an id from `GET /v1/models` | an id from `GET /v1/models` |

## 1. Get the key

If the `ATP_API_KEY` environment variable is set, or the person already pasted
a key that starts with `atp-`, use it and skip to step 2.

Otherwise, **Person:** tell them, in their language: "Open
https://atptoken.ai/console/keys, press Create API key, and paste the key to
me. It is shown only once." If they have no account, they sign up at
https://atptoken.ai/signup first. Wait for the key; do not continue with a
placeholder.

Treat the key like a password. Do not repeat it back, write it into project
files, or commit it. It belongs only in the user-level config named below.

## 2. List the models this key can use

```sh
curl -s https://api.atptoken.ai/v1/models -H "Authorization: Bearer $ATP_API_KEY"
```

Every `id` in the reply works with this key; nothing else does. Never guess a
model id. If the reply is `401`, the key is wrong or revoked: go back to
step 1. If the list is empty, **Person:** they enable models for the key's
project at https://atptoken.ai/console/workspaces, then you list again.

Pick a model the person asked for. If they did not say, pick a coding model
from the list (for Claude Code, a `claude-` model) and tell them which.

## 3. Find out which app you are, then configure it

- Claude Code (you can run the `claude` command): **3a**.
- Codex (CLI, IDE extension or desktop app; settings in `~/.codex/config.toml`): **3b**.
- Anything else: **3c**.

Keep the person's unrelated settings. Edit only the keys named here.

### 3a. Claude Code

Merge this into `~/.claude/settings.json` (create the file if it is missing).
Put the key in place of `KEY` and the chosen model in place of `MODEL`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.atptoken.ai",
    "ANTHROPIC_AUTH_TOKEN": "KEY",
    "ANTHROPIC_API_KEY": ""
  },
  "model": "MODEL"
}
```

`ANTHROPIC_API_KEY` must stay empty, or it overrides the ATP key. Do not add
`/v1` to the base URL; Claude Code adds `/v1/messages` itself.

**Person:** ask them to quit Claude Code and start it again, then send any
short message. The settings load only at start.

### 3b. Codex

Add this to `~/.codex/config.toml` (create it if missing; if a
`[model_providers.atp]` table exists, replace it). Put the chosen model in
place of `MODEL`:

```toml
model = "MODEL"
model_provider = "atp"

[model_providers.atp]
name = "ATP Token"
base_url = "https://api.atptoken.ai/v1"
env_key = "ATP_API_KEY"
wire_api = "responses"
```

Codex reads the key from `ATP_API_KEY`. If it is not already set, add
`export ATP_API_KEY="KEY"` to the person's shell startup file (`~/.zshrc` on
macOS, `~/.bashrc` on most Linux), or on Windows run
`setx ATP_API_KEY "KEY"`.

Current Codex accepts only `wire_api = "responses"`. Older ATP pages showed
`wire_api = "chat"`; Codex now refuses it, so do not use it.

**Person:** ask them to open a new terminal, start `codex` again and send any
short message. If Codex reports `404` or an error about the Responses API,
stop and tell the person that Codex cannot use ATP yet; Claude Code and the
tools in 3c still can. Do not try other endpoints to work around it.

### 3c. Other tools

Most tools have an "OpenAI compatible" provider. Fill in base URL
`https://api.atptoken.ai/v1` (with `/v1`, without `/chat/completions`), the
`atp-` key and a model id from step 2. Tool-specific notes, including Cline,
Roo Code, Continue, OpenCode, Hermes and OpenClaw, are in
https://atptoken.ai/docs/agents.md.

## 4. Check it works

The first message in the restarted tool is the check. Then tell the person, in
their language, that their tool now runs on ATP Token, which model it uses, and
that each request appears in https://atptoken.ai/console/logs and is paid from
the project's credits.

If a request fails, read the status: `401` wrong key, `402` the project is out
of credits (**Person:** top up at https://atptoken.ai/console/billing), `403`
the model is not enabled for this project. More in
https://atptoken.ai/docs/errors.md.

## 5. Optional: install the ATP skills

They teach you ATP's API in later sessions too: model listing, image, video
and audio tasks, errors. Ask the person first, then run:

```sh
npx skills add https://atptoken.ai -g -a claude-code -y
```

For Codex use `-a codex`. If `npx` is missing, use
`curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude` (or
`codex`). If the person prefers not to install anything, skip this step.

## 6. Tell the person what they can ask for

Give a few examples in their language, for instance:

- "Translate this project's README into English."
- "Use ATP to draw a product hero image."
- "Use ATP to turn this picture into a 5-second video."

## More

- Every page of the docs has a markdown copy: add `.md` to its URL.
- Site overview for AI assistants: https://atptoken.ai/llms.txt
- Writing your own program against the API: https://atptoken.ai/docs/quickstart.md
