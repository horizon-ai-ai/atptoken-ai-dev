# 加入 ATP MCP 伺服器

> Source: https://atptoken.ai/zh-tw/docs/mcp/

把 `https://mcp.atptoken.ai/mcp` 加進 Claude、ChatGPT、Cursor、Codex 等 AI 工具，讓它能查詢並檢查 ATP API 的呼叫方式。不需要金鑰。工具照樣用它原本的模型；這個伺服器只提供 ATP 的 API 指南和檢查工具，讓它第一次就寫對請求。

## 開始之前

需要網址、伺服器名稱；只有要查即時模型清單時，才需要 API 金鑰。

| 項目 | 值 |
|---|---|
| 網址 | `https://mcp.atptoken.ai/mcp`（Streamable HTTP） |
| 名稱 | `atptoken-api-docs`（取什麼名字都可以） |
| API 金鑰 | 選填。只有 `atptoken_list_models` 會用到。放在環境變數 `ATP_API_KEY`。 |

伺服器有四個工具：

| 工具 | 做什麼 | 金鑰 |
|---|---|---|
| `atptoken_docs` | ATP API 指南：端點、參數、媒體任務、錯誤 | — |
| `atptoken_check_media_request` | 送出影片請求、花點數之前，先檢查 body | — |
| `atptoken_install` | 其他 AI 工具的安裝指令 | — |
| `atptoken_list_models` | 金鑰所屬專案現在能呼叫哪些模型 | 需要 |

加入伺服器不花錢。透過 API 生成圖片、影片或語音才會扣點數，那需要從[主控台](https://atptoken.ai/zh-tw/console/keys/)建立的 `atp-` 金鑰。

## 設定

找到你的工具，每一段都可以直接貼上。加好之後開新的對話或重開工具：MCP 工具在啟動時載入。

### Claude Code

```bash
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
```

`--scope user` 讓它在每個資料夾都能用；不加的話，只有執行指令的那個資料夾有。

要用即時模型清單，加上金鑰標頭。如果之前已經加過不帶金鑰的版本，先移除：

```bash
claude mcp remove --scope user atptoken-api-docs
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp \
  --header "Authorization: Bearer $ATP_API_KEY"
```

### Codex

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

帶金鑰的版本，Codex 每次啟動時從環境變數讀取：

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp --bearer-token-env-var ATP_API_KEY
```

### Claude 應用程式（網頁版與桌面版）

1. 打開 **Customize → Connectors**。
2. 按 **+ Add**，再選 **Add custom connector**。
3. 名稱填 `ATP Token`，網址貼上 `https://mcp.atptoken.ai/mcp`，按 **Continue**。
4. **Authentication** 選 **No sign in**。要用即時模型清單的話，加一個請求標頭 `Authorization`，值是 `Bearer atp-…`。
5. 按 **Add**，然後在新對話裡開啟這個 connector。

Team 與 Enterprise 方案由擁有者在 **Organization settings → Connectors** 加入，成員再按 **Connect**。桌面版的 `claude_desktop_config.json` 不接受網址，請改用 Connectors。

### ChatGPT

1. 在 **Settings → Apps & Connectors → Advanced settings** 打開 **Developer mode**。
2. 回到 **Apps & Connectors**，按 **Create**。
3. 名稱填 `ATP Token`，網址貼上 `https://mcp.atptoken.ai/mcp`，驗證方式選 **No authentication**。
4. 在新對話的工具選單裡開啟它。

選單名稱和哪些方案能加自訂 connector 會不定期調整；找不到 **Developer mode** 時，請查 OpenAI 對你方案的說明。

### Cursor

加進 `~/.cursor/mcp.json`（所有專案）或 `.cursor/mcp.json`（單一專案）：

```json
{
  "mcpServers": {
    "atptoken-api-docs": {
      "url": "https://mcp.atptoken.ai/mcp",
      "headers": { "Authorization": "Bearer ${env:ATP_API_KEY}" }
    }
  }
}
```

不需要即時模型清單的話，拿掉 `headers`。

### Cline

加進 `cline_mcp_settings.json`（MCP Servers → Configure）。一定要寫 `type`；沒寫的話 Cline 會用舊的 SSE 傳輸，連不上：

```json
{
  "mcpServers": {
    "atptoken-api-docs": {
      "type": "streamableHttp",
      "url": "https://mcp.atptoken.ai/mcp"
    }
  }
}
```

### Gemini CLI

```bash
gemini mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
```

### 其他工具

支援遠端 MCP 伺服器的工具，都是填網址 `https://mcp.atptoken.ai/mcp`、傳輸方式選 Streamable HTTP。這個設定常叫做「remote」、「HTTP」或「URL」伺服器。只能跑本機（stdio）伺服器的工具，把指令設成 `npx -y mcp-remote https://mcp.atptoken.ai/mcp` 轉接。

伺服器加進一個工具後，也可以請那個工具呼叫 `atptoken_install`，幫你加到另一個工具。

## 確認可以用

在新的對話裡問你的工具：

```
Use the atptoken_docs tool to open the "start" page and summarize how to call ATP.
```

它回出 ATP 指南的摘要，就代表連上了，這一步不花錢。如果有加金鑰，也可以請它用 `atptoken_list_models` 列出你的模型。

## 疑難排解

| 狀況 | 原因 | 解法 |
|---|---|---|
| 看不到這些工具 | MCP 工具在對話開始時載入 | 開新的對話或重開工具 |
| Claude Code 只有某個資料夾找得到 | 加的時候沒帶 `--scope user` | 移除後帶 `--scope user` 重加 |
| 加帶金鑰的版本時出現 `already exists` | 同名的伺服器已經存在 | 先移除再加 |
| `atptoken_list_models` 說需要金鑰 | 沒帶 `Authorization` 標頭，或環境變數是空的 | 在啟動工具的終端機設定 `ATP_API_KEY`，再重開工具 |
| Cline 連不上 | 沒寫 `type`，它改走 SSE | 加上 `"type": "streamableHttp"` |
| 用瀏覽器打開網址出現錯誤 | 這個網址只回應 MCP 請求（POST），不提供網頁 | 沒有問題，請到工具裡加入 |

## 下一步

- [連接 Coding agents](https://atptoken.ai/zh-tw/docs/agents/) — 用專案金鑰讓 Claude Code、Codex 等 agent 跑在 ATP 模型上。
- [Agent Skills](https://atptoken.ai/zh-tw/docs/agent-skills/) — 同樣的指南做成本機檔案，給不支援 MCP 的工具用。
- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 自己打第一個 API 請求。
