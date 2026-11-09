# 影片生成

> Source: https://atptoken.ai/zh-cn/docs/media-video/

`POST /omni/media/v1/contents/generations/tasks`

影片生成是**非同步**的，没有同步版本：先建立任务（回 `202` 和 task id），轮询到终态，再下载签章 URL。base URL 与 `atp-` 密钥同图像。**请求的写法由模型决定**：同一个端点，不同模型收不同的栏位名，连大小写都可能不同，不要从一个模型推另一个。

**每一个影片任务**

1. 建立任务 — `POST …/contents/generations/tasks` — 回 `202` + `cgt_…`
2. 轮询到终态 — `GET …/contents/generations/tasks/{id}` — 四个终态都要跳出
3. 下载 `content.video_url` — 签章 URL — 24 小时内有效
   - succeeded
   - failed：原因在 `error`
   - 超过 24 小时：仍是 `succeeded`，但 `video_url` 为 `null`、`expired: true`

- **`succeeded` 不保证拿得到文件。** 超过 24 小时后状态仍是 `succeeded`，但 `content.video_url` 变成 `null`，另有 `expired: true`，只能重建任务。要留存就下载，不要把网址存进数据库当永久连结。
- **没有 webhook，必须轮询。** `callback_url` 会被接受，但不会被使用。
- 项目余额耗尽时，建立任务会回 `402 insufficient_quota`。

## 选模型

不确定就用 `seedance-2-0`。先看模型属于哪一系列：**请求外层由系列决定**。

| 系列 | 模型 | 文字与素材放哪 |
| --- | --- | --- |
| Seedance | `seedance-2-0`、`seedance-2-0-fast`、`seedance-2-0-mini`、`seedance-2-5` | `content[]`，见 [Seedance](https://atptoken.ai/zh-cn/docs/seedance-2-0/) |
| Kling | `kling-o3-*`、`kling-v3-*` | `content[]`；`-v2v`、`-video-edit` 例外，放 `input` |
| Wan 2.7、HappyHorse | `wan-2-7-t2v`、`wan-2-7-i2v`、`wan-2-7-video`、`happyhorse-1.1-t2v`／`-i2v`／`-r2v` | `content[]` |
| HappyHorse 影片编辑 | `happyhorse-1.0-video-edit` | 另一个端点，放 `input.media[]` |
| MiniMax | `minimax-h3` | `content[]` |
| Wan 3.0、spicy | `wan-3-0-video`、`wan-3-0-video-pro`、`wan-3-0-video-prime`、`wan-2-2-i2v-spicy`、`wan-2-7-i2v-spicy` | **扁平**：`prompt` 与素材放顶层 |

> **先确认这把密钥能用哪些模型**
>
> 完整清单是 `GET https://api.atptoken.ai/v1/project/models`：这个项目放行的每一个模型，不分文字、影像、影片。`GET /v1/models` 只列 OpenAI 格式的 chat 模型，影片模型不在里面。
>
> 清单上没有，不代表不能用；清单上有，也可能暂时没有上游在服务。没有权限时，建立任务会回 `403`，不收费。

**影片模型默认开放。** 管理者可以把特定模型设为受控，只有白名单账号能用。收到 `403 permission_denied` 不是密钥或余额问题：换一个模型，或请管理者授权。这个机制只作用于影片，跟 chat 的权限无关。

## 建立任务

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "seedance-2-0",
    "content": [
      { "type": "text", "text": "a red fox running through snow, cinematic" },
      { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
    ],
    "resolution": "720p",
    "ratio": "16:9",
    "duration": 5
  }'
# → 202 { "id": "cgt_..." }
```

必填只有 `model` 和 `content`（扁平系列是 `model` 和 `prompt`）。下表是端点接受的所有栏位；某个模型实际吃哪些，看该模型的段落。

| 栏位 | 型别 | 说明 |
|---|---|---|
| model | string · 必填 | 模型 ID |
| content | array · 必填 | 文字与素材区块（见下方） |
| resolution | string | `480p` `720p` `1080p` `4k` `768P` `2K`；部分模型只吃大写 |
| ratio | string | `16:9` `9:16` `4:3` `3:4` `1:1` `21:9` `adaptive`（别名 `aspect_ratio`，但有模型会拒绝这个别名） |
| duration | integer | 秒数（与 `frames` 择一） |
| frames | integer | 影格数（`duration` 的替代） |
| generate_audio | boolean | 生成音轨（别名 `add_audio`）；有模型的栏位叫 `audio` 或 `sound` |
| return_last_frame | boolean | 结果多带 `content.last_frame_url` |
| seed | integer | |
| camera_fixed | boolean | |
| watermark | boolean | 有模型会拒绝 |

`callback_url`、`service_tier`、`safety_identifier`、`execution_expires_after` 会被接受但丢掉，对输出没有影响。

**`content[]` 区块**：每个区块是 `{ "type": "text" | "image_url" | "video_url" | "audio_url", ... }`。

- 只有文字 → 文生影片；含图片 → 图生影片。
- 网址放在 `image_url: { "url": "…" }`（影片用 `video_url`、音讯用 `audio_url`）。区块**没有顶层 `url`**，放错会回 `400 missing content[1].image_url`。
- `role` 为 `first_frame`、`last_frame`、`reference_image`、`reference_video`、`reference_audio`。

**幂等**：带 `Idempotency-Key`（或 `X-Idempotency-Key`、`X-Thankyou-Task-Id`），同一把 key 重送会回原本的 task id，不会重复建立、不会重复计费。影片、图像、语音各用各的 key：同一把 key 先用在图像再用在影片，会回 `409`。

### 栏位写错不会报错

`content[]` 系列**不检查栏位名**。拼错的栏位、或这个模型不吃的栏位，一样回 `202`，只是没有效果。Kling、Seedance 没宣告的顶层栏位会原样转给模型（例如 `negative_prompt`）；放进 `input: {…}` 的栏位也会转送，而且同名时 `input` 里的优先。

要确认参数有没有生效，看轮询结果里的 `resolved_params`（模型实际采用的参数）；`params_raw` 是 gateway 实际送出的内容。`resolved_params` 也包含模型自己填的默认值，所以要比对**值**是不是你送的，不是只看栏位在不在。

扁平系列相反：多余的栏位会被拒绝，回 `400 Extra inputs are not permitted`。

## 素材怎么传

`content[].image_url.url`（或 `video_url.url`、`audio_url.url`）可以放：

| 形式 | 说明 |
| --- | --- |
| 公开 `https://…` URL | 最简单。模型要能免登录直接抓得到。 |
| base64 | 也接受。 |
| 素材 API 回传的 `asset://…`（`AssetUri`） | 原样放进来。部分模型要求这种方式，见下方。 |

**`/v1/files` 的文件不能当素材。** 它回的 `an_…` 是 chat 用的文件 id，放进 `image_url.url` 会回 `400 The parameter content[1].image_url specified in the request is not valid`；放 `https://api.atptoken.ai/v1/files/{id}` 也是 `400`。请把文件放到公开 `https://` URL，或登记成素材。

图片端点不支持 `asset://` 引用，收到时会在生成阶段回 `provider_error / generation_failed`。

### 登记素材

登记素材本身也要一个公开网址，所以它不是「没有公开网址时」的替代品，而是部分模型要求的另一种引用方式。

**把素材登记成 asset**

1. 建立素材群组 — `POST /omni/media/v1/asset-groups` — body：`Name`、`Description`、`model`（建议带）
2. 登记素材 — `POST /omni/media/v1/assets` — body：`group_id`、`url`、`asset_type`、`name`
3. 轮询到就绪 — `POST /omni/media/v1/assets/get` — body：`asset_id`；回传 `AssetUri`
4. 建立影片任务 — `POST …/contents/generations/tasks` — `AssetUri` 放在 `content[].image_url.url`

```
{ "type": "image_url", "image_url": { "url": "asset://…" }, "role": "reference_image" }
```

这条链最常出错的地方：

- **顺序不能跳。** 没有 `group_id` 不能登记。素材还没就绪就建任务，回 `400`（`reason: asset_not_ready`）；素材建立失败，回 `400`（`reason: asset_failed`）。所以第三步的轮询不能省。
- **`asset_type` 一定要写**，值是 `Image`、`Video`、`Audio`。不写的话，影片可能被登记成图片，而且不会报错。
- **建群组时带 `model`。** 带了才保证这个群组之后能给那个模型用。
- **群组有配额（约 50 个）。** 重复使用群组，不要一个素材开一个。
- **`name` 最多 64 个字元。** 超过时登记照样回 200，轮询才看到失败（`InvalidParameter.Name`），拿它建任务会得到 `ATP_ASSET_FAILED`。缩短名字即可。
- **同一个任务不能混用不同来源的素材**，会回 `400`。
- 状态变成 `Completed` 或 `Active`（依上游而定）才算就绪。

**部分模型的登记是排队的。** 每个群组每 20 秒只建立一笔，所以会立刻回一个 `asset-q-…` 的 id（`AssetUri` 是 `asset://asset-q-…`）、状态 `Processing`，并用 `Retry-After` 给出预估秒数。轮询到 `Completed` 再拿去建任务。不同群组各自排队。

素材跟群组同寿命：群组被清理后（影片完成后回收，或每天清掉闲置超过一天的群组），这个 id 就查不到了。

`seedance-2-0-fast` 不接受素材，回 `422 this asset's upstream does not serve the requested model`，请直接传公开网址。各 Seedance 模型的支持情况见 [Seedance](https://atptoken.ai/zh-cn/docs/seedance-2-0/)。

### 真人照片

真人照片用公开网址送出时，可能被拒，回 `400 may contain real person`。被挡时，把同一张图登记成素材，改传 `AssetUri`，**不需要核身**。`seedance-2-0-fast` 不能用素材，所以真人照片不要用它。

只有你的产品要求核身时，才走核身流程：

**真人素材核身（选用）**

1. 开始核身 — `POST /omni/media/v1/validate-session` — 回 `h5_link` + `session_ref`；不计费
2. 使用者完成核身 — 把 `h5_link` 给使用者 — 完成后你拿到 `byted_token`
3. 取得群组 — `POST /omni/media/v1/validate-result` — body：`session_ref`、`byted_token`；回 `group_id`
4. 登记素材并建任务 — `POST /omni/media/v1/assets` → `assets/get` → 建立任务 — 用上一步的 `group_id`

核身流程自己会给群组，**不要再去开新群组**。要查群组，用 `GET /omni/media/v1/asset-groups/{id}`（回 `group_type`）。

## 轮询与下载

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks/cgt_... \
  -H "Authorization: Bearer atp-..."
# → { "status": "succeeded", "content": { "video_url": "https://media-prod.atptoken.ai/v/...mp4?exp=...&sig=..." } }
```

| 状态 | 终态 | 意思 |
| --- | --- | --- |
| `queued` | | 已入列，继续轮询 |
| `running` | | 生成中，继续轮询 |
| `succeeded` | ✓ | 有结果；仍要检查 `video_url` 是不是 `null` |
| `failed` | ✓ | 失败，原因在 `error: { code, message }` |
| `expired` | ✓ | 结果已不在 |
| `cancelled` | ✓ | 已取消 |

只等 `succeeded` 的回圈碰到 `failed` 会永远转下去，四个终态都要跳出。影片是分钟级的。

| 方法 | 路径 | 动作 |
| --- | --- | --- |
| POST | /omni/media/v1/contents/generations/tasks | 建立 |
| GET | /omni/media/v1/contents/generations/tasks/{id} | 轮询；查不到或不是你的回 `404` |
| GET | /omni/media/v1/contents/generations/tasks | 列出本项目的任务 |
| DELETE | /omni/media/v1/contents/generations/tasks/{id} | `queued` → 取消；终态 → 删记录；`running` → `409` |

要最后一帧：建立时送 `return_last_frame: true`，结果在 `content.last_frame_url`。

## Kling 影片模型

Kling 用和 Seedance 相同的端点。**操作与画质由模型名称决定，不是由参数决定**：`standard` 输出 720p、`pro` 输出 1080p（`-v2v`、`-video-edit` 例外）；后缀决定操作。

| 你要做什么 | 模型 | 素材 |
| --- | --- | --- |
| 文生影片 | `kling-o3-standard`／`-pro`、`kling-v3-standard`／`-pro` | 只有文字 |
| 图生影片 | 上述模型加 `-i2v` | 1 张 `first_frame` |
| 参考图生影片 | `kling-o3-standard-reference`／`kling-o3-pro-reference`（1–6 张图）、`-reference-7`（7 张图） | `reference_image` |
| 拿原片当参考生新片 | `kling-o3-standard-v2v`、`kling-o3-pro-v2v` | 放在 `input`，见下方 |
| 修改原片 | `kling-o3-standard-video-edit`、`kling-o3-pro-video-edit` | 放在 `input`，见下方 |

素材用 `content[]` 送就好，gateway 会转成模型要的格式，不要自己组 `reference_assets`（`-v2v`、`-video-edit` 除外）。尾帧（`last_frame`）请先不要送。

| 栏位 | 可用值 | 默认 |
| --- | --- | --- |
| `prompt`（文字区块） | 最长 2500 字；`kling-v3-*` 必填 | |
| `ratio` | 只有 `16:9`、`9:16`、`1:1` | `16:9` |
| `duration` | 3–15 秒 | `5` |
| `resolution` | `720p`、`1080p`；**只有 `-i2v` 吃这个栏位** | |
| `generate_audio` | 布林值；`kling-o3-*` 用 | `true` |
| `sound` | 布林值；`kling-v3-standard`、`kling-v3-*-i2v` 用 | `false` |
| `negative_prompt` | 最长 1000 字；`kling-v3-*` | |
| `cfg_scale` | 0–1；`kling-v3-standard`／`-standard-i2v` | `0.5` |
| `guidance_scale` | 0–1；`kling-v3-standard`、`kling-v3-*-i2v` | `0.5` |
| `multi_prompt` | 阵列；`kling-o3-*` | |

和你送的值不一样的地方：

- **音讯栏位两群不同。** o3 用 `generate_audio`，**默认是 `true`**，不送就有音轨；要无声就送 `false`。v3 用 `sound`。`kling-v3-pro` 没有音讯栏位。
- **`-i2v` 不吃 `ratio`**，长宽比跟著输入图。送了不报错，但不生效。
- **`-reference-7` 也不套用 `ratio`**：要 `16:9`，实际输出 960×960。
- 要确定就看回来的影片，或比对 `resolved_params`。

### 文生影片

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-job-001" \
  -d '{
    "model": "kling-o3-standard",
    "content": [{ "type": "text", "text": "an orange cat walking slowly along the beach at sunset, steady tracking shot" }],
    "ratio": "16:9",
    "duration": 5,
    "generate_audio": false
  }'
# → 202 { "id": "cgt_..." }
```

### 图生影片

```
{
  "model": "kling-o3-standard-i2v",
  "content": [
    { "type": "text", "text": "the person slowly turns and smiles; keep the outfit and background unchanged" },
    { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
  ],
  "resolution": "720p",
  "duration": 5
}
```

选 Pro 时换成 Pro 的模型 ID，并把 `resolution` 改成 `1080p`。

### 参考图生影片

```
{
  "model": "kling-o3-standard-reference",
  "content": [
    { "type": "text", "text": "the figure turns and walks away" },
    { "type": "image_url", "image_url": { "url": "https://example.com/figure.jpg" }, "role": "reference_image" }
  ],
  "ratio": "16:9",
  "duration": 3,
  "generate_audio": false
}
```

### 影片转影片与影片编辑

先选操作：要**改这支原片**（换背景、换物件、改风格，其余保留）选 `-video-edit`；要**拿原片当动作或内容参考，生一支新片**选 `-v2v`。

这两类的请求放在 **`input`**，不是 `content[]`。来源影片要放在公开 `https://` 网址：

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: kling-edit-001" \
  -d '{
    "model": "kling-o3-standard-video-edit",
    "input": {
      "prompt": "Replace the cat in the video with a Shiba Inu. Keep the motion, camera and everything else unchanged.",
      "reference_assets": [
        { "role": "source_video", "asset_type": "video", "url": "https://example.com/source.mp4" }
      ],
      "keep_original_sound": false
    }
  }'
# → 202 { "id": "cgt_..." }
```

| 栏位（都在 `input` 里） | 可用值 | 说明 |
| --- | --- | --- |
| `prompt` | 最长 2500 字 | 必填 |
| `reference_assets` | 阵列 | 必填。恰好一个 `source_video`；参考图 0–4 张 |
| `keep_original_sound` | 布林值 | 默认 `false`。要保留原片声音送 `true` |
| `duration` | 3–15 秒 | 只有 `-v2v`；不送时 `5` |

要指定新主体的长相，再加参考图，每张一个项目，在 prompt 里用「the dog in Image 1」指名它：

```
{ "role": "reference", "asset_type": "image", "url": "https://example.com/dog.jpg" }
```

**输出跟著原片，不照 standard／pro 的 720p／1080p 规则。** 给一支 1280×720、3 秒的原片：`-video-edit` 输出 1280×720、3 秒（pro 也一样）；`-v2v` 不送 `duration` 时输出 1280×720、5 秒。

**prompt 第一句写要改什么。** 点名目标、说出新状态，保留只用一句带过。逐项列出要保留的东西，或要求新主体符合旧主体的外观，模型可能判断成「什么都不改」：任务照样 `succeeded`，回来的还是原片。`succeeded` 不代表修改生效，要看回来的影片。

这两类写错时在建立就被拒，不建立任务、不收费：

- 影片放在 `content[]`（不论 `role` 是 `source_video` 还是 `reference_video`）→ `422 The parameter combination is not supported.`
- 参考图的 `role` 写成 `reference_image` 或 `image` → 同上。这里要写 `reference`。

## 阿里影片模型

`wan-2-7-t2v`／`wan-2-7-i2v` 与 HappyHorse 的文生／图生／参考图模型用同一个端点与 `content[]` 写法，以下只列各模型特有之处。**`happyhorse-1.0-video-edit` 是例外：它用另一个端点**（见下）。

| 模型 | 输入 | 时长 | 计费解析度 | 端点 |
| --- | --- | --- | --- | --- |
| `wan-2-7-t2v` | 文字 | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `wan-2-7-i2v` | 文字 + 1 张 `first_frame` | 2–15 秒 | **一律 1080P**（见注意事项） | 统一 |
| `happyhorse-1.1-t2v` | 文字 | 3–15 秒 | 依请求 720p／1080p | 统一 |
| `happyhorse-1.1-i2v` | 文字 + 1 张 `first_frame` | 3–15 秒 | 依请求 720p／1080p | 统一 |
| `happyhorse-1.1-r2v` | 文字 + 1–9 张 `reference_image` | 3–15 秒 | 依请求 720p／1080p | 统一 |
| `happyhorse-1.0-video-edit` | 1 支来源影片（3–60 秒）+ 最多 5 张参考图 | 依来源影片长度 | 依请求 720P／1080P | **video-synthesis** |

| 栏位 | 可用值 | 说明 |
| --- | --- | --- |
| `resolution` | `720p`、`1080p`（小写） | 只有这两阶 |
| `ratio` | `16:9` 等 | 与 `resolution` 搭配使用 |
| `duration` | 整数秒 | 范围见上表 |
| `watermark` | 布林值 | |
| `seed` | 整数 | |
| `audio_setting` | | 只有 `-video-edit` |

> **有些模型可能暂时无法服务**
>
> `wan-2-7-t2v`、`wan-2-7-i2v`、`happyhorse-1.1-t2v` 可能在建立时就回 `404 not_found_error — upstream returned 404`。这是模型暂时无法服务，不是写错；不会建立任务，也不收费。要文字生影片可改用 `wan-2-7-video`（同样的 `content[]` 写法），或稍后再试。

> **wan-2-7 不论请求解析度皆输出 1080P**
>
> `wan-2-7-t2v`／`wan-2-7-i2v` 即使请求 `720p` 仍回传 1080P 影片，且计费依实际产出计算——5 秒影片会以 1080P 费率计价。请以 1080P 估算预算；若需要 720P 价位请改用 `happyhorse-1.1-*`。

> **HappyHorse 只支持 720p 与 1080p**
>
> 送 `480p` 等于没送，会用模型自己的默认：约 1080P 产出、按 1080P 费率计费。需要 720P 价位请明确送 `720p`。

### 文生影片

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: hh-job-001" \
  -d '{
    "model": "happyhorse-1.1-t2v",
    "content": [{ "type": "text", "text": "a horse galloping across a green field" }],
    "resolution": "720p", "ratio": "16:9", "duration": 5,
    "watermark": false
  }'
# → 202 { "id": "cgt_..." }
```

### 图生影片

加一个 `role: "first_frame"` 的图片区块：

```
"content": [
  { "type": "text", "text": "the subject turns slowly toward the camera" },
  { "type": "image_url", "image_url": { "url": "https://example.com/first.jpg" }, "role": "first_frame" }
]
```

### 参考图生影片

`happyhorse-1.1-r2v` 接受 1 至 9 张参考图，每张带 `role: "reference_image"`，在 prompt 中以 `[Image 1]`、`[Image 2]` 指代：

```
"content": [
  { "type": "text", "text": "[Image 1] walks into the room shown in [Image 2]" },
  { "type": "image_url", "image_url": { "url": "https://example.com/person.jpg" }, "role": "reference_image" },
  { "type": "image_url", "image_url": { "url": "https://example.com/room.jpg" }, "role": "reference_image" }
]
```

### 影片编辑

`happyhorse-1.0-video-edit` **要用 video-synthesis 端点，不是统一端点。** 送到统一端点会在建立时回 `400`，消息要你改用这个端点、把影片放在 `input.media[]`。建立后轮询 `GET /omni/media/v1/tasks/{id}`：

```
curl https://api.atptoken.ai/omni/media/v1/services/aigc/video-generation/video-synthesis \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: my-stable-key-123" \
  -d '{
    "model": "happyhorse-1.0-video-edit",
    "input": {
      "prompt": "replace the background with a snowy street",
      "media": [
        { "type": "video",           "url": "https://example.com/source.mp4" },
        { "type": "reference_image", "url": "https://example.com/style.jpg" }
      ]
    },
    "parameters": { "resolution": "720P", "watermark": false }
  }'
# → 202 { "output": { "task_id": "cgt_...", "task_status": "PENDING" } }

curl https://api.atptoken.ai/omni/media/v1/tasks/cgt_... -H "Authorization: Bearer atp-..."
# → { "output": { "task_status": "SUCCEEDED", "video_url": "https://media.atptoken.ai/v/..." }, "usage": { … } }
```

- `input.media[].type` 只接受 `video` 与 `reference_image`，网址栏位名为 `url`（不是 `video_url`）。
- **写错时建立仍回 `202`**，错误要等轮询才以 `InvalidParameter` 出现，例如 `InvalidParameter: Field required: input.media`。建立成功不代表内容正确。
- 来源影片与每一张参考图都必须能免登录直接下载；任一个抓不到时任务会以 `FAILED`＋`Failed to download …` 结束且不计费。
- 这个端点回自己的格式（`output.task_status`、`output.video_url`）；过期后是 `SUCCEEDED` + `video_url: null`。输出长度依来源影片，不是 `parameters.duration`。
- 这个模型也可能在建立时回 `404 not_found_error — upstream returned 404`，意思同上：暂时无法服务，不收费。
- 权限、余额与计费规则跟统一端点完全相同。

### 其他模型特性

- **浮水印**：HappyHorse 浮水印**默认开启**——需传 `watermark: false` 关闭；Wan 2.7 默认关闭。
- **画面比例**：HappyHorse 在共用清单之外另支持 `4:5`、`5:4`、`9:21`、`21:9`。
- **Prompt 长度**：5,000 字元（HappyHorse 中文 2,500 字）。
- 这些模型尚未支持 `generate_audio`。

## Wan 3.0 与 spicy：扁平请求

`wan-3-0-video`、`wan-3-0-video-pro`、`wan-3-0-video-prime`、`wan-2-2-i2v-spicy`、`wan-2-7-i2v-spicy` **不吃 `content[]`**，`prompt` 和素材都放在顶层。`content` 阵列会被丢掉；丢掉后内容变空，会回 `missing_prompt_or_image`。

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: wan3-job-001" \
  -d '{
    "model": "wan-3-0-video",
    "prompt": "a paper boat drifting on still water",
    "first_frame": "https://example.com/first-frame.png",
    "resolution": "480P",
    "ratio": "16:9",
    "duration": 4,
    "audio": false,
    "prompt_extend": false
  }'
# → 202 { "id": "cgt_..." }
```

**最容易写错的两处：音讯栏位叫 `audio`，不是 `generate_audio`；`resolution` 要大写。**

| 栏位 | 可用值 | 默认 |
| --- | --- | --- |
| `prompt` | 字串 | 必填 |
| `first_frame`、`last_frame` | 图片 URL | 首尾帧模式 |
| `reference_images` | 最多 10 个 URL | 参考素材模式 |
| `reference_videos`、`reference_audios` | 各最多 5 个 URL | 参考素材模式 |
| `resolution` | `480P`、`720P`、`1080P`；`-pro` 另有 `2K`、`4K` | `480P` |
| `duration` | `-1`（用模型默认长度，有输入影片时通常跟著影片），或 2–30 秒 | `4` |
| `ratio` | `16:9`、`9:16`、`4:3`、`3:4`、`1:1`、`adaptive` | `16:9` |
| `audio` | 布林值 | `false` |
| `prompt_extend` | 布林值 | `false` |

- 支持文生影片、首帧、首尾帧、参考图＋参考音讯、参考影片。
- 同一个请求只能用首尾帧模式**或**参考素材模式，不能混用。
- 送 `aspect_ratio`、`generate_audio`、`watermark` 或 `media` 会回 `400 Extra inputs are not permitted`。`content` 会被丢掉，`input` 会被拆开并到顶层，都不要用。
- 两个 spicy 模型跟 `wan-3-0-video*` 同一种扁平格式，栏位名规则相同。

## MiniMax H3

`minimax-h3` 用 `content[]` 写法：

```
curl https://api.atptoken.ai/omni/media/v1/contents/generations/tasks \
  -H "Authorization: Bearer atp-..." -H "Content-Type: application/json" \
  -H "Idempotency-Key: minimax-job-001" \
  -d '{
    "model": "minimax-h3",
    "content": [{ "type": "text", "text": "a paper boat drifting on still water" }],
    "resolution": "768P",
    "duration": 6
  }'
# → 202 { "id": "cgt_..." }
```

- `resolution` 只有 `768P` 与 `2K` 两阶；送 `480p`、`720p`、`1080p`、`4k` 会对映到这两阶。
- **不要送 `watermark`。** 不论 `false` 或 `"false"`，都会在建立时回 `400 invalid params, watermark is invalid (2013)`。

## 计费

任务进入终态后才结算，依**实际**用量扣款：

```text
video_tokens = (in_dur + out_dur) × W × H × fps ÷ 1024
```

`in_dur` 是输入影片秒数、`out_dur` 是输出秒数、`W × H` 是输出的宽高。有些模型会自己回报用量，这时以回报的为准。轮询结果的 `usage` 是 token 用量，影片的 input 永远是 0。费率见[价格页](https://atptoken.ai/zh-cn/pricing/)。

- **建立时只做轻量预留**：只要余额还是正的就放行；余额耗尽（`credit − inflight ≤ 0`）才回 `402`。
- 结算时余额不足会扣成负值，**下一个请求会被挡住**。
- 受控与否只决定谁能用，不影响计价；不受控的模型照样计费。
- 在建立时就被拒的请求不建立任务、不收费。任务失败不计费。
- 带输入影片的模型（例如 `-r2v`、`-video-edit`）**输入秒数一并计费**：以 5 秒来源影片产出 5 秒成品，计 10 秒。

## 错误

**4xx 要读消息，不要只看状态码。** 模型自己的 4xx 会原样转给你，消息通常直接指名栏位与合法值。回报问题时带上回应的 `x-request-id`。

- 400 — 请求格式错：缺 `model` 或 prompt、混用不同来源的素材、`asset_not_ready`、`asset_failed`。读消息后修正。
- 401 — `token_revoked`：密钥无效，或**根本没送密钥**。先确认 header 有送出。
- 402 — `insufficient_quota`：项目余额耗尽。不是暂时性限流，**不要重试**，加值后再送。
- 403 — `permission_denied`：这个模型受控，项目不在白名单。换模型或请管理者授权。
- 404 — 建立时回 `upstream returned 404`：模型暂时无法服务，换模型或稍后再试。轮询时回 404：任务不存在或不是你的。
- 409 — 这把 `Idempotency-Key` 已用在另一个媒体介面；或想取消 `running` 的任务。
- 422 — 请求外层或素材角色不是这个模型要的；或素材不能给这个模型用；或模型目前没有可用容量。
- 429 — 限流。退避后重试。
- 502 — 建立失败。可以重试（幂等保留会释放）。
- 503 — 入列失败，或 `balance_check_unavailable`（**读不到余额，不是余额不足**；没有扣款）。依 `Retry-After` 重试。

常见消息（都在建立时就被拒，不建立任务、不收费）：

| 消息 | 原因 | 怎么办 |
| --- | --- | --- |
| `422 The parameter combination is not supported.` | 外层或素材角色不对，最常见是 Kling `-v2v`／`-video-edit` 把影片放进 `content[]` | 照该模型的范例写 |
| `422 this asset's upstream does not serve the requested model` | 素材不能给这个模型用（例如 `seedance-2-0-fast`） | 改传公开网址 |
| `400 may contain real person` | 公开网址的图含真人 | 登记成素材，传 `AssetUri` |
| `400 The parameter content[1].image_url specified in the request is not valid` | `url` 不是可下载的网址，例如 `/v1/files` 的 `an_…` | 放公开网址或 `AssetUri` |
| `400 missing content[1].image_url` | 网址放在区块顶层 | 放进 `image_url: { "url": … }` |
| `400 Extra inputs are not permitted` | 扁平模型收到不认得的栏位 | 用该模型自己的栏位名 |
| `400 invalid params, watermark is invalid (2013)` | 这个模型不收 `watermark` | 拿掉 `watermark` |

任务本身失败时，状态是 `failed`，原因在 `error`。

## 下一步

- [Seedance](https://atptoken.ai/zh-cn/docs/seedance-2-0/) — Seedance 2.0 与 2.5 的模型选择、素材组合、参数与范例。
- [/v1/files](https://atptoken.ai/zh-cn/docs/files/) — 上传给 chat 与 messages 请求使用的文件。媒体任务无法使用。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码代表什么、先检查什么。
