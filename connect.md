# Connect ATP Token — steps for an AI assistant

You are an AI assistant (Claude Code, Codex or another coding agent), and the
person you work for wants to connect you to ATP Token (https://atptoken.ai):
one API key and one endpoint for OpenAI, Anthropic, Gemini, DeepSeek, Qwen,
Kimi and more, plus image, video and speech models, billed against their ATP
project.

## 0. Two ways to connect: API or MCP

People connect ATP in one of two ways, and the choice is theirs; they can also
do both. Most people have not heard of the difference, so if their words do
not already pick one, it helps to explain both before starting. What they
usually need to hear:

1. **API connection**: the model behind the assistant (Claude Code / Codex)
   becomes an ATP model, so every reply is billed to their ATP credits. For
   people who want ATP to be where their models and spending are managed.
   Needs an ATP API key.
2. **MCP connection**: the assistant keeps the model it uses now and adds
   ATP's MCP server, `atptoken-api-docs` at `https://mcp.atptoken.ai/mcp`.
   It gives the assistant ATP's API guide, a live model check and a checker
   for video requests, so it can call ATP correctly, for example to make
   pictures, videos and speech. Adding it needs no key; actually calling ATP
   (and spending credits) does.

- 1 = **path A, API connection**: steps 1 to 4.
- 2 = **path B, MCP connection**: step 3m. When the person also wants you to
  make media through ATP now, steps 1, 2 and 3d as well.

Everything needed for either path is on this page or at a `.md` link below.
The website and the console are written for people, and the console needs a
browser sign-in.

Talk to the person in their own language, in plain words: they may not be a
programmer. Do the steps yourself; ask the person only for what is marked
**Person**.

## The three values

| Value | Claude Code | Codex and OpenAI-compatible tools |
|---|---|---|
| Base URL | `https://api.atptoken.ai` (no `/v1`) | `https://api.atptoken.ai/v1` |
| API key | an `atp-…` project key | the same key |
| Model | an id from `GET /v1/project/models` | an id from `GET /v1/models` |

## 1. Get the key

If the `ATP_API_KEY` environment variable is set, or the person already pasted
a key that starts with `atp-`, use it and skip to step 2.

Otherwise, **Person:** tell them, in their language: "Open
https://atptoken.ai/console/keys, press Create API key, and paste the key to
me. It is shown only once." If they have no account, they sign up at
https://atptoken.ai/signup first. Wait for the key; do not continue with a
placeholder.

If they would rather not paste the key in the chat, give them the line from
step 3d to run themselves with their key in it, ask them to open a new
terminal and start you again, and continue once `ATP_API_KEY` is set.

Treat the key like a password. Do not repeat it back, write it into project
files, or commit it. It belongs only in the user-level config named below.

## 2. List the model ids

```sh
curl -s https://api.atptoken.ai/v1/project/models -H "Authorization: Bearer $ATP_API_KEY"
```

This lists everything the key's project allows: chat, image, video and speech
models. Use ids from this reply exactly; never guess a model id. A `200` proves
the key works; a `401` means it is wrong or revoked: go back to step 1. A
request to a model the project does not allow returns `403` (**Person:** they
enable it at https://atptoken.ai/console/workspaces).

`GET /v1/models` is a narrower list: only the OpenAI-format chat models
(`/v1/chat/completions`, `/v1/responses`). Codex and the tools in 3c can call
only those, so pick their model from it. Most `claude-*` models are not on it,
because Claude Code calls them on `/v1/messages`; for Claude Code, pick from
`GET /v1/project/models`.

Path A: pick a model the person asked for. If they did not say, pick a
coding model (for Claude Code, a `claude-` model from
`GET /v1/project/models`) and tell them which. Path B: you do not change your own model. Prices of every model are
at https://atptoken.ai/models/.

## 3. Find out which app you are, then configure it

Path B goes to **3m** (and **3d** when it uses a key). For path A:

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

Codex reads the key from `ATP_API_KEY`. If it is not already set, do 3d.

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

### 3d. Keep the key in `ATP_API_KEY`

If `ATP_API_KEY` is not already set, add `export ATP_API_KEY="KEY"` to the
person's shell startup file (`~/.zshrc` on macOS, `~/.bashrc` on most Linux),
or on Windows run `setx ATP_API_KEY "KEY"`. New terminals and new sessions of
you pick it up; for this session, use the key directly.

### 3m. Add the ATP MCP server

No key is needed for this.

- Claude Code: `claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp`
- Codex: `codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp`
- Claude app (web, desktop), ChatGPT, Cursor, Cline, Gemini CLI and other
  tools: follow your tool's section in https://atptoken.ai/docs/mcp.md. In
  short, add the remote (Streamable HTTP) MCP URL `https://mcp.atptoken.ai/mcp`.

Optional: with the key attached, its `atptoken_list_models` tool can check
live which models this key's project allows. In Claude Code add
`--header "Authorization: Bearer $ATP_API_KEY"` to the command above (if the
server is already added, run `claude mcp remove --scope user atptoken-api-docs`
first); in Codex add `--bearer-token-env-var ATP_API_KEY`.

**Person:** ask them to start a new session of you; MCP tools load at start.

## 4. Check it works

Path B: in the new session, call the `atptoken_docs` tool with path `start`.
A reply means the MCP connection works, and it costs nothing. Tell the person
it is connected; if they also gave a key, tell them they can now ask you for
pictures, videos and speech through ATP, each paid from the project's credits.

Path A: the first message in the restarted tool is the check. Then tell the person, in
their language, that their tool now runs on ATP Token, which model it uses, and
that each request appears in https://atptoken.ai/console/logs and is paid from
the project's credits.

If a request fails, read the status: `401` wrong key, `402` the project is out
of credits (**Person:** top up at https://atptoken.ai/console/billing), `403`
the model is not enabled for this project. More in
https://atptoken.ai/docs/errors.md.

## 5. Optional: install the ATP skills

The same guidance as the MCP server, kept as local files instead: model
listing, image, video and audio tasks, errors. Useful for tools without MCP.
Ask the person first, then run:

```sh
npx skills add https://atptoken.ai -g -a claude-code -y
```

For Codex use `-a codex`. If `npx` is missing, use
`curl -fsSL https://atptoken.ai/skills/install.sh | sh -s -- claude` (or
`codex`). If the person prefers not to install anything, read
https://atptoken.ai/skill.md and follow it for this session instead.

## 6. Tell the person what they can ask for

Give a few examples in their language, for instance:

- "Translate this project's README into English."
- "Use ATP to draw a product hero image."
- "Use ATP to turn this picture into a 5-second video."

## More

- Every page of the docs has a markdown copy: add `.md` to its URL.
- Site overview for AI assistants: https://atptoken.ai/llms.txt
- Writing your own program against the API: https://atptoken.ai/docs/quickstart.md
