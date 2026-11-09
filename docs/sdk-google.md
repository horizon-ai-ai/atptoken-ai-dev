# Google GenAI SDK

> Source: https://atptoken.ai/docs/sdk-google/

Use the Google GenAI SDK (`google-genai`: `from google import genai` in Python, `@google/genai` in Node) unchanged. The older `google-generativeai` package is deprecated. Set the base URL to the Gateway with `apiVersion` `v1beta`, authenticate with `x-goog-api-key` (the SDK default), and call a model served on this entrypoint.

## Configure the client

| Setting | Value |
|---|---|
| Base URL | `https://api.atptoken.ai` |
| API version | `v1beta` |
| Auth | `x-goog-api-key: atp-…` (SDK default) |
| Model | any id from GET /v1beta/models |

`GET /v1beta/models` is Gemini's own list endpoint and shows only the models callable on `:generateContent` / `:streamGenerateContent`. `GET /v1/models` is OpenAI's list, not this one. For every model your project allows, on any entrypoint, call `GET /v1/project/models`. A model that isn't served here returns `422` naming the right entrypoint.

```
from google import genai

client = genai.Client(
    api_key="atp-...",
    http_options={"base_url": "https://api.atptoken.ai", "api_version": "v1beta"},
)
r = client.models.generate_content(
    model="<model from GET /v1beta/models>",
    contents="hi",
)
print(r.text)
```

## Supported routes

The `generateContent` and `streamGenerateContent` routes work under both `/v1` and `/v1beta`. The model goes in the URL, not the body. There is no `stream` field: to stream, call `:streamGenerateContent`. Full endpoint reference: [/v1/models/{model}:generateContent](https://atptoken.ai/docs/gemini/).

> **Keep apiVersion on v1beta**
>
> A client pinned to `v1` fetches its model list from `/v1/models`, which is OpenAI's endpoint and answers in OpenAI's shape. The SDK then parses zero models — without any error. Chat calls are not affected; only the list is.

Files uploaded through the Gemini upload protocol (`/upload/v1beta/files`) can't be used by models on this entrypoint — referencing one returns an error. Send images and audio inline (`inlineData`) instead.

## Next steps

- [/v1/models/{model}:generateContent](https://atptoken.ai/docs/gemini/) — Parameters and response shape for this endpoint.
- [List available models](https://atptoken.ai/docs/models/) — Get the model IDs to pass as `model`.
- [Authentication](https://atptoken.ai/docs/auth/) — Where your key can go, including `x-goog-api-key`.
