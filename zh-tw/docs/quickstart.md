# 快速開始

> Source: https://atptoken.ai/zh-tw/docs/quickstart/

用一把專案 API 金鑰，透過你熟悉的 SDK 呼叫模型，最後在主控台的「請求紀錄」看到這一筆。本頁用 OpenAI 格式示範；Anthropic 與 Gemini 格式見 [Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic/) 與 [Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google/)。

> **開始前需要**
>
> - ATP Token 帳號：[免費註冊](https://atptoken.ai/zh-tw/signup/)
> - 至少 USD 5 的點數（500 點）。沒有點數時請求會回 `402`。
> - 已安裝 Python 或 Node.js，或只用終端機的 curl。

- [自己接 API](#建立帳號並儲值)
  六個步驟：從儲值到在主控台看到第一筆請求。
- [用 coding agent 接](https://atptoken.ai/zh-tw/docs/agents/)
  Claude Code、Codex、Cline 等工具的設定方式。

## 1. 建立帳號並儲值

登入[主控台](https://atptoken.ai/zh-tw/console/)。第一次登入會請你替組織命名。接著到「帳單」按「儲值」，最低 USD 5（500 點），點數不會過期。
如果你用的是團隊組織，儲值會先進入你的個人錢包，請再到「資源」把點數撥給要使用的工作區。詳見 [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/)。

## 2. 建立 API 金鑰

到主控台的「API 金鑰」，按「建立 API 金鑰」。精靈可選擇既有工作區與專案，或在權限允許時建立；接著設定專案可呼叫的模型並產生金鑰。**至少勾選一個模型**，這把金鑰只能呼叫這些模型。
一把金鑰只綁一個專案：能用哪些模型、點數從誰扣，都由那個專案決定。金鑰以 `atp-` 開頭，完整內容只顯示這一次，請立刻複製。

## 3. 安裝 SDK 並設定金鑰

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

Gateway 位址是 `https://api.atptoken.ai/v1`（OpenAI 格式）。金鑰可以放在哪些 header，見 [驗證方式](https://atptoken.ai/zh-tw/docs/auth/)。

## 4. 查詢 OpenAI 格式能呼叫的模型

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

`GET /v1/models` 是 OpenAI 自己的清單端點，所以只列 `/v1/chat/completions` 與 `/v1/responses` 收的 chat 模型——剛好就是下一步能呼叫的。從這份清單挑一個模型 ID。

它不是專案的完整清單：多數 `claude-*` 走 `/v1/messages`，Gemini 在 `/v1beta/models`，媒體與向量模型也不在裡面。要看專案允許的全部模型，用同一把金鑰打 `GET /v1/project/models`。兩份都是空的，才表示專案還沒開通模型：到主控台的「資源」替專案加上模型。

## 5. 送出第一個請求

把 `MODEL_ID` 換成上一步挑的模型 ID。`stream` 一定要明確送：`/v1/chat/completions` 預設是 `true`，跟 OpenAI 官方相反，不送就會收到 SSE 而不是 JSON。

```curl
curl https://api.atptoken.ai/v1/chat/completions \
  -H "Authorization: Bearer $ATP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MODEL_ID",
    "stream": false,
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

```Python
r = client.chat.completions.create(model="MODEL_ID", stream=False, messages=[{"role": "user", "content": "hi"}])
print(r.choices[0].message.content)
print(r.usage)
```

```Node.js
const r = await client.chat.completions.create({ model: "MODEL_ID", stream: false, messages: [{ role: "user", content: "hi" }] });
console.log(r.choices[0].message.content, r.usage);
```

成功時會收到 OpenAI 格式的回應：`choices[0].message.content` 是模型的回覆，`usage` 是這次的 input／output tokens。

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

| 回應 | 代表什麼 | 怎麼處理 |
|---|---|---|
| `401 token_revoked` | 金鑰沒帶到、打錯，或已停用。完全沒送金鑰也是這個 | 先確認 header 真的有送出去、`ATP_API_KEY` 有值且以 `atp-` 開頭；必要時到「API 金鑰」重新建立 |
| `402` | 點數用完 | 到「帳單」儲值；團隊組織再到「資源」撥點數 |
| `403` | 這個模型沒有在專案開通。建立時就被拒，不收費 | 改用第 4 步清單裡的模型 ID，或到「資源」替專案加上模型 |
| `422` | 這個模型不在這個入口服務，訊息會指名正確的入口 | 改打訊息指名的入口、用對應的 SDK——見 [Anthropic SDK](https://atptoken.ai/zh-tw/docs/sdk-anthropic/) 或 [Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google/) |

其他狀態碼見 [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## 6. 在主控台確認這一筆

打開主控台的「總覽」，在「最近請求」按「查看全部」，或直接開 [請求紀錄](https://atptoken.ai/zh-tw/console/logs/)。剛才的請求會排在最上面，顯示模型、狀態與 input／output tokens；扣掉的點數會算進「用量」。

## 下一步

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 三個可以放金鑰的位置，以及 Gemini SDK 的設定。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — tokens 怎麼換算成點數。
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — 每個狀態碼先檢查什麼。
