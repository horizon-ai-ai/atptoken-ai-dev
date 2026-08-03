# Quickstart

> Source: https://atptoken.ai/docs/quickstart/

Create a project API key, list the models that key can use, then send a request through the Gateway with any of three SDK formats.

- [Set it up yourself](#create-a-project-api-key)
  Four manual steps, using the OpenAI, Anthropic, or Gemini SDK.
- [Let a coding agent set it up](https://atptoken.ai/docs/agents/)
  Configuration for Claude Code, Codex, Cline, and similar tools.

## 1. Create a project API key

Sign in to the console, create or choose an organization, workspace, and project, then issue an API key from that project. The key inherits the project's allowed model list and credit balance. Keys start with `atp-` and are shown only once.

## 2. Point your SDK at the Gateway

The Gateway accepts the OpenAI, Anthropic, and Google GenAI SDKs using each SDK's default authentication header. See Authentication for the three accepted key locations.

```
# OpenAI SDK
from openai import OpenAI
client = OpenAI(
    base_url="https://api.atptoken.ai/v1",
    api_key="atp-..."
)

# Anthropic SDK
from anthropic import Anthropic
client = Anthropic(
    base_url="https://api.atptoken.ai",
    api_key="atp-..."
)

# Google GenAI SDK (Gemini) — uses x-goog-api-key by default
from google import genai
client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai"}
)
```

## 3. Discover allowed models

```curl
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer atp-..."
```

```Python
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
for m in client.models.list().data:
    print(m.id)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: "atp-..." });
const models = await client.models.list();
for (const m of models.data) console.log(m.id);
```

Use one of the returned model IDs in the request body. If a model is not enabled for the project, the Gateway returns 403 before reaching any provider.

## 4. Make a request

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer atp-..." \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model from GET /v1/models>",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")
r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: "atp-..." });
const r = await client.chat.completions.create({
  model: "<model from GET /v1/models>",
  messages: [{ role: "user", content: "hi" }],
});
console.log(r.choices[0].message.content);
```
