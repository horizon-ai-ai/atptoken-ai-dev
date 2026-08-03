# 从 OpenAI 迁移

> Source: https://atptoken.ai/zh-cn/docs/cb-migrate-openai/

把既有的 OpenAI 整合搬到 ATP，通常只是两行改动：把 base URL 换成 Gateway、API key 换成 project key。你的 request 与 response 结构完全不变。

## 1. 拿一把 project key

在 Console 建立 project API key。它以 `atp-` 开头，继承所属 project 的允许模型与 credits。见 [管理 API keys](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 2. 换掉 base URL 与 key

把 OpenAI SDK 指向 Gateway、用 `atp-` key。其余 — messages、tools、串流 — 都不变。

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

## 3. 对应你的 model id

ATP 的 model id 来自 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/)，不是 OpenAI 的型录。列出后把 `model` 栏位改成你 project 已启用的 id — 未启用的模型会回 `403`。

## 4. 测试并确认

送一个请求，再看 Console:它会出现在 Request logs（含 input / output tokens），花掉的 credits 显示在 Usage 页。见 [用量与纪录](https://atptoken.ai/zh-cn/docs/monitoring/)。

> **结构一样，帐单合一**
>
> 因为 OpenAI wire format 原样通过，你 app 里解析 response 的部分不用改。现在跨所有模型的用量都以 credits 计量。见 [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/)。
