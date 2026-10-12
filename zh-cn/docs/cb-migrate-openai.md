# 从 OpenAI 迁移

> Source: https://atptoken.ai/zh-cn/docs/cb-migrate-openai/

把既有的 OpenAI 整合搬到 ATP，通常只是两行改动：把 base URL 换成 Gateway、API 密钥换成项目（project）密钥。你的 request 与 response 结构完全不变。

## 1. 拿一把项目密钥

在控制台建立项目 API 密钥。它以 `atp-` 开头，继承所属项目的允许模型与点数。见 [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 2. 换掉 base URL 与密钥

把 OpenAI SDK 指向 Gateway、用 `atp-` 密钥。其余——messages、tools、串流——都不变。

```
from openai import OpenAI

# Before: client = OpenAI(api_key="sk-...")
client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")

r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## 3. 对应你的模型 ID

ATP 的模型 ID 来自 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/)，不是 OpenAI 的型录。列出后把 `model` 栏位改成你项目已启用的 id——未启用的模型会回 `403`。

## 4. 测试并确认

送一个请求，再看控制台：它会出现在请求记录（含 input / output tokens），花掉的点数显示在用量页。见 [用量与记录](https://atptoken.ai/zh-cn/docs/monitoring/)。

> **结构一样，账单合一**
>
> 因为 OpenAI wire format 原样通过，你 app 里解析 response 的部分不用改。现在跨所有模型的用量都以点数计量。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。

## 下一步

- [OpenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-openai/) — 用 OpenAI SDK 接 Gateway 的完整设定。
- [/v1/chat/completions](https://atptoken.ai/zh-cn/docs/chat/) — 迁移后的呼叫打的端点。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 用量如何以点数计量。
