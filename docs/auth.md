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

## Signing in to the console

Issuing a key, topping up and reading the Console API all start the same way: a person signs in at [atptoken.ai](https://atptoken.ai). Two rules about that sign-in are worth knowing before you build anything around it.

### Sign-in asks you to prove you are human

Signing in requires a human-verification check, and a browser is the only thing that can answer it. A request without an answer is refused with `400` and `reason: "captcha_required"`; one whose answer does not check out is refused with `400` and `captcha_invalid`.

It is there because people were being locked out of their own accounts. Scripts guessed passwords account by account, and the only brake was a per-account attempt limit — which stopped the real holder from signing in and did nothing to the script, since it simply moved to the next account. The check stops that run at its first request. A failed check costs you nothing: your attempt counter moves only when a password is actually wrong.

The check runs on every sign-in. There is no threshold to cross first, and no exemption to apply for.

### Linking a sign-in provider closes the password path

You can attach an external sign-in provider to your account and use it instead of a password. Attaching the first one asks for the same human-verification check, and it changes the account: the account becomes passwordless and the stored password is deleted. The password you remember stops being a way in — not suspended, deleted.

Attaching a second provider later changes nothing further, because the password went with the first one.

Getting the password path back is an administrator's action: they put the account back into password mode, and you then set a new password through "Forgot password". Nothing you can do from your own account recovers the old one.

When you sign in with a password and have no provider attached, the console offers to attach one. Skipping is a full answer — your password keeps working — and the offer comes back the next time you sign in.

## Next steps

- [Managing API keys](https://atptoken.ai/docs/console-keys/) — create project keys and revoke them
- [Error codes](https://atptoken.ai/docs/errors/) — what a `401` means and what to check first
- [Quickstart](https://atptoken.ai/docs/quickstart/) — send your first request with a project key
