# Migrate from OpenAI

> Source: https://atptoken.ai/docs/cb-migrate-openai/

Moving an existing OpenAI integration to ATP is usually a two-line change: swap the base URL to the Gateway and the API key to a project key. Your request and response shapes stay exactly the same; the one default that differs is `stream` (step 2).

## 1. Get a project key

Create a project API key in the console. It starts with `atp-` and inherits its project's allowed models and credits. See [Managing API keys](https://atptoken.ai/docs/console-keys/).

## 2. Swap the base URL and key

Point the OpenAI SDK at the Gateway and use the `atp-` key. Messages and tools are unchanged. Streaming is the one catch: on `/v1/chat/completions` `stream` defaults to `true`, the opposite of OpenAI's API, so a call that leaves it out gets SSE instead of JSON. Send `stream` explicitly on every call (on `/v1/responses` it defaults to `false`).

```
from openai import OpenAI

# Before: client = OpenAI(api_key="sk-...")
client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")

r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    stream=False,
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## 3. Map your model ids

Model ids on ATP come from [GET /v1/models](https://atptoken.ai/docs/models/), not OpenAI's catalog. That list shows exactly the models the OpenAI SDK can call here; update the `model` field to one of them. A model that isn't enabled for your project returns `403` (not billed). If the model you want isn't on it, check `GET /v1/project/models`, the project's complete list: it may be served on another entrypoint, such as `/v1/messages` for most `claude-*` models, and calling it through the OpenAI SDK returns `422` naming that entrypoint.

## 4. Test and confirm

Send a request and check the console: it appears in Request logs with input / output tokens, and the credits it used show on the Usage page. See [Usage & logs](https://atptoken.ai/docs/monitoring/).

> **Same shapes, one bill**
>
> Because the OpenAI wire format passes through unchanged, response parsing in your app doesn't change — as long as `stream` is set explicitly. Usage across every model is now metered in credits. See [How credits work](https://atptoken.ai/docs/credits/).

## Next steps

- [OpenAI SDK](https://atptoken.ai/docs/sdk-openai/) — Full OpenAI SDK setup against the Gateway.
- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — The endpoint your migrated calls hit.
- [How credits work](https://atptoken.ai/docs/credits/) — How usage is metered in credits.
