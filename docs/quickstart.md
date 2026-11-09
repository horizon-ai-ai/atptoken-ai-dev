# Quickstart

> Source: https://atptoken.ai/docs/quickstart/

Call a model with a project API key through the SDK you already use, then find the request under "Request logs" in the Console. This page uses the OpenAI format; for the Anthropic and Gemini formats, see [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic/) and [Google GenAI SDK](https://atptoken.ai/docs/sdk-google/).

> **Before you start**
>
> - An ATP Token account: [sign up free](https://atptoken.ai/signup/)
> - At least USD 5 in credits (500 credits). Without credits, requests return `402`.
> - Python or Node.js installed, or just curl in a terminal.

- [Call the API yourself](#create-an-account-and-add-credits)
  Six steps, from adding credits to seeing your first request in the Console.
- [Use a coding agent](https://atptoken.ai/docs/agents/)
  Setup for Claude Code, Codex, Cline and other tools.

## 1. Create an account and add credits

Sign in to the [Console](https://atptoken.ai/console/). On your first sign-in you name your organization. Then open "Billing" and choose "Top up". The minimum is USD 5 (500 credits), and credits do not expire.
If you use a team organization, top-ups go to your personal wallet first; then go to "Resources" and allocate credits to the workspace that will use them. See [Top-ups and wallets](https://atptoken.ai/docs/topup/).

## 2. Create an API key

Open "API Keys" in the Console and choose "Create API key". The wizard lets you pick an existing workspace and project, or create them if your role allows it; then it sets the models the project can call and creates the key. **Select at least one model** — this key can call only those models.
One key is bound to one project: that project decides which models the key can call and whose credits pay. The key starts with `atp-`, and its full value is shown only once. Copy it right away.

## 3. Install the SDK and set your key

```curl
export ATP_API_KEY="atp-your-key"
```

```Python
pip install openai
export ATP_API_KEY="atp-your-key"
```

```Node.js
npm install openai
export ATP_API_KEY="atp-your-key"
```

The Gateway base URL is `https://api.atptoken.ai/v1` (OpenAI format). For the headers that can carry your key, see [Authentication](https://atptoken.ai/docs/auth/).

## 4. List the models you can call in OpenAI format

```curl
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
for m in client.models.list().data:
    print(m.id)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const models = await client.models.list();
for (const m of models.data) console.log(m.id);
```

`GET /v1/models` is OpenAI's list endpoint, so it lists only the chat models served on `/v1/chat/completions` and `/v1/responses` — exactly what the next step can call. Pick a model ID from it.

It is not your project's full list: most `claude-*` models are called on `/v1/messages`, Gemini models on `/v1beta/models`, and media and embedding models are not on it either. For everything the project allows, call `GET /v1/project/models` with the same key. If both lists are empty, the project has no models enabled yet: open "Resources" in the Console and add models to the project.

## 5. Send your first request

Replace `MODEL_ID` with the model ID you picked in the previous step. Always send `stream` explicitly: on `/v1/chat/completions` it defaults to `true`, the opposite of OpenAI's own API, so leave it out and you get SSE instead of JSON.

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
r = client.chat.completions.create(model="MODEL_ID", stream=False, messages=[{"role": "user", "content": "hi"}])
print(r.choices[0].message.content)
print(r.usage)
```

```Node.js
const r = await client.chat.completions.create({ model: "MODEL_ID", stream: false, messages: [{ role: "user", content: "hi" }] });
console.log(r.choices[0].message.content, r.usage);
```

A successful call returns an OpenAI-format response: `choices[0].message.content` is the model's reply, and `usage` holds this call's input/output tokens.

```json
{
  "object": "chat.completion",
  "model": "MODEL_ID",
  "choices": [
    {
      "message": { "role": "assistant", "content": "Hi! How can I help?" },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 9,
    "total_tokens": 17
  }
}
```

| Response | What it means | What to do |
|---|---|---|
| `401 token_revoked` | The key is missing, mistyped, or disabled. Sending no key at all also returns this | First check that the header was actually sent and `ATP_API_KEY` is set and starts with `atp-`; if needed, create a new key under "API Keys" |
| `402` | Credits are used up | Add credits under "Billing"; for a team organization, also allocate credits under "Resources" |
| `403` | The model is not enabled for the project. Rejected at create, not billed | Use a model ID from the list in step 4, or add the model to the project under "Resources" |
| `422` | The model is not served on this entrypoint; the message names the right one | Call the entrypoint the message names, with that SDK — see [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic/) or [Google GenAI SDK](https://atptoken.ai/docs/sdk-google/) |

For other status codes, see [Error codes](https://atptoken.ai/docs/errors/).

## 6. Find the request in the Console

Open "Overview" in the Console and choose "View all" under "Recent requests", or go straight to [Request logs](https://atptoken.ai/console/logs/). Your request is at the top, with its model, status and input/output tokens; the credits it used count toward "Usage".

## Next steps

- [Authentication](https://atptoken.ai/docs/auth/) — Where your key can go, plus Gemini SDK setup.
- [How credits work](https://atptoken.ai/docs/credits/) — How tokens convert to credits.
- [Error codes](https://atptoken.ai/docs/errors/) — What to check first for each status code.
