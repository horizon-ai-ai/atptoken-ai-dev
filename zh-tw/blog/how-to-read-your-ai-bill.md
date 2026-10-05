# LLM token 成本怎麼算？計算公式、5 個模型實算與 AI 帳單讀法（2026）

> 來源: https://atptoken.ai/zh-tw/blog/how-to-read-your-ai-bill/
> 發表於: 2026-07-21 · 作者: hung-chien (AI 成長與品牌經理)

LLM token 成本怎麼算：單次請求計算公式、同一請求在 5 個模型上的實際花費、輸入與輸出價差、快取與推理 token，以及 AI 帳單該看哪些欄位。

## 重點摘要

- 單次請求的 LLM token 成本 = 輸入 token × 輸入單價 + 輸出 token × 輸出單價，單價以每 100 萬 token 計。claude-sonnet-4-6（$3 / $15）處理 1,284 個輸入與 412 個輸出 token，成本是 $0.010032，也就是 1.0032 點 ATP 點數。
- 同一筆請求在 gpt-5.5 上是 $0.01878，在 qwen-3-7-flash 上是 $0.00009208，相差 204 倍。模型選擇對帳單的影響，大過其他任何單一設定。
- 常見模型的輸出單價是輸入的 2 到 6 倍，推理 token 也按輸出計費。讀帳單時先按專案與模型看，再趁 7 天的請求紀錄還在時追到單筆請求。

LLM token 成本，是模型讀進（輸入）與寫出（輸出）的 token 所產生的費用，兩者各自以每 100 萬 token 的單價計算。這篇整理計算公式，拿一筆真實大小的請求在五個模型上實算，說明輸出、快取與推理 token 怎麼改變算式，也列出月帳對不上時該看哪些欄位。

以下單價都是各模型頁上的 ATP 牌價，截至 2026 年 10 月。引用的原廠單價都附上原廠定價頁連結。

## token 成本計算公式

任何按 token 計價的 API，單次請求的成本都來自同樣三步：

1. 輸入成本 = 輸入 token × 輸入單價 ÷ 1,000,000
2. 輸出成本 = 輸出 token × 輸出單價 ÷ 1,000,000
3. 請求成本 = 輸入成本 + 輸出成本

在 ATP Token 上，這筆費用會以點數從專案餘額扣除，[1 點 = 0.01 美元](https://atptoken.ai/zh-tw/docs/credits)。點數 = 美元成本 × 100。

### 實算：一則客服機器人回覆

客服機器人送出 1,284 token 的提示（系統提示、檢索到的說明中心段落、客戶訊息）給 claude-sonnet-4-6，單價為每 100 萬 token 輸入 $3、輸出 $15，拿回 412 token 的回答。

- 輸入：1,284 × $3 ÷ 1,000,000 = $0.003852
- 輸出：412 × $15 ÷ 1,000,000 = $0.00618
- 合計：$0.010032 = 1.0032 點

每月 10 萬則回覆就是 $1,003.20。這筆請求裡輸出只佔 token 數的 24%，卻佔成本的 61.6%。

### 可以直接貼上的 token 成本計算器

SDK 回傳的內容本來就帶有 token 數。OpenAI 格式的欄位是 `usage.prompt_tokens` 與 `usage.completion_tokens`，Anthropic 格式則是 `usage.input_tokens` 與 `usage.output_tokens`。

```python
RATES = {  # 每 100 萬 token 美元：(輸入, 輸出)，ATP 牌價
    "gpt-5.5": (5.00, 30.00),
    "claude-sonnet-4-6": (3.00, 15.00),
    "gemini-3-5-flash": (1.50, 9.00),
    "deepseek-v4-flash": (0.20, 0.40),
    "qwen-3-7-flash": (0.03, 0.13),
}

def token_cost(model, input_tokens, output_tokens):
    rate_in, rate_out = RATES[model]
    usd = (input_tokens * rate_in + output_tokens * rate_out) / 1_000_000
    return usd, usd * 100  # (美元, ATP 點數)

print(token_cost("claude-sonnet-4-6", 1284, 412))  # 約 (0.010032, 1.0032)
```

## 同一筆請求放到 5 個模型上

把輸入 1,284、輸出 412 的請求放到五個模型上計價。qwen-3-7-flash 採用提示在 32K token 以內的級距單價。

| 模型 | ATP 牌價（每 100 萬 token 輸入 / 輸出） | 單次成本 | 單次點數 | 每 10 萬次 |
|---|---|---|---|---|
| [gpt-5.5](https://atptoken.ai/zh-tw/models/gpt-5.5/) | $5 / $30 | $0.01878 | 1.878 | $1,878.00 |
| [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/) | $3 / $15 | $0.010032 | 1.0032 | $1,003.20 |
| [gemini-3-5-flash](https://atptoken.ai/zh-tw/models/gemini-3-5-flash/) | $1.50 / $9 | $0.005634 | 0.5634 | $563.40 |
| [deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/) | $0.20 / $0.40 | $0.0004216 | 0.04216 | $42.16 |
| [qwen-3-7-flash](https://atptoken.ai/zh-tw/models/qwen-3-7-flash/) | $0.03 / $0.13 | $0.00009208 | 0.009208 | $9.21 |

這張表把 token 數固定，只比較單價。實際上每家的 tokenizer 切字方式不同，token 數也會不同。Anthropic 指出 Claude 4.7 以後模型的 tokenizer，同樣文字大約會多產生 30% 的 token（[Anthropic 定價](https://platform.claude.com/docs/en/about-claude/pricing)），所以同一段 1,284 token 的提示，在 4.7 以後的模型上會接近 1,670 token。比較模型前先用自己的提示實測，品質也要並排看，例如 [DeepSeek vs Claude 比較](https://atptoken.ai/zh-tw/compare/deepseek-vs-claude/)。

## 為什麼輸出 token 主導帳單

輸出與輸入的單價比，決定錢花在哪裡。

| 模型 | 輸出單價 ÷ 輸入單價 | 上例中輸出佔成本比例 |
|---|---|---|
| gpt-5.5 | 6 倍 | 65.8% |
| claude-sonnet-4-6 | 5 倍 | 61.6% |
| deepseek-v4-flash | 2 倍 | 39.1% |

實務上有兩個影響。在 5 倍或 6 倍的模型上，縮短回答比縮短提示更划算：在 claude-sonnet-4-6 上少 200 個輸出 token 省 $0.003，等於少 1,000 個輸入 token。另外，大量生成文字的工作（起草、產生程式碼、寫報告），估價時主要看預期的輸出長度。

## 快取輸入與推理 token

原廠價目表上有兩種 token，第一次讀帳單的人最容易卡住。

### 快取輸入是原廠的計價功能

部分原廠對從快取命中的重複提示前綴另訂較低單價。OpenAI 列出 GPT-5.5 的快取輸入為每 100 萬 token $0.50，一般輸入是 $5（[OpenAI 定價](https://developers.openai.com/api/docs/pricing)）。Anthropic 多數模型的快取讀取是基本輸入單價的 0.1 倍，快取寫入為 1.25 倍（5 分鐘）或 2 倍（1 小時）（[Anthropic 定價](https://platform.claude.com/docs/en/about-claude/pricing)）。這些是依各原廠快取規則直接呼叫時的原廠單價。ATP Token 依[計價模式](https://atptoken.ai/zh-tw/docs/pricing-model)以輸入與輸出 token 計費，所以 ATP 預算請用輸入與輸出牌價來估。

### 推理 token 按輸出計費

推理模型回答前會先思考，這些看不見的 token 也要付費。OpenAI 寫明推理 token 以輸出 token 計費（[OpenAI 推理指南](https://developers.openai.com/api/docs/guides/reasoning)），Anthropic 也把 extended thinking 的 token 按輸出計費（[Claude Code 成本](https://code.claude.com/docs/en/costs)）。如果上面那則客服回覆在 claude-sonnet-4-6 上用了 1,500 個 thinking token，就多出 1,500 × $15 ÷ 1,000,000 = $0.0225，單次成本從 $0.010032 變成 $0.032532，約 3.2 倍。

推理預算也能解釋一種令人困惑的紀錄：回傳 `200` 但內容是空的。`max_tokens` 設太低時，模型把預算全用在思考，沒有產出文字。在 ATP 上這種請求通常顯示零用量、不扣點數；解法是調高 `max_tokens`（[錯誤代碼](https://atptoken.ai/zh-tw/docs/errors)）。

## 單筆請求紀錄告訴你什麼

月總額只說得出花了多少。單筆請求紀錄說得出是哪個專案、哪個模型、用了多少 token。下面是示意用的紀錄，列出計算單次成本需要的欄位，並非 ATP 實際的紀錄格式。

```json
{
  "request_id": "req_example_01",
  "project": "support-bot-prod",
  "model": "claude-sonnet-4-6",
  "input_tokens": 1284,
  "output_tokens": 412,
  "cost_usd": 0.010032,
  "cost_credits": 1.0032
}
```

在 ATP Token 裡，這些資訊分在三個地方：

- 請求紀錄，每次呼叫一列：時間、範圍（工作區與專案）、模型、端點、HTTP 狀態、供應商結果、輸入與輸出 token、計費狀態與請求 ID。可依時間範圍、範圍、模型、狀態或請求 ID 篩選（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。保留 7 天，費用異常要在一週內查。
- 帳務事件，也就是逐筆計費帳本，主控台以 90 天呈現，可依模型、金鑰、計費狀態或請求 ID 篩選（[帳務 API](https://atptoken.ai/zh-tw/docs/console-api-billing)）。計費以這份帳本為準。
- 用量頁，依模型與 API 金鑰彙總一段期間的點數與 token。

每個回應也都帶有 `x-request-id` 標頭，工程師可以把應用程式日誌裡的某次呼叫，對到主控台裡的那一列。

## 三種帳單異常與查法

### 某一週費用突然跳升

用量頁按 API 金鑰排序。如果金鑰和專案一對一，跳升馬上落到某個負責人身上。接著在請求紀錄裡篩選該專案，比較跳升前後每次請求的 token 數。輸入從約 1,300 漲到 13,000 token，通常是有人開始每一輪都送整份文件。

### 單價沒錯，總額卻對不上

檢查模型組合。把 10 萬則客服回覆中的 20% 從 claude-sonnet-4-6 改到 gpt-5.5，流量不變，那個月就從 $1,003.20 變成 $1,178.16。

### 請求成功卻沒有文字

找推理模型上輸出 token 為零的 `200` 紀錄，把 `max_tokens` 調到足以涵蓋思考加上回答。

## 在 ATP Token 上怎麼設定

1. 每個服務、每個環境各建一個專案，各配一把 `atp-` 金鑰，用量頁「依金鑰」就等於「依負責人」。
2. 為每個專案分配點數。分配額就是專案的上限，餘額用完時呼叫會回傳 `402`（[預算上限設定](https://atptoken.ai/zh-tw/docs/cb-budget-caps)）。專案也可以開啟自動儲值，設定觸發門檻與每月上限。
3. 記錄每個回應的 `usage` 與模型 ID，每週依專案跑一次上面的計算器。
4. 月底以帳務事件對帳，7 天內的細節用請求紀錄追查。

[從快速開始接入](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [企業 AI 成本管理與 LLM 成本優化指南](https://atptoken.ai/zh-tw/blog/enterprise-ai-cost-management-guide)
- [上線後 AI 帳單為什麼會暴增](https://atptoken.ai/zh-tw/blog/why-ai-bills-explode-after-go-live)
- [什麼是 agent tax？](https://atptoken.ai/zh-tw/blog/what-is-the-agent-tax)

## 常見問題

### LLM token 成本怎麼計算？

把輸入 token 乘上模型的輸入單價、輸出 token 乘上輸出單價，因為單價以每 100 萬 token 計，所以各自再除以 1,000,000，最後相加。例如 claude-sonnet-4-6（$3 / $15）處理 1,284 個輸入與 412 個輸出 token，成本是 $0.003852 + $0.00618 = $0.010032。

### 為什麼輸出 token 比輸入 token 貴？

供應商對生成的定價高於讀取。以 ATP 牌價來看，gpt-5.5 的輸出是輸入的 6 倍、claude-sonnet-4-6 是 5 倍、deepseek-v4-flash 是 2 倍，所以提示短、回答長的請求，成本大多落在輸出。

### 推理 token 要付費嗎？

要。OpenAI 與 Anthropic 都把推理（thinking）token 按輸出 token 計費，即使它不會出現在回答裡。在 claude-sonnet-4-6 上多用 1,500 個 thinking token，單次請求就多 $0.0225。

### 在 ATP Token 上一次請求會扣多少點數？

1 點 = 0.01 美元，所以點數 = 美元成本 × 100。$0.010032 的請求扣 1.0032 點。餘額顯示到小數點後四位。

### ATP 的請求紀錄保留多久？

請求紀錄保留 7 天，用途是除錯。計費以帳務事件（billing events）為準，主控台以 90 天帳本呈現。

---

Tags: LLM token 成本, AI 帳務, ATP
