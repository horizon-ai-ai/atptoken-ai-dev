# Server-Sent Events

> Source: https://atptoken.ai/docs/sse-openai/

When you set `stream: true` on /v1/chat/completions, the Gateway streams the upstream provider response as OpenAI-format SSE chunks.

## Request

Add `"stream": true`. On `/v1/chat/completions` that is already the default, but send it explicitly anyway — `/v1/responses` defaults to `false`, and code moved between the two silently flips. With curl, pass `-N` so the output isn't buffered.

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

Chunks carry incremental `delta`s. The stream ends with `data: [DONE]` — wait for that line.

On every streaming request the Gateway sends `stream_options: {"include_usage": true}` upstream, even if you did not, because billing needs the token counts. So the stream always ends with one extra chunk that carries `usage`, at the end of the stream, before `data: [DONE]`. Sending `stream_options` yourself is harmless.

```
data: {"choices":[{"delta":{"content":"Hel"}}],…}
data: {"choices":[{"delta":{"content":"lo"}}],…}
data: [DONE]
```

## Errors before the stream starts

A request is checked before any chunk is sent: the model is not on your project's allowed list → `403`; your balance is used up → `402`; no capacity right now → `429`. These come back as a normal JSON error with an HTTP status and no stream, so check the status before you read chunks. See [Error codes](https://atptoken.ai/docs/errors/).

## /v1/responses streams differently

`/v1/responses` uses named events (`event: <type>` plus `data: {...}`), each with an increasing `sequence_number`.

- Text arrives in `response.output_text.delta` events.
- The stream ends with `response.completed`, which carries the full `output[]` and `usage`.
- If `max_output_tokens` cut the answer short, `response.completed` has `status: "incomplete"`.

## Next steps

- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — request fields for the endpoint that produces this stream
- [Anthropic SSE](https://atptoken.ai/docs/sse-anthropic/) — the event sequence on /v1/messages
- [OpenAI SDK](https://atptoken.ai/docs/sdk-openai/) — stream with the official SDK
