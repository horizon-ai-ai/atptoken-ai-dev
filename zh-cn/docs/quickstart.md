# 快速开始

> Source: https://atptoken.ai/zh-cn/docs/quickstart/

用一把项目 API 密钥，通过你熟悉的 SDK 呼叫模型，最后在控制台的「请求记录」看到这一笔。本页用 OpenAI 格式示范；Anthropic 与 Gemini 格式见 [Anthropic SDK](https://atptoken.ai/zh-cn/docs/sdk-anthropic/) 与 [Google GenAI SDK](https://atptoken.ai/zh-cn/docs/sdk-google/)。

> **开始前需要**
>
> - ATP Token 账号：[免费注册](https://atptoken.ai/zh-cn/signup/)
> - 至少 USD 5 的点数（500 点）。没有点数时请求会回 `402`。
> - 已安装 Python 或 Node.js，或只用终端机的 curl。

- [自己接 API](#建立账号并充值)
  六个步骤：从充值到在控制台看到第一笔请求。
- [用 coding agent 接](https://atptoken.ai/zh-cn/docs/agents/)
  Claude Code、Codex、Cline 等工具的设定方式。

## 1. 建立账号并充值

登录[控制台](https://atptoken.ai/zh-cn/console/)。第一次登录会请你替组织命名。接著到「账单」按「充值」，最低 USD 5（500 点），点数不会过期。
如果你用的是团队组织，充值会先进入你的个人钱包，请再到「资源」把点数拨给要使用的工作区。详见 [充值与钱包](https://atptoken.ai/zh-cn/docs/topup/)。

## 2. 建立 API 密钥

到控制台的「API 密钥」，按「建立 API 密钥」。精灵可选择既有工作区与项目，或在权限允许时建立；接著设定项目可呼叫的模型并产生密钥。**至少勾选一个模型**，这把密钥只能呼叫这些模型。
密钥以 `atp-` 开头，完整内容只显示这一次，请立刻复制。

## 3. 安装 SDK 并设定密钥

```curl
export ATP_API_KEY="atp-your-key"
```

```Python
pip install openai
export ATP_API_KEY="atp-your-key"
```

```Node.js
npm install openai
export ATP_API_KEY="atp-your-key"
```

Gateway 位址是 `https://api.atptoken.ai/v1`（OpenAI 格式）。密钥可以放在哪些 header，见 [验证方式](https://atptoken.ai/zh-cn/docs/auth/)。

## 4. 查询这把密钥可用的模型

```curl
curl https://api.atptoken.ai/v1/models \
  -H "Authorization: Bearer $ATP_API_KEY"
```

```Python
import os
from openai import OpenAI

client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key=os.environ["ATP_API_KEY"])
for m in client.models.list().data:
    print(m.id)
```

```Node.js
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "https://api.atptoken.ai/v1", apiKey: process.env.ATP_API_KEY });
const models = await client.models.list();
for (const m of models.data) console.log(m.id);
```

从清单挑一个模型 ID，下一步会用到。如果清单是空的，表示项目还没开通模型：到控制台的「资源」替项目加上模型。

## 5. 送出第一个请求

把 `MODEL_ID` 换成上一步挑的模型 ID。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
r = client.chat.completions.create(model="MODEL_ID", messages=[{"role": "user", "content": "hi"}])
print(r.choices[0].message.content)
print(r.usage)
```

```Node.js
const r = await client.chat.completions.create({ model: "MODEL_ID", messages: [{ role: "user", content: "hi" }] });
console.log(r.choices[0].message.content, r.usage);
```

成功时会收到 OpenAI 格式的回应：`choices[0].message.content` 是模型的回复，`usage` 是这次的 input／output tokens。

```json
{
  "object": "chat.completion",
  "model": "MODEL_ID",
  "choices": [
    {
      "message": { "role": "assistant", "content": "Hi! How can I help?" },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 9,
    "total_tokens": 17
  }
}
```

| 回应 | 代表什么 | 怎么处理 |
|---|---|---|
| `401` | 密钥没带到、打错，或已停用 | 确认 `ATP_API_KEY` 有值、以 `atp-` 开头；必要时到「API 密钥」重新建立 |
| `402` | 点数用完 | 到「账单」充值；团队组织再到「资源」拨点数 |
| `403` | 这个模型没有在项目开通 | 改用第 4 步清单里的模型 ID，或到「资源」替项目加上模型 |

其他状态码见 [错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 6. 在控制台确认这一笔

打开控制台的「总览」，在「最近请求」按「查看全部」，或直接开 [请求记录](https://atptoken.ai/zh-cn/console/logs/)。刚才的请求会排在最上面，显示模型、状态与 input／output tokens；扣掉的点数会算进「用量」。

## 下一步

- [验证方式](https://atptoken.ai/zh-cn/docs/auth/) — 三个可以放密钥的位置，以及 Gemini SDK 的设定。
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — tokens 怎么换算成点数。
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — 每个状态码先检查什么。
