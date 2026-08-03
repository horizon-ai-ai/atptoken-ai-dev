# 在 ATP 上跑 Claude Code

> Source: https://atptoken.ai/zh-cn/docs/cb-claude-code/

把 Claude Code 指向 Gateway，用一把 project key 驱动任一允许的模型 — 不用改 code，只设环境变数。

## 1. 建立 project API key

在 Console 建立（或选择）organization、workspace 与 project，再从该 project 建立 API key。这把 key 会继承 project 的允许模型与 credit balance。完整密钥只显示一次，记得复制。见 [管理 API keys](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 2. 把 Claude Code 指向 Gateway

设定 base URL（不用加 `/v1` — Claude Code 会自己补上 `/v1/messages`）、把 key 当 auth token 送出，并清掉 `ANTHROPIC_API_KEY` 以免它盖过去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

偏好设定档？把相同的值写进 `~/.claude/settings.json` 的 `env` 区块。

## 3. 挑一个允许的模型

`ANTHROPIC_MODEL` 必须是 [GET /v1/models](https://atptoken.ai/zh-cn/docs/models/) 回传、且在该 key 所属 project 已启用的 model id — 否则 Gateway 回传 `403`。不确定就先列出 id。

## 4. 验证

在 Claude Code 跑一段 prompt，再打开 Console:该次呼叫会出现在 Request logs，花掉的 credits 会显示在 Usage 页。见 [用量与纪录](https://atptoken.ai/zh-cn/docs/monitoring/)。

> **Codex 也一样**
>
> 同样的做法适用于 Codex 与其他会说 OpenAI 或 Anthropic wire format 的 agent — Codex 设定见 [Coding agents](https://atptoken.ai/zh-cn/docs/agents/)。
