# /v1/messages

> Source: https://atptoken.ai/docs/messages/

`POST /v1/messages`

Anthropic Messages requests are accepted and normalized by the Gateway. The top-level `system` field must be a **string**. The array form used by Anthropic's cache_control feature is not yet supported — sending an array returns 400 `invalid_request_error`. The `anthropic-version` header is accepted and forwarded unchanged.

| Field | Type | Description |
|---|---|---|
| model | string · required | A model id from GET /v1/models. |
| max_tokens | integer · required | Max output tokens (Anthropic requires this). With extended thinking, the thinking budget counts against it — too low returns a `200` with empty content (see [Errors](https://atptoken.ai/docs/errors/)). |
| messages | array · required | Conversation turns, each { role, content }. |
| system | string | System prompt. Must be a string, not an array. |
| temperature | number | Sampling temperature, 0–1. |
| stream | boolean | Stream as Anthropic SSE events. |

#### Request

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
