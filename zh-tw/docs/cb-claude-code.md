# 在 ATP 上跑 Claude Code

> Source: https://atptoken.ai/zh-tw/docs/cb-claude-code/

把 Claude Code 指向 Gateway，用一把 project key 驅動任一允許的模型 — 不用改 code，只設環境變數。

## 1. 建立 project API key

在 Console 建立（或選擇）organization、workspace 與 project，再從該 project 建立 API key。這把 key 會繼承 project 的允許模型與 credit balance。完整密鑰只顯示一次，記得複製。見 [管理 API keys](https://atptoken.ai/zh-tw/docs/console-keys/)。

## 2. 把 Claude Code 指向 Gateway

設定 base URL（不用加 `/v1` — Claude Code 會自己補上 `/v1/messages`）、把 key 當 auth token 送出，並清掉 `ANTHROPIC_API_KEY` 以免它蓋過去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

偏好設定檔？把相同的值寫進 `~/.claude/settings.json` 的 `env` 區塊。

## 3. 挑一個允許的模型

`ANTHROPIC_MODEL` 必須是 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳、且在該 key 所屬 project 已啟用的 model id — 否則 Gateway 回傳 `403`。不確定就先列出 id。

## 4. 驗證

在 Claude Code 跑一段 prompt，再打開 Console:該次呼叫會出現在 Request logs，花掉的 credits 會顯示在 Usage 頁。見 [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/)。

> **Codex 也一樣**
>
> 同樣的做法適用於 Codex 與其他會說 OpenAI 或 Anthropic wire format 的 agent — Codex 設定見 [Coding agents](https://atptoken.ai/zh-tw/docs/agents/)。
