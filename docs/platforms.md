# Platforms and workflow tools

> Source: https://atptoken.ai/docs/platforms/

Tools where you assemble AI through an interface instead of writing code — app builders, workflow automation — talk to the Gateway the same way an SDK does. Point the tool's OpenAI-compatible provider at the Gateway base URL and every model your project allows becomes available inside it, on one key and one bill.

> **This page is also plain Markdown**
>
> Add `.md` to any docs URL to read the page as plain text: `https://atptoken.ai/docs/platforms.md`. Useful when you want to hand the whole page to an assistant.

### Before you start

Three values, the same everywhere:

- **Base URL** — `https://api.atptoken.ai/v1`. Include `/v1`, do not append `/chat/completions`.
- **API Key** — the `atp-…` project key.
- **Model** — an id from `GET /v1/models`.

Where the tools differ is whether they can read your model list for you:

| Tool | Where the settings live | Model list |
|---|---|---|
| Dify | Settings → Model Providers | added one at a time, by hand |
| n8n | the OpenAI credential's Base URL field | read from `GET /v1/models` |

If you are wiring up a coding agent instead — Claude Code, Codex, Cline — see [Coding agents](https://atptoken.ai/docs/agents/).

### Dify

Install the **OpenAI-API-compatible** model provider from the marketplace, then use **Add Model** on its card. The fields that matter:

| Field | Value |
|---|---|
| Model Name | the model id from `GET /v1/models` |
| API Key | your `atp-…` key |
| API Base URL | `https://api.atptoken.ai/v1` |
| Model context size | the model's real context window |
| Upper bound for max tokens | the model's real output limit |
| Function Call Type | `Tool Call` if you want agents to use tools |
| Vision Support | `Support` for models that accept images |

Two defaults cause most of the confusion. **Model context size defaults to 4096**, which silently truncates anything longer, so set it per model. And **Function Call Type defaults to `no_call`**, which means Dify never sends a tools array — an agent built on that model will quietly refuse to call tools until you change it.

Dify does not read `GET /v1/models`, so each model is a separate Add Model entry. Call the endpoint first and work from the list it returns.

The setup is identical on Dify Cloud and self-hosted.

### n8n

n8n uses its built-in **OpenAI** credential. Create one, then under **Add option** set **Base URL** to `https://api.atptoken.ai/v1` and paste the `atp-…` key into **API Key**.

The model dropdown then reads `GET /v1/models` through that base URL, so your project's models appear without any manual list.

To use it, add an **OpenAI Chat Model** sub-node to an **AI Agent** or **Basic LLM Chain** node and select the credential.

> **Use the AI Agent node, not the OpenAI node's Message a model**
>
> The OpenAI node's own `Message a model` action has an open bug with custom base URLs: the credential test passes but the request returns `404` at runtime. `AI Agent` plus an `OpenAI Chat Model` sub-node is the path that works.

Two more notes. The Base URL field lives on the credential, not on the node — it was hidden from the node in a later version, which is why it can look missing. And n8n's own docs do not list the field; it exists in the credential UI under **Add option**.

The credential behaves the same on n8n Cloud and self-hosted.

### Troubleshooting

- **`403`** — the model is not enabled for the key's project. Open the project's Resources in the Console and enable it.
- **`404`** — `/v1` is in the wrong place, or the tool appended `/chat/completions` to a base URL that already ended in it.
- **The model picker is empty** — Dify never lists models for you; add each one by hand. In n8n, an empty list usually means the key or base URL is wrong, since the dropdown is populated from `GET /v1/models`.
- **Tools are never called** — in Dify, `Function Call Type` is still `no_call`.

## Next steps

- [Coding agents](https://atptoken.ai/docs/agents/) — Claude Code, Codex, and other terminal agents
- [Managing API keys](https://atptoken.ai/docs/console-keys/) — scope a key to one project before wiring it into a shared tool
- [How credits work](https://atptoken.ai/docs/credits/) — how usage from these tools is metered
