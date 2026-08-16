# Media models (preview)

> Source: https://atptoken.ai/docs/media/

Beyond text, the catalog includes **image, video, audio (text-to-speech) and embedding** models. They share the same account, credits and project scoping as text models, but each modality bills on its own meter instead of input + output tokens. Current models and list prices are on the [pricing page](https://atptoken.ai/pricing/).

> **Preview status**
>
> Media generation is rolling out in preview. Models marked **Preview** on the pricing page are live in testing but their list prices are not yet published. If your team wants early access at scale, [tell us about your use case](https://atptoken.ai/enterprise-plan/).

### Video

Video models: **seedance-2-0** (standard), **seedance-2-0-mini** (lighter, lower cost) and **seedance-2-0-fast** (faster rendering). Per-model rates are on the [pricing page](https://atptoken.ai/pricing/).

Video generation bills on **video tokens**, computed from the pixels and seconds you render:

```
video_tokens = width × height × (input seconds + output seconds) × 24 ÷ 1024
cost = video_tokens × per-1M rate for the resolution tier
```

Per-second quick reference at list rates (16:9, no video input):

| Resolution | Approx. price / second |
| --- | --- |
| 480p (draft) | ~$0.07 |
| 720p · 16:9 | ~$0.15 |
| 720p · 1:1 | ~$0.085 |
| 1080p | ~$0.37 |

Worth knowing before you render:

- **Aspect ratio changes the price.** Cost follows actual width × height — a 1:1 clip at 720p costs ~44% less than 16:9 at the same tier.
- **Auto duration bills actual seconds.** With `duration: auto`, you are charged for the seconds the task actually renders, not the request.
- **Reference video switches tiers.** Adding input video moves the task to the with-input rate, and input seconds enter the formula.
- **4K is not yet available**; requests above 1080p are rejected before any task is created.
- **Failed tasks are not billed.**

For the current video model parameters and examples, see [Seedance 2.0](https://atptoken.ai/docs/seedance-2-0/).

### Image

Text-to-image generation runs synchronously — prompt in, image URL back. List pricing will be published at launch; the model appears on the pricing page as **Preview** until then.

### Audio (text-to-speech)

TTS bills **per character** of input text rather than per token. List pricing will be published at launch.

### Embeddings

Embedding models bill on **input tokens only** — there is no output meter. Rates are on the [pricing page](https://atptoken.ai/pricing/).
