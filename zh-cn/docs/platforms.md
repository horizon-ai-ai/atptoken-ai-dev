# 平台与工作流工具

> Source: https://atptoken.ai/zh-cn/docs/platforms/

用介面组装 AI、不自己写代码的工具——应用建构平台、工作流自动化——接 Gateway 的方式跟 SDK 一样。把工具里的 OpenAI 相容 provider 指向 Gateway，这个 project 允许的模型就全部在里面可用，共用一把金钥、一张帐单。

> **这一页也有纯 markdown 版本**
>
> 任何文件网址加上 `.md` 就能读到纯文字版：`https://atptoken.ai/docs/platforms.md`。想把整页喂给 AI 助理时很好用。

### 开始之前

三个值，到哪里都一样：

- **Base URL** — 填 `https://api.atptoken.ai/v1`。要含 `/v1`，但不要接 `/chat/completions`。
- **API Key** — 那把 `atp-…` 开头的 project key。
- **Model** — `GET /v1/models` 回传的其中一个 id。

工具之间的差别，在于它能不能自己去读你的模型清单：

| 工具 | 设定位置 | 模型清单 |
|---|---|---|
| Dify | Settings → Model Providers | 一次加一个，手动 |
| n8n | OpenAI credential 的 Base URL 栏位 | 从 `GET /v1/models` 自动读 |

如果你要接的是 coding agent——Claude Code、Codex、Cline 那一类——请看 [Coding agents](https://atptoken.ai/zh-cn/docs/agents/)。

### Dify

从 marketplace 安装 **OpenAI-API-compatible** 这个 model provider，然后在它的卡片上按 **Add Model**。要填的栏位：

| 栏位 | 值 |
|---|---|
| Model Name | `GET /v1/models` 回传的模型 id |
| API Key | 你的 `atp-…` 金钥 |
| API Base URL | `https://api.atptoken.ai/v1` |
| Model context size | 该模型真正的 context window |
| Upper bound for max tokens | 该模型真正的输出上限 |
| Function Call Type | 想让 agent 使用工具就选 `Tool Call` |
| Vision Support | 吃图片的模型选 `Support` |

多数卡关来自两个预设值。**Model context size 预设只有 4096**，超过就被静默截断，所以每个模型都要照实填。还有 **Function Call Type 预设是 `no_call`**，代表 Dify 根本不会送出 tools 阵列——建在这个模型上的 agent 会安静地不呼叫任何工具，直到你改掉它。

Dify 不会去读 `GET /v1/models`，每个模型都要独立 Add Model 一次。先打那支端点，照它回传的清单一个个加。

Dify Cloud 与自架版的设定方式相同。

### n8n

n8n 用它内建的 **OpenAI** credential。建一组，在 **Add option** 里把 **Base URL** 设成 `https://api.atptoken.ai/v1`，**API Key** 贴上 `atp-…` 金钥。

之后模型下拉选单就会透过这个 base URL 去读 `GET /v1/models`，你 project 的模型会自己出现，不用手动列。

使用时，在 **AI Agent** 或 **Basic LLM Chain** 节点底下挂一个 **OpenAI Chat Model** 子节点，选这组 credential。

> **要用 AI Agent 节点，不要用 OpenAI 节点的 Message a model**
>
> OpenAI 节点自己的 `Message a model` 动作，配自订 Base URL 时有一个尚未修复的问题：credential 测试会过，但实际执行回 `404`。走 `AI Agent` 加 `OpenAI Chat Model` 子节点才是可行的路。

还有两点。Base URL 栏位在 credential 上，不在节点上——它在后来的版本被从节点隐藏了，所以会给人「找不到这个栏位」的感觉。另外 n8n 官方文件没有列出这个栏位，它只存在于 credential 介面的 **Add option** 里。

n8n Cloud 与自架版的行为相同。

### 排错

- **`403`** — 模型没有在这把 key 所属的 project 启用。到 Console 的该 project Resources 开启。
- **`404`** — `/v1` 位置放错，或工具在已经以 `/chat/completions` 结尾的网址后面又接了一次。
- **模型选单是空的** — Dify 本来就不会替你列模型，要一个个加。n8n 如果是空的，通常代表金钥或 base URL 有误，因为那个下拉是由 `GET /v1/models` 填的。
- **工具都没有被呼叫** — Dify 那边的 `Function Call Type` 还停在 `no_call`。

## 后续步骤

- [Coding agents](https://atptoken.ai/zh-cn/docs/agents/) — Claude Code、Codex 与其他终端机 agent
- [管理 API keys](https://atptoken.ai/zh-cn/docs/console-keys/) — 接进共用工具之前，先把金钥限定在单一 project
- [点数如何运作](https://atptoken.ai/zh-cn/docs/credits/) — 这些工具的用量怎么计费
