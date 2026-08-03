# Server-Sent Events

> Source: https://atptoken.ai/zh-cn/docs/sse-openai/

当你在 /v1/chat/completions 设定 `stream: true`，Gateway 会把上游 provider 回应以 OpenAI 格式的 SSE chunk 串流出来。最后一个 chunk 含 `usage` 物件；串流以 `data: [DONE]` 结束。
