# 加入 ATP MCP 服务器

> Source: https://atptoken.ai/zh-cn/docs/mcp/

把 `https://mcp.atptoken.ai/mcp` 加进 Claude、ChatGPT、Cursor、Codex 等 AI 工具，让它能查询并检查 ATP API 的调用方式。不需要密钥。工具照样用它原本的模型；这个服务器只提供 ATP 的 API 指南和检查工具，让它第一次就写对请求。

## 开始之前

需要网址、服务器名称；只有要查即时模型清单时，才需要 API 密钥。

| 项目 | 值 |
|---|---|
| 网址 | `https://mcp.atptoken.ai/mcp`（Streamable HTTP） |
| 名称 | `atptoken-api-docs`（取什么名字都可以） |
| API 密钥 | 选填。只有 `atptoken_list_models` 会用到。放在环境变量 `ATP_API_KEY`。 |

服务器有四个工具：

| 工具 | 做什么 | 密钥 |
|---|---|---|
| `atptoken_docs` | ATP API 指南：端点、参数、媒体任务、错误 | — |
| `atptoken_check_media_request` | 送出视频请求、花点数之前，先检查 body | — |
| `atptoken_install` | 其他 AI 工具的安装命令 | — |
| `atptoken_list_models` | 密钥所属项目现在能调用哪些模型 | 需要 |

加入服务器不花钱。通过 API 生成图片、视频或语音才会扣点数，那需要从[控制台](https://atptoken.ai/zh-cn/console/keys/)建立的 `atp-` 密钥。

## 配置

找到你的工具，每一段都可以直接贴上。加好之后开新的对话或重开工具：MCP 工具在启动时载入。

### Claude Code

```bash
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp
```

`--scope user` 让它在每个数据夹都能用；不加的话，只有执行命令的那个数据夹有。

要用即时模型清单，加上密钥请求头。如果之前已经加过不带密钥的版本，先移除：

```bash
claude mcp remove --scope user atptoken-api-docs
claude mcp add --transport http --scope user atptoken-api-docs https://mcp.atptoken.ai/mcp \
  --header "Authorization: Bearer $ATP_API_KEY"
```

### Codex

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp
```

带密钥的版本，Codex 每次启动时从环境变量读取：

```bash
codex mcp add atptoken-api-docs --url https://mcp.atptoken.ai/mcp --bearer-token-env-var ATP_API_KEY
```

### Claude 应用程式（网页版与桌面版）

1. 打开 **Customize → Connectors**。
2. 按 **+ Add**，再选 **Add custom connector**。
3. 名称填 `ATP Token`，网址贴上 `https://mcp.atptoken.ai/mcp`，按 **Continue**。
4. **Authentication** 选 **No sign in**。要用即时模型清单的话，加一个请求请求头 `Authorization`，值是 `Bearer atp-…`。
5. 按 **Add**，然后在新对话里打开这个 connector。

Team 与 Enterprise 方案由拥有者在 **Organization settings → Connectors** 加入，成员再按 **Connect**。桌面版的 `claude_desktop_config.json` 不接受网址，请改用 Connectors。

### ChatGPT

1. 在 **Settings → Apps & Connectors → Advanced settings** 打开 **Developer mode**。
2. 回到 **Apps & Connectors**，按 **Create**。
3. 名称填 `ATP Token`，网址贴上 `https://mcp.atptoken.ai/mcp`，验证方式选 **No authentication**。
4. 在新对话的工具菜单里打开它。

菜单名称和哪些方案能加自订 connector 会不定期调整；找不到 **Developer mode** 时，请查 OpenAI 对你方案的说明。

### Cursor

加进 `~/.cursor/mcp.json`（所有项目）或 `.cursor/mcp.json`（单一项目）：

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

不需要即时模型清单的话，拿掉 `headers`。

### Cline

加进 `cline_mcp_settings.json`（MCP Servers → Configure）。一定要写 `type`；没写的话 Cline 会用旧的 SSE 传输，连不上：

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

支持远程 MCP 服务器的工具，都是填网址 `https://mcp.atptoken.ai/mcp`、传输方式选 Streamable HTTP。这个设置常叫做「remote」、「HTTP」或「URL」服务器。只能跑本地（stdio）服务器的工具，把命令设成 `npx -y mcp-remote https://mcp.atptoken.ai/mcp` 转接。

服务器加进一个工具后，也可以请那个工具调用 `atptoken_install`，帮你加到另一个工具。

## 确认可以用

在新的对话里问你的工具：

```
Use the atptoken_docs tool to open the "start" page and summarize how to call ATP.
```

它回出 ATP 指南的摘要，就代表连上了，这一步不花钱。如果有加密钥，也可以请它用 `atptoken_list_models` 列出你的模型。

## 故障排除

| 状况 | 原因 | 解法 |
|---|---|---|
| 看不到这些工具 | MCP 工具在对话开始时载入 | 开新的对话或重开工具 |
| Claude Code 只有某个数据夹找得到 | 加的时候没带 `--scope user` | 移除后带 `--scope user` 重加 |
| 加带密钥的版本时出现 `already exists` | 同名的服务器已经存在 | 先移除再加 |
| `atptoken_list_models` 说需要密钥 | 没带 `Authorization` 请求头，或环境变量是空的 | 在启动工具的终端设置 `ATP_API_KEY`，再重开工具 |
| Cline 连不上 | 没写 `type`，它改走 SSE | 加上 `"type": "streamableHttp"` |
| 用浏览器打开网址出现错误 | 这个网址只回应 MCP 请求（POST），不提供网页 | 没有问题，请到工具里加入 |

## 下一步

- [连接 Coding agents](https://atptoken.ai/zh-cn/docs/agents/) — 用项目密钥让 Claude Code、Codex 等 agent 跑在 ATP 模型上。
- [Agent Skills](https://atptoken.ai/zh-cn/docs/agent-skills/) — 同样的指南做成本地文件，给不支持 MCP 的工具用。
- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 自己打第一个 API 请求。
