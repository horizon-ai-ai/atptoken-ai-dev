# Model catalog

> Source: https://atptoken.ai/docs/console-api-models/

`GET /api/video/models`

Five modality-scoped catalog endpoints, each returning the deduplicated, alphabetically sorted list of active `unifiedModelName` values on the platform:

| Endpoint | Modality |
|---|---|
| `GET /api/chat/models` | Chat / text |
| `GET /api/image/models` | Image generation |
| `GET /api/video/models` | Video generation |
| `GET /api/audio/models` | Speech (TTS) |
| `GET /api/embedding/models` | Embeddings |

> **Platform catalog vs. your project's models**
>
> These endpoints list what exists **on the platform**. What *your key* can call is the project's allowed-model list — query that on the data plane with `GET https://api.atptoken.ai/v1/models` using your `atp-` key (chat models only). Media models enabled for your project are shown in the console's key wizard.
