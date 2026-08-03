# 快速开始

> Source: https://atptoken.ai/zh-cn/docs/quickstart/

建立 project API key、确认这把 key 可使用的模型，然后用 OpenAI、Anthropic 或 Gemini 任一 SDK 格式送出请求。

- [自己接 API](#建立-project-api-key)
  四个步骤手动接入，OpenAI、Anthropic、Gemini 三种格式都支持。
- [用 coding agent 接](https://atptoken.ai/zh-cn/docs/agents/)
  Claude Code、Codex、Cline 等工具的配置方式。

## 1. 建立 project API key

登录 Console，建立或选择 organization、workspace 与 project，接着从该 project 建立 API key。这把 key 会继承 project 的允许模型清单与 credit balance。key 以 `atp-` 开头，完整密钥只会显示一次。

## 2. 把 SDK 指向 Gateway

Gateway 支援 OpenAI、Anthropic 与 Google GenAI SDK 的预设验证 header，不需要另外包一层 library。下方 Authentication 章节列出三种可接受的 key 位置。

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

## 3. 查询可用模型

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

请在 request body 使用回传的 model ID。如果 project 没有启用该模型，Gateway 会在送到 provider 前回传 403。

## 4. 送出请求

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
