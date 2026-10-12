# Three accepted key locations

> Source: https://atptoken.ai/docs/auth/

The Gateway accepts a project API key in any of the locations below. Use whichever your SDK sends by default. The Gateway strips the key before forwarding to the provider.

## Where the key goes

| Location | Used by |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK, Anthropic SDK, curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK (recommended for Gemini) |
| `?key=atp-…` | Gemini REST clients. Logs scrub this query param — prefer the header form when possible. |

## When authentication fails

If none of the three are present → `401`. If the key is disabled or expired → `401`.

## Next steps

- [Managing API keys](https://atptoken.ai/docs/console-keys/) — create project keys and revoke them
- [Error codes](https://atptoken.ai/docs/errors/) — what a `401` means and what to check first
- [Quickstart](https://atptoken.ai/docs/quickstart/) — send your first request with a project key
