# /v1/messages

> Source: https://atptoken.ai/docs/messages/

`POST /v1/messages`

Anthropic Messages requests are accepted and normalized by the Gateway.

## Request

The `anthropic-version` header is accepted and forwarded unchanged.

```curl
curl https://api.atptoken.ai/v1/messages \
  -H "Authorization: Bearer atp-..." \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model from GET /v1/models>",
    "max_tokens": 256,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
from anthropic import Anthropic

client = Anthropic(base_url="https://api.atptoken.ai", api_key="atp-...")
msg = client.messages.create(
    model="<model from GET /v1/models>",
    max_tokens=256,
    messages=[{"role": "user", "content": "hi"}],
)
print(msg.content[0].text)
```

```Node.js
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ baseURL: "https://api.atptoken.ai", apiKey: "atp-..." });
const msg = await client.messages.create({
  model: "<model from GET /v1/models>",
  max_tokens: 256,
  messages: [{ role: "user", content: "hi" }],
});
console.log(msg.content[0].text);
```

## Parameters

The top-level `system` field accepts a string or an array of text blocks (`cache_control` on a block is accepted).

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id from GET /v1/models. |
| max_tokens | integer · required | Max output tokens (Anthropic requires this). With extended thinking, the thinking budget counts against it — too low returns a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| messages | array · required | Conversation turns, each { role, content }. |
| system | string or array | System prompt, as a string or an array of text blocks. |
| temperature | number | Sampling temperature, 0–1. |
| stream | boolean | Stream as Anthropic SSE events. |

## Next steps

- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence you get with `stream: true`
- [Anthropic SDK](https://atptoken.ai/docs/sdk-anthropic/) — call this endpoint from the official SDK
- [Error codes](https://atptoken.ai/docs/errors/) — what to check first for each status code
