# Server-Sent Events

> Source: https://atptoken.ai/docs/sse-openai/

When you set `stream: true` on /v1/chat/completions, the Gateway streams the upstream provider response as OpenAI-format SSE chunks.

## Request

Add `"stream": true`. With curl, pass `-N` so the output isn't buffered.

```curl
curl -N https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}],
    "stream": true
  }'
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
stream = client.chat.completions.create(
    model="MODEL_ID",
    messages=[{"role": "user", "content": "hi"}],
    stream=True,
)
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const stream = await client.chat.completions.create({
  model: "MODEL_ID",
  messages: [{ role: "user", content: "hi" }],
  stream: true,
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? "");
}
```

## Usage and the end of the stream

The final chunk contains the `usage` object; the stream ends with `data: [DONE]`.

## Next steps

- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — request fields for the endpoint that produces this stream
- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence on /v1/messages
- [OpenAI SDK](https://atptoken.ai/docs/sdk-openai/) — stream with the official SDK
