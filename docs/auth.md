# Where your API key goes

> Source: https://atptoken.ai/docs/auth/

The Gateway reads your project API key from any of the locations below. `Authorization: Bearer` and `x-api-key` both work on every endpoint, so the official OpenAI, Anthropic and Google GenAI SDKs work unchanged — only the base URL changes. The Gateway strips the key before forwarding the request.

## Get a key first

Keys are not issued by the API. Sign in at [atptoken.ai](https://atptoken.ai), then pick or create an organization → a workspace → a project, and create the key inside that project. A key belongs to one project: that project decides which models the key may call and whose balance it uses. See [Managing API keys](https://atptoken.ai/docs/console-keys/).

## Where the key goes

| Location | Used by |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK, curl |
| `x-api-key: atp-…` | Anthropic SDK (`api_key=`), curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK |
| `?key=atp-…` | Gemini REST clients. Logs scrub this query param — prefer a header when you can. |

## When authentication fails

A missing, disabled, expired or unknown key returns `401` with `token_revoked` — "API key has been revoked or does not exist". **Sending no key at all returns the same error**, so first check that the header actually went out, then suspect the key.

A `403` is a different problem: the key is fine, but the model is not on its project's allowed list. See [Error codes](https://atptoken.ai/docs/errors/).

## Next steps

- [Managing API keys](https://atptoken.ai/docs/console-keys/) — create project keys and revoke them
- [Error codes](https://atptoken.ai/docs/errors/) — what a `401` means and what to check first
- [Quickstart](https://atptoken.ai/docs/quickstart/) — send your first request with a project key
