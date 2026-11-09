# Platforms and workflow tools

> Source: https://atptoken.ai/docs/platforms/

Tools where you assemble AI through an interface instead of writing code — app builders, workflow automation — talk to the Gateway the same way an SDK does. Point the tool's OpenAI-compatible provider at the Gateway base URL and your project's OpenAI-format chat models become available inside it, on one key and one bill.

> **This page is also plain Markdown**
>
> Add `.md` to any docs URL to read the page as plain text: `https://atptoken.ai/docs/platforms.md`. Useful when you want to hand the whole page to an assistant.

## Before you start

Three values, the same everywhere:

- **Base URL** — `https://api.atptoken.ai/v1`. Include `/v1`, do not append `/chat/completions`.
- **API Key** — the `atp-…` project key.
- **Model** — an id from `GET /v1/models`.

`GET /v1/models` is OpenAI's list endpoint, so it lists only the chat models served on `/v1/chat/completions` and `/v1/responses` — exactly what an OpenAI-compatible provider can call. Your project may allow more: most `claude-*` models (on `/v1/messages`), Gemini-entrypoint models, and media and embedding models are not on it. `GET /v1/project/models` is the complete list.

Where the tools differ is whether they can read your model list for you:

| Tool | Where the settings live | Model list |
|---|---|---|
| Dify | Settings → Model Providers | added one at a time, by hand |
| n8n | the OpenAI credential's Base URL field | read from `GET /v1/models` (OpenAI-format chat models only) |

If you are wiring up a coding agent instead — Claude Code, Codex, Cline — see [Coding agents](https://atptoken.ai/docs/agents/).

## Connect Dify

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

## Connect n8n

n8n uses its built-in **OpenAI** credential. Create one, then under **Add option** set **Base URL** to `https://api.atptoken.ai/v1` and paste the `atp-…` key into **API Key**.

The model dropdown then reads `GET /v1/models` through that base URL, so your project's OpenAI-format chat models appear without any manual list. Models on other entrypoints — most `claude-*`, Gemini-entrypoint, media and embedding models — will not appear there.

To use it, add an **OpenAI Chat Model** sub-node to an **AI Agent** or **Basic LLM Chain** node and select the credential.

> **Use the AI Agent node, not the OpenAI node's Message a model**
>
> The OpenAI node's own `Message a model` action has an open bug with custom base URLs: the credential test passes but the request returns `404` at runtime. `AI Agent` plus an `OpenAI Chat Model` sub-node is the path that works.

Two more notes. The Base URL field lives on the credential, not on the node — it was hidden from the node in a later version, which is why it can look missing. And n8n's own docs do not list the field; it exists in the credential UI under **Add option**.

The credential behaves the same on n8n Cloud and self-hosted.

## Troubleshooting

- **`401 token_revoked`** — the key is missing, wrong, or revoked. Sending no key at all also returns this, so check the key field first.
- **`403`** — the model is not enabled for the key's project. Open the project's Resources in the Console and enable it. Rejected requests are not billed.
- **`422`** — the model is served on a different entrypoint (for example `/v1/messages`), so an OpenAI-compatible provider can't call it; the message names the right entrypoint.
- **`404`** — `/v1` is in the wrong place, or the tool appended `/chat/completions` to a base URL that already ended in it.
- **The model picker is empty** — Dify never lists models for you; add each one by hand. In n8n, the dropdown is populated from `GET /v1/models`, so an empty list means either the key or base URL is wrong, or the project has no OpenAI-format chat models enabled — compare with `GET /v1/project/models`.
- **Tools are never called** — in Dify, `Function Call Type` is still `no_call`.

## Next steps

- [Coding agents](https://atptoken.ai/docs/agents/) — Claude Code, Codex, and other terminal agents
- [Managing API keys](https://atptoken.ai/docs/console-keys/) — scope a key to one project before wiring it into a shared tool
- [How credits work](https://atptoken.ai/docs/credits/) — how usage from these tools is metered
