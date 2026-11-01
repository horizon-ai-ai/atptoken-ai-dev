# Connect ATP Token — steps for an AI assistant

You are an AI assistant (Claude Code, Codex or another coding agent), and the
person you work for wants to connect you to ATP Token (https://atptoken.ai):
one API key and one endpoint for OpenAI, Anthropic, Gemini, DeepSeek, Qwen,
Kimi and more, plus image, video and speech models, billed against their ATP
project.

## 0. Two ways to connect: API or MCP-style tools

People connect ATP in one of two ways, and the choice is theirs. Most people
have not heard of the difference, so if their words do not already pick one,
it helps to explain both before starting. What they usually need to hear:

1. **API connection**: the model behind the assistant (Claude Code / Codex)
   becomes an ATP model, so every reply is billed to their ATP credits. For
   people who want ATP to be where their models and spending are managed.
2. **MCP-style tools**: the assistant keeps the model it uses now and gains
   new abilities: making pictures, videos and speech through ATP. ATP has no
   MCP server; this is done with ATP's skills and the same API key, and in use
   it feels like MCP tools: they just ask for a picture or a video.

Both need one ATP API key. There is no MCP URL to look for.

- 1 = **path A, API connection**: steps 1 to 4.
- 2 = **path B, MCP-style tools**: steps 1, 2, 3d and 5.

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
| Model | an id from `GET /v1/models` | an id from `GET /v1/models` |

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
curl -s https://api.atptoken.ai/v1/models -H "Authorization: Bearer $ATP_API_KEY"
```

Use ids from this reply exactly; never guess a model id. A `200` proves the
key works; a `401` means it is wrong or revoked: go back to step 1. The list
shows the platform's models; a model must also be enabled for the key's
project, and a request to one that is not returns `403` (**Person:** they
enable it at https://atptoken.ai/console/workspaces).

Path A: pick a model the person asked for. If they did not say, pick a
coding model from the list (for Claude Code, a `claude-` model) and tell them
which. Path B: you do not change your own model. Image, video and speech
models, with prices, are listed at https://atptoken.ai/models/ and in
https://atptoken.ai/docs/media.md.

## 3. Find out which app you are, then configure it

Path B goes straight to **3d**. For path A:

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

## 4. Check it works

Path B: step 2 already proved the key works, and it cost nothing. Do step 5,
then tell the person they can now ask you for pictures, videos and speech
through ATP, each paid from the project's credits.

Path A: the first message in the restarted tool is the check. Then tell the person, in
their language, that their tool now runs on ATP Token, which model it uses, and
that each request appears in https://atptoken.ai/console/logs and is paid from
the project's credits.

If a request fails, read the status: `401` wrong key, `402` the project is out
of credits (**Person:** top up at https://atptoken.ai/console/billing), `403`
the model is not enabled for this project. More in
https://atptoken.ai/docs/errors.md.

## 5. Install the ATP skills (path B; optional for path A)

They teach you ATP's API, in this session and later ones: model listing,
image, video and audio tasks, errors. Path B needs them to make media. Ask the
person first, then run:

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
