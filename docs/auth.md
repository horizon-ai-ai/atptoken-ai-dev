# Three accepted key locations

> Source: https://atptoken.ai/docs/auth/

The Gateway accepts a project API key in any of the locations below. Use whichever your SDK sends by default. The Gateway strips the key before forwarding to the provider.

| Location | Used by |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK, Anthropic SDK, curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK (recommended for Gemini) |
| `?key=atp-…` | Gemini REST clients. Logs scrub this query param — prefer the header form when possible. |

If none of the three are present → `401`. If the key is disabled or expired → `401`.
