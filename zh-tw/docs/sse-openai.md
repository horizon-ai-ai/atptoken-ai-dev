# Server-Sent Events

> Source: https://atptoken.ai/zh-tw/docs/sse-openai/

當你在 /v1/chat/completions 設定 `stream: true`，Gateway 會把上游 provider 回應以 OpenAI 格式的 SSE chunk 串流出來。最後一個 chunk 含 `usage` 物件；串流以 `data: [DONE]` 結束。
