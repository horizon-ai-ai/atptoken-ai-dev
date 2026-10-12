# Pricing

> Source: https://atptoken.ai/docs/pricing-model/

Billing is usage-based, measured on **input + output tokens**. Each model has its own rate; the exact per-model economics are resolved by the gateway's pricing tables at request time, not by a static table on this page. Which models a key may call is scoped by its project.

## Monthly fee and access tiers

There is no monthly fee. See the [pricing page](https://atptoken.ai/pricing/) for the model lineup and access tiers.

## Estimate a request

Estimate a video or text request from the list rates:

**Billing calculator**

Video: video tokens ≈ width × height × seconds × 24 ÷ 1024; cost ≈ video tokens × the resolution tier's USD per 1M video tokens. Pixels assume 16:9. Output can run slightly longer than requested (e.g. 5.04 s for a 5 s request), so results are approximate.

| Model | Resolution | Video tokens (5 s) | USD / 1M | USD (5 s) |
| --- | --- | --- | --- | --- |
| `seedance-2-0` | 480p | ≈ 48,038 | 7 | ≈ 0.3363 |
| `seedance-2-0` | 720p | ≈ 108,000 | 7 | ≈ 0.7560 |
| `seedance-2-0` | 1080p | ≈ 243,000 | 7.7 | ≈ 1.8711 |
| `seedance-2-0` | 4k | ≈ 972,000 | 4 | ≈ 3.8880 |
| `seedance-2-0-fast` | 480p | ≈ 48,038 | 5.6 | ≈ 0.2690 |
| `seedance-2-0-fast` | 720p | ≈ 108,000 | 5.6 | ≈ 0.6048 |
| `kling-v3-standard` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-v3-standard-i2v` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-v3-pro` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-v3-pro-i2v` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-o3-standard` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-o3-standard-i2v` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-o3-standard-reference` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-o3-standard-reference-7` | 720P | ≈ 108,000 | 3.888889 | ≈ 0.4200 |
| `kling-o3-pro` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-o3-pro-i2v` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-o3-pro-reference` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-o3-pro-reference-7` | 1080P | ≈ 243,000 | 2.304527 | ≈ 0.5600 |
| `kling-o3-standard-v2v` | 720P | ≈ 108,000 | 5.833333 | ≈ 0.6300 |
| `kling-o3-standard-video-edit` | 720P | ≈ 108,000 | 5.833333 | ≈ 0.6300 |
| `kling-o3-pro-v2v` | 1080P | ≈ 243,000 | 3.45679 | ≈ 0.8400 |
| `kling-o3-pro-video-edit` | 1080P | ≈ 243,000 | 3.45679 | ≈ 0.8400 |
| `wan-2-7-t2v` | 720P | ≈ 108,000 | 4.62963 | ≈ 0.5000 |
| `wan-2-7-t2v` | 1080P | ≈ 243,000 | 3.08642 | ≈ 0.7500 |
| `wan-2-7-i2v` | 720P | ≈ 108,000 | 4.62963 | ≈ 0.5000 |
| `wan-2-7-i2v` | 1080P | ≈ 243,000 | 3.08642 | ≈ 0.7500 |
| `wan-3-0-video` | 720P | ≈ 108,000 | 4.62963 | ≈ 0.5000 |
| `wan-3-0-video` | 1080P | ≈ 243,000 | 4.11523 | ≈ 1.0000 |
| `wan-3-0-video-pro` | 1080P | ≈ 243,000 | 3.7037 | ≈ 0.9000 |
| `wan-3-0-video-pro` | 2K | ≈ 432,000 | 2.31481 | ≈ 1.0000 |
| `happyhorse-1.1-t2v` | 720P | ≈ 108,000 | 6.481481 | ≈ 0.7000 |
| `happyhorse-1.1-t2v` | 1080P | ≈ 243,000 | 3.703704 | ≈ 0.9000 |
| `happyhorse-1.1-i2v` | 720P | ≈ 108,000 | 6.481481 | ≈ 0.7000 |
| `happyhorse-1.1-i2v` | 1080P | ≈ 243,000 | 3.703704 | ≈ 0.9000 |
| `happyhorse-1.1-r2v` | 720P | ≈ 108,000 | 6.481481 | ≈ 0.7000 |
| `happyhorse-1.1-r2v` | 1080P | ≈ 243,000 | 3.703704 | ≈ 0.9000 |
| `happyhorse-1.0-video-edit` | 720P | ≈ 108,000 | 6.481481 | ≈ 0.7000 |
| `happyhorse-1.0-video-edit` | 1080P | ≈ 243,000 | 4.938272 | ≈ 1.2000 |

Text: cost = input tokens × input rate + cache-read tokens × cache-read rate + output tokens × output rate (USD per 1M tokens).
1 credit = USD 0.01.

| Model | Input (USD / 1M) | Cache read (USD / 1M) | Output (USD / 1M) |
| --- | --- | --- | --- |
| `gpt-5.4-pro` | 30 | — | 180 |
| `claude-fable-5` | 10 | 1 | 50 |
| `claude-opus-5` | 5 | 0.5 | 25 |
| `gpt-5.6-sol` | 5 | — | 30 |
| `gpt-5.5` | 5 | — | 30 |
| `claude-opus-4-8` | 5 | 0.5 | 25 |
| `claude-opus-4-7` | 5 | 0.5 | 25 |
| `claude-sonnet-5` | 3 | 0.3 | 15 |
| `gpt-5.6-terra` | 2.5 | — | 15 |
| `claude-sonnet-4-6` | 3 | 0.3 | 15 |
| `gpt-5.4` | 2.5 | — | 15 |
| `gemini-3-1-pro-preview` | 2 | — | 12 |
| `gemini-3-5-flash` | 1.5 | — | 9 |
| `qwen-3-6-max` | 1.29 | — | 7.71 |
| `qwen-3-8-max` | 2 | 0.25 | 6 |
| `qwen-3-7-max` | 2.5 | 0.5 | 7.5 |
| `qwen-3-7-plus` (tier ≤256K) | 0.4 | 0.08 | 1.6 |
| `qwen-3-7-plus` (tier >256K) | 1.2 | 0.24 | 4.8 |
| `qwen-3-7-flash` (tier ≤32K) | 0.03 | 0.006 | 0.13 |
| `qwen-3-7-flash` (tier 32K–256K) | 0.1 | 0.02 | 0.4 |
| `qwen-3-7-flash` (tier >256K) | 0.2 | 0.04 | 0.8 |
| `qwen-3-6-plus` (tier ≤256K) | 0.276 | — | 1.651 |
| `qwen-3-6-plus` (tier >256K) | 1.101 | — | 6.602 |
| `qwen-3-6-flash` (tier ≤256K) | 0.165 | — | 0.99 |
| `qwen-3-6-flash` (tier >256K) | 0.66 | — | 3.961 |
| `qwen-plus-character` | 0.115 | 0.023 | 0.287 |
| `gpt-5.6-luna` | 1 | — | 6 |
| `claude-haiku-4-5` | 1 | 0.1 | 5 |
| `glm-5-1` | 1.54 | — | 4.84 |
| `kimi-k2.6` | 0.95 | — | 4 |
| `glm-5-2` | 1.4 | 0.28 | 4.4 |
| `kimi-k2.7-code` | 0.95 | 0.19 | 4 |
| `kimi-k3` | 3 | 0.3 | 15 |
| `deepseek-v4-pro` | 2.4 | 0.2 | 4.8 |
| `glm-5` | 1 | — | 3.2 |
| `gemini-3-flash-preview` | 0.5 | — | 3 |
| `deepseek-v4-flash` | 0.2 | 0.04 | 0.4 |
| `deepseek-v3-2` | 0.57 | 0.114 | 1.71 |
| `gemini-3-5-flash-lite` | 0.3 | 0.03 | 2.5 |
| `gemini-3-6-flash` | 1.5 | — | 7.5 |

## Next steps

- [How credits work](https://atptoken.ai/docs/credits/) — What one credit is worth and how credits flow to a project.
- [Top up & wallet](https://atptoken.ai/docs/topup/) — Buy credits and see the top-up packages.
- [Tracking spend](https://atptoken.ai/docs/spend/) — See where credits go by model, key, and level.
