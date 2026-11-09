# 在 ATP 上跑 Claude Code

> Source: https://atptoken.ai/zh-cn/docs/cb-claude-code/

把 Claude Code 指向 Gateway，用一把项目（project）密钥驱动任一允许的模型——不用改 code，只设环境变数。

## 1. 建立项目 API 密钥

登录 atptoken.ai，依序建立（或选择）组织、工作区、项目——三层都要先有，才看得到建立密钥的地方——再从该项目建立 API 密钥。一把密钥只绑一个项目：它继承那个项目的允许模型与点数余额。完整密钥只显示一次，记得复制。见 [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 2. 把 Claude Code 指向 Gateway

设定 base URL（不用加 `/v1`——Claude Code 会自己补上 `/v1/messages`）、把密钥当 auth token 送出，并清掉 `ANTHROPIC_API_KEY` 以免它盖过去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # a model from GET /v1/project/models
claude
```

偏好设定档？把相同的值写进 `~/.claude/settings.json` 的 `env` 区块。

## 3. 挑一个允许的模型

`ANTHROPIC_MODEL` 必须是该密钥所属项目已启用、且在 `/v1/messages` 服务的模型。不要去 `GET /v1/models` 找：那是 OpenAI 的清单，多数 `claude-*` 不在上面。用同一把密钥打 `GET /v1/project/models`，拿项目的完整清单。

```
curl https://api.atptoken.ai/v1/project/models \
  -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN"
```

项目没开权限的模型会回 `403`（不收费）；在别的入口服务的模型会回 `422`，消息会指名那个入口。见 [模型查询](https://atptoken.ai/zh-cn/docs/models/)。

## 4. 验证

在 Claude Code 跑一段 prompt，再打开控制台：该次呼叫会出现在请求记录，花掉的点数会显示在用量页。见 [用量与记录](https://atptoken.ai/zh-cn/docs/monitoring/)。

> **Codex 也一样**
>
> 同样的做法适用于 Codex 与其他会说 OpenAI 或 Anthropic wire format 的 agent——Codex 设定见 [Coding agents](https://atptoken.ai/zh-cn/docs/agents/)。

## 下一步

- [Coding agents](https://atptoken.ai/zh-cn/docs/agents/) — 在同一个 Gateway 上接 Codex、Cline 与其他 agent。
- [模型查询](https://atptoken.ai/zh-cn/docs/models/) — 列出可以设成 `ANTHROPIC_MODEL` 的模型 ID。
- [用量与记录](https://atptoken.ai/zh-cn/docs/monitoring/) — 找到每一次 Claude Code 呼叫与它花掉的点数。
