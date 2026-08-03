# Server-Sent Events

> Source: https://atptoken.ai/docs/sse-openai/

When you set `stream: true` on /v1/chat/completions, the Gateway streams the upstream provider response as OpenAI-format SSE chunks. The final chunk contains the `usage` object; the stream ends with `data: [DONE]`.
