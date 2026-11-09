# Media models (preview)

> Source: https://atptoken.ai/docs/media/

Beyond text, the catalog includes **image, video, audio (text-to-speech) and embedding** models. They share the same account, credits and project scoping as text models, but each modality bills on its own meter instead of input + output tokens. Models and list prices are on the [pricing page](https://atptoken.ai/pricing/).

> **Preview status**
>
> Media generation is rolling out in preview. Models marked **Preview** on the pricing page are live in testing but their list prices are not yet published. If your team wants early access at scale, [tell us about your use case](https://atptoken.ai/enterprise-plan/).

## Check which models you can use

Call `GET https://api.atptoken.ai/v1/project/models` with your key. It is the project's complete list: text, image, video, audio and embedding models together. `GET /v1/models` lists only OpenAI-dialect chat models; media models are not on it. A model missing from a list is not necessarily unusable; without permission, create returns `403` and nothing is billed.

## Image, video and audio are all asynchronous

None of the three media surfaces has a synchronous variant. The flow is the same: create a task → poll until terminal → download before the signed URL expires. **Only the result field differs:**

| Modality | Endpoint | Task id | Result |
| --- | --- | --- | --- |
| Video | `/omni/media/v1/contents/generations/tasks` | `cgt_…` | `content.video_url` |
| Image | `/omni/media/v1/images/generations/tasks` | `img_…` | `data[].url` (array) |
| Audio | `/omni/media/v1/audio/generations/tasks` | `aud_…` | `audio_url` (top level) |

- Statuses are `queued`, `running`, `succeeded`, `failed`, `expired` and `cancelled`; the last four are terminal.
- **Signed URLs expire after 24 hours.** After that the status is still `succeeded`, but the URL is `null` and `expired: true` appears.
- There are no webhooks; `callback_url` is never used, so you must poll.
- Use a separate `Idempotency-Key` per media surface; reusing one across two surfaces returns `409`.

## Video

Video models include the Seedance family (`seedance-2-0`, `-fast`, `-mini`, `seedance-2-5`) plus the Kling, Wan, HappyHorse and MiniMax families. Request shapes differ by family; see [Video generation](https://atptoken.ai/docs/media-video/) for the full list and how to call each. Per-model rates are on the [pricing page](https://atptoken.ai/pricing/).

Video generation bills on **video tokens**, settled on actual usage once the task finishes:

```
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

`in_dur` is the input video length in seconds, `out_dur` the output length, and `W × H` the output size. When a model reports its own usage, that figure is used.

Per-second quick reference at list rates (16:9, no video input):

| Resolution | Approx. price / second |
| --- | --- |
| 480p (draft) | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

Worth knowing before you render:

- **Aspect ratio changes the price.** Cost follows actual width × height — a 1:1 clip at 720p costs ~44% less than 16:9 at the same tier.
- **When the model picks the duration, you pay for the seconds it actually renders**, not the number in the request.
- **Reference video switches tiers.** Adding input video moves the task to the with-input rate, and input seconds enter the formula.
- **Available resolutions depend on the model**; see each family in [Video generation](https://atptoken.ai/docs/media-video/), and the [pricing page](https://atptoken.ai/pricing/) for rates.
- **An exhausted balance returns `402` at create.** If the balance is short at settlement it goes negative and the next request is blocked.
- **Failed tasks are not billed.**

For Seedance parameters and examples, see [Seedance](https://atptoken.ai/docs/seedance-2-0/).

## Image

Text-to-image is an asynchronous task too: create it, poll, and read the result from `data[].url`. List pricing will be published at launch; the model appears on the pricing page as **Preview** until then.

## Audio (text-to-speech)

TTS is an asynchronous task; the result is in `audio_url`. It bills **per character** of input text rather than per token. List pricing will be published at launch.

## Embeddings

Embeddings are a single synchronous call (`POST /v1/embeddings`) and bill on **input tokens only** — there is no output meter. Rates are on the [pricing page](https://atptoken.ai/pricing/).

## Next steps

- [Seedance](https://atptoken.ai/docs/seedance-2-0/) — Seedance parameters, examples and limits.
- [Video generation](https://atptoken.ai/docs/media-video/) — Create a video task and poll for the result.
- [Image generation](https://atptoken.ai/docs/media-image/) — Generate images from a prompt.
- [Speech generation (TTS)](https://atptoken.ai/docs/media-audio/) — Turn text into speech.
