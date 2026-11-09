# Add the ATP MCP server

> Source: https://atptoken.ai/docs/mcp/

Add `https://mcp.atptoken.ai/mcp` to Claude, ChatGPT, Cursor, Codex and other AI tools so they can look up and check ATP API calls. No key needed. Your tool keeps the model it uses now; the server only gives it ATP's API guide and checkers, so it writes correct requests the first time.

## Before you start

You need the URL, a name for the server, and, only for the live model list, your API key.

| Item | Value |
|---|---|
| URL | `https://mcp.atptoken.ai/mcp` (Streamable HTTP) |
| Name | `atptoken-api-docs` (any name works) |
| API key | Optional. Only `atptoken_list_models` uses it. Keep it in the `ATP_API_KEY` environment variable. |

The server has four tools:

| Tool | What it does | Key |
|---|---|---|
| `atptoken_docs` | The ATP API guide: endpoints, parameters, media tasks, errors | — |
| `atptoken_check_media_request` | Checks a video request body before you send it and spend credits | — |
| `atptoken_install` | Install commands for other AI tools | — |
| `atptoken_list_models` | The models your key's project can call right now | needed |

Adding the server costs nothing. Generating images, video or speech through the API is what uses credits, and that needs an `atp-` key from [the console](https://atptoken.ai/console/keys/).

## Configure

Find your tool below. Each block can be pasted as it is. After adding the server, start a new session or restart the tool: MCP tools load at start.

### Claude Code

```bash
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
```

`--scope user` makes it available in every folder; without it, the server exists only in the folder you ran the command in.

To use the live model list, add the key header. If you already added the server without it, remove it first:

```bash
claude mcp remove --scope user atptoken-api-docs
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp \
  --header "Authorization: Bearer $ATP_API_KEY"
```

### Codex

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

With the key, Codex reads it from the environment variable each time it starts:

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp --bearer-token-env-var ATP_API_KEY
```

### Claude app (web and desktop)

1. Open **Customize → Connectors**.
2. Click **+ Add**, then **Add custom connector**.
3. Name it `ATP Token`, paste `https://mcp.atptoken.ai/mcp` as the URL, and click **Continue**.
4. Under **Authentication**, choose **No sign in**. To use the live model list, add a request header `Authorization` with the value `Bearer atp-…`.
5. Click **Add**, then turn the connector on in a new chat.

On Team and Enterprise plans, an owner adds it under **Organization settings → Connectors**, and members then click **Connect**. The desktop app's `claude_desktop_config.json` does not accept a URL; use Connectors instead.

### ChatGPT

1. In **Settings → Apps & Connectors → Advanced settings**, turn on **Developer mode**.
2. Back in **Apps & Connectors**, click **Create**.
3. Name it `ATP Token`, paste `https://mcp.atptoken.ai/mcp` as the URL, and choose **No authentication**.
4. Turn it on in a new chat from the tools menu.

Menu names and which plans can add custom connectors change from time to time; if you do not see **Developer mode**, check OpenAI's help for your plan.

### Cursor

Add this to `~/.cursor/mcp.json` (every project) or `.cursor/mcp.json` (one project):

```json
{
  "mcpServers": {
    "atptoken-api-docs": {
      "url": "https://mcp.atptoken.ai/mcp",
      "headers": { "Authorization": "Bearer ${env:ATP_API_KEY}" }
    }
  }
}
```

Leave out `headers` if you do not need the live model list.

### Cline

Add this to `cline_mcp_settings.json` (MCP Servers → Configure). Set `type` explicitly; without it Cline uses the older SSE transport and fails to connect:

```json
{
  "mcpServers": {
    "atptoken-api-docs": {
      "type": "streamableHttp",
      "url": "https://mcp.atptoken.ai/mcp"
    }
  }
}
```

### Gemini CLI

```bash
gemini mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
```

### Other tools

Any tool that supports remote MCP servers takes the URL `https://mcp.atptoken.ai/mcp` with the Streamable HTTP transport. The setting is often called "remote", "HTTP" or "URL" server. For a tool that only runs local (stdio) servers, bridge it with `npx -y mcp-remote https://mcp.atptoken.ai/mcp` as the command.

Once the server is in one tool, you can also ask that tool to call `atptoken_install` and add it to another.

## Check that it works

In a new session, ask your tool:

```
Use the atptoken_docs tool to open the "start" page and summarize how to call ATP.
```

A summary of the ATP guide means the connection works. It costs nothing. If you added the key, also ask it to list your models with `atptoken_list_models`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| The tools do not appear | MCP tools load when a session starts | Start a new session or restart the tool |
| Claude Code finds it in one folder only | Added without `--scope user` | Remove it and add it again with `--scope user` |
| `already exists` when adding the key version | A server with the same name is already there | Remove it first, then add it again |
| `atptoken_list_models` says a key is needed | No `Authorization` header, or the variable is empty | Set `ATP_API_KEY` in the shell that starts the tool, then restart it |
| Cline cannot connect | `type` missing, so it tries SSE | Add `"type": "streamableHttp"` |
| Opening the URL in a browser shows an error | The URL answers MCP requests (POST), not page views | Nothing is wrong; add it in your tool |

## Next steps

- [Connect coding agents](https://atptoken.ai/docs/agents/) — Run Claude Code, Codex and other agents on ATP models with your project key.
- [Agent Skills](https://atptoken.ai/docs/agent-skills/) — The same guidance as local files, for tools without MCP.
- [Quickstart](https://atptoken.ai/docs/quickstart/) — Make your first API call yourself.
