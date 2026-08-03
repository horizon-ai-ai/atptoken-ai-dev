# Migrate from OpenAI

> Source: https://atptoken.ai/docs/cb-migrate-openai/

Moving an existing OpenAI integration to ATP is usually a two-line change: swap the base URL to the Gateway and the API key to a project key. Your request and response shapes stay exactly the same.

## 1. Get a project key

Create a project API key in the console. It starts with `atp-` and inherits its project's allowed models and credits. See [Managing API keys](https://atptoken.ai/docs/console-keys/).

## 2. Swap the base URL and key

Point the OpenAI SDK at the Gateway and use the `atp-` key. Everything else — messages, tools, streaming — is unchanged.

```
from openai import OpenAI

# Before: client = OpenAI(api_key="sk-...")
client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")

r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## 3. Map your model ids

Model ids on ATP come from [GET /v1/models](https://atptoken.ai/docs/models/), not OpenAI's catalog. List them and update the `model` field to an id enabled for your project — a model that isn't enabled returns `403`.

## 4. Test and confirm

Send a request and check the console: it appears in Request logs with input / output tokens, and the credits it used show on the Usage page. See [Usage & logs](https://atptoken.ai/docs/monitoring/).

> **Same shapes, one bill**
>
> Because the OpenAI wire format passes through unchanged, response parsing in your app doesn't change. Usage across every model is now metered in credits. See [How credits work](https://atptoken.ai/docs/credits/).
