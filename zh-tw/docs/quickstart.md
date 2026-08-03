# 快速開始

> Source: https://atptoken.ai/zh-tw/docs/quickstart/

建立 project API key、確認這把 key 可使用的模型，然後用 OpenAI、Anthropic 或 Gemini 任一 SDK 格式送出請求。

- [自己接 API](#建立-project-api-key)
  四個步驟手動設定，OpenAI、Anthropic、Gemini 三種格式都支援。
- [用 coding agent 接](https://atptoken.ai/zh-tw/docs/agents/)
  Claude Code、Codex、Cline 等工具的設定方式。

## 1. 建立 project API key

登入 Console，建立或選擇 organization、workspace 與 project，接著從該 project 建立 API key。這把 key 會繼承 project 的允許模型清單與 credit balance。key 以 `atp-` 開頭，完整密鑰只會顯示一次。

## 2. 把 SDK 指向 Gateway

Gateway 支援 OpenAI、Anthropic 與 Google GenAI SDK 的預設驗證 header，不需要另外包一層 library。下方 Authentication 章節列出三種可接受的 key 位置。

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

## 3. 查詢可用模型

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

請在 request body 使用回傳的 model ID。如果 project 沒有啟用該模型，Gateway 會在送到 provider 前回傳 403。

## 4. 送出請求

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
