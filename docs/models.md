# List the models your key can use

> Source: https://atptoken.ai/docs/models/

`GET /v1/project/models`

`GET /v1/project/models` returns every model id your key's project may put in `body.model` — text, image, video, audio and embedding models in one list. It is the only complete list. Use it to get exact model ids instead of copying names from a marketing page or provider dashboard.

> **Availability is per project**
>
> A key belongs to one project, and that project decides which models the key may call. Another project in the same organization can allow different models. A model the project does not allow is refused at create time with `403`, and you are not billed.

## Full list: GET /v1/project/models

```curl
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

#### Response

```
{
  "data": [
    { "id": "gpt-5.5" },
    { "id": "claude-opus-4-8" },
    { "id": "seedance-2-0" },
    { "id": "text-embedding-3-small" }
  ]
}
```

- Each entry has only an `id`. The list says **what** you may call, not **where**: a chat model and an asynchronous video model sit side by side with nothing marking which is which.
- The project is the key's own. There is no path parameter, so one key cannot ask about another project.
- A project with no models returns `200` with `{"data": []}`.
- A listed model can still be unavailable right now. Permission to call a model and the model having somewhere to run are separate; the second case is refused with a routing error.

## Per-entry-point lists

Each chat entry point has its own list endpoint, and each one shows only the models that entry point accepts. A name missing from one of these lists is usually called on a different entry point.

| List | Shows | Shape |
|---|---|---|
| `GET /v1/models` | Models you can call on `/v1/chat/completions` and `/v1/responses` (OpenAI's list endpoint) | `{"object":"list","data":[{"id":…}]}` |
| `GET /v1beta/models` | Models you can call on `:generateContent` and `:streamGenerateContent` (Gemini) | `{"models":[{"name":"models/<id>",…}]}` |

What these two lists leave out:

- **Most `claude-*` models.** They are called on [/v1/messages](https://atptoken.ai/docs/messages/), and there is no Anthropic list endpoint. The Anthropic SDK's `models.list()` calls `/v1/models`, gets a compatible shape, and returns a shorter list without any error.
- **Media models** (video, image, audio). They are called on the `/omni/media/v1/...` task routes.
- **Embedding models.** They are called on `/v1/embeddings`.

A Gemini client pinned to `apiVersion: "v1"` asks for its list at `/v1/models`, gets the OpenAI shape, and parses zero models. Use `apiVersion: "v1beta"` — see [Gemini](https://atptoken.ai/docs/gemini/).

#### Response from GET /v1/models

```
{
  "object": "list",
  "data": [
    { "id": "gpt-5.5", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gemini-3-5-flash", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

## Not on a list does not mean unusable

You cannot tell from a model's name which entry point serves it — you look it up. Each model is served on one entry point. Call it on the wrong one and you get `422` with a message that names the right one:

```
this model is not served on this endpoint; it is available on /v1/messages
```

A model your project does not allow returns `403` at create time and is not billed. A project admin can enable models under Resources in the console.

## Catalog and project access

For why the platform catalog and project allowlists are separate controls, see [Model catalog vs access control](https://atptoken.ai/blog/model-catalog-vs-access-control/). A broader adoption path is in the [enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist/).

### How model access works

_(Live model list: https://atptoken.ai/models/)_

## Next steps

- [Workspaces & projects](https://atptoken.ai/docs/resources/) — Enable models for a project under Resources.
- [/v1/chat/completions](https://atptoken.ai/docs/chat/) — Send a request with a model id your project allows.
- [Model catalog](https://atptoken.ai/docs/console-api-models/) — Platform-wide model lists per modality from the Console API.
