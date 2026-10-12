# 在 ATP 上跑 Claude Code

> Source: https://atptoken.ai/zh-tw/docs/cb-claude-code/

把 Claude Code 指向 Gateway，用一把專案（project）金鑰驅動任一允許的模型——不用改 code，只設環境變數。

## 1. 建立專案 API 金鑰

在主控台建立（或選擇）組織、工作區與專案，再從該專案建立 API 金鑰。這把金鑰會繼承專案的允許模型與點數餘額。完整密鑰只顯示一次，記得複製。見 [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/)。

## 2. 把 Claude Code 指向 Gateway

設定 base URL（不用加 `/v1`——Claude Code 會自己補上 `/v1/messages`）、把金鑰當 auth token 送出，並清掉 `ANTHROPIC_API_KEY` 以免它蓋過去。

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

偏好設定檔？把相同的值寫進 `~/.claude/settings.json` 的 `env` 區塊。

## 3. 挑一個允許的模型

`ANTHROPIC_MODEL` 必須是 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/) 回傳、且在該金鑰所屬專案已啟用的模型 ID——否則 Gateway 回傳 `403`。不確定就先列出 id。

## 4. 驗證

在 Claude Code 跑一段 prompt，再打開主控台：該次呼叫會出現在請求紀錄，花掉的點數會顯示在用量頁。見 [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/)。

> **Codex 也一樣**
>
> 同樣的做法適用於 Codex 與其他會說 OpenAI 或 Anthropic wire format 的 agent——Codex 設定見 [Coding agents](https://atptoken.ai/zh-tw/docs/agents/)。

## 下一步

- [Coding agents](https://atptoken.ai/zh-tw/docs/agents/) — 在同一個 Gateway 上接 Codex、Cline 與其他 agent。
- [模型查詢](https://atptoken.ai/zh-tw/docs/models/) — 列出可以設成 `ANTHROPIC_MODEL` 的模型 ID。
- [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/) — 找到每一次 Claude Code 呼叫與它花掉的點數。
