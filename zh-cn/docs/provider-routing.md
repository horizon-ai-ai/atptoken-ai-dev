# Provider routing 与 fallback

> Source: https://atptoken.ai/zh-cn/docs/provider-routing/

平台上每个模型由一个或多个上游 provider 组成的 pool 服务。你呼叫单一 model id；Gateway 为该请求挑一个 provider，并可 fail over 到另一个，因此就算某个 provider 降级，模型仍能持续运作。

### 一个 model id，背后一个 pool

每个模型的 provider 组合与顺序是设在平台端，不是逐请求指定。你的 client 永远只指名模型（来自 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/)）；实际由哪个 provider 服务由 Gateway 处理，且可在请求之间改变，你这端不需改任何 code。

### Fallback 行为

当某个 provider 失败或逾时，Gateway 会换到该模型 pool 里下一个可用的 provider。这对应到你可能看到的状态码：

| 状态码 | 意义 |
|---|---|
| `502` | Provider 连线失败或逾时。可安全重试。 |
| `503` | 该模型的所有 provider 目前皆 circuit-open。请遵守 `Retry-After`（60 秒）。 |
| `429` | 上游速率限制、配额或 provider 冷却中。若有 `Retry-After` 请遵守。 |

完整清单见 [Errors](https://atptoken.ai/zh-cn/docs/errors/)。所有回应都带一个 `request_id`，路由行为异常时可附上给支援。

> **后端待确认的细节**
>
> Pool 内的挑选顺序、health-check 周期与 circuit-open 门槛设定在平台端，确认后会补在这页。上面的行为（每模型一个 pool、自动 fallback，以及状态码对应）目前可稳定依赖。
