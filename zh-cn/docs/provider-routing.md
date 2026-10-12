# 供应商路由与备援

> Source: https://atptoken.ai/zh-cn/docs/provider-routing/

平台上每个模型由一个或多个上游供应商组成的供应商池 服务。你呼叫单一模型 ID；Gateway 为该请求挑一个供应商，并可 fail over 到另一个，因此就算某个供应商降级，模型仍能持续运作。

## 一个模型 ID，背后一个供应商池

每个模型的供应商组合与顺序是设在平台端，不是逐请求指定。你的程式 永远只指名模型（来自 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/)）；实际由哪个供应商服务由 Gateway 处理，且可在请求之间改变，你这端不需改任何 code。

## 自动备援（fallback）行为

当某个供应商失败或逾时，Gateway 会换到该模型的供应商池里下一个可用的供应商。这对应到你可能看到的状态码：

| 状态码 | 意义 |
|---|---|
| `502` | 供应商连线失败或逾时。可安全重试。 |
| `503` | 该模型的所有供应商皆 circuit-open。请遵守 `Retry-After`（60 秒）。 |
| `429` | 上游速率限制、配额或供应商冷却中。若有 `Retry-After` 请遵守。 |

完整清单见 [错误码](https://atptoken.ai/zh-cn/docs/errors/)。所有回应都带一个 `request_id`，路由行为异常时可附上给支持。

> **尚未公开的设定**
>
> 供应商池内的挑选顺序、health-check 周期与 circuit-open 门槛不对外公开。可以依赖的行为：每个模型一个供应商池、自动备援，以及上表的状态码。

## 下一步

- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 完整的状态码清单，包含 `502`、`503` 与 `429`。
- [模型查询](https://atptoken.ai/zh-cn/docs/models/) — 列出请求里可以指名的模型 ID。
- [运作方式](https://atptoken.ai/zh-cn/docs/how-it-works/) — 跟著一个请求走过验证、模型授权、路由与计量。
