# List available models

> Source: https://atptoken.ai/docs/models/

`GET /v1/models`

Lists every model available on the platform. Use it to get exact, current model IDs instead of copying names from a marketing page or provider dashboard.

> **This list is the menu, not your key's permissions**
>
> `GET /v1/models` is not scoped to your project. Which models a key may call is set by the project's allowed list and enforced at request time.

For why the platform catalog and project allowlists are separate controls, see [Model catalog vs access control](https://atptoken.ai/blog/model-catalog-vs-access-control/). A broader adoption path is in the [enterprise AI governance checklist](https://atptoken.ai/blog/ai-governance-checklist/).

#### Response

```
{
  "object": "list",
  "data": [
    { "id": "claude-sonnet-4-6", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" },
    { "id": "gpt-5.4", "object": "model", "created": 1700000000, "owned_by": "llm-gateway" }
  ]
}
```

### How model access works

_(Live model list: https://atptoken.ai/models/)_
