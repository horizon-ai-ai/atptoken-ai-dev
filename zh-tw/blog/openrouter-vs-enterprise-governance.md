# OpenRouter 替代方案（團隊版）：費用、預算與模型控管比較（2026）

> 來源: https://atptoken.ai/zh-tw/blog/openrouter-vs-enterprise-governance/
> 發表於: 2026-08-26 · 作者: hung-chien (AI 成長與品牌經理)

OpenRouter 替代方案比較：OpenRouter 怎麼收費、預算與模型白名單怎麼運作，以及 LiteLLM、Vercel AI Gateway、ATP Token 各自適合什麼情況。

## 重點摘要

- 截至 2026 年 10 月，OpenRouter 在按量付費方案購買點數時，刷卡收 5.5% 平台費（Business 方案 8%，最低 0.80 美元），模型 token 價格則照供應商原價計算。
- OpenRouter 已經有組織、工作區與 guardrails，可以對成員或金鑰設預算與模型白名單。團隊換掉它的理由在別處：必須自架、計費方式、以專案為單位的預付預算，或需要的 SDK 格式與模型。
- 必須自架選 LiteLLM，已經部署在 Vercel 選 Vercel AI Gateway；若希望每個專案有預付點數額度與自己的模型白名單，涵蓋文字、圖像與影片模型，選 ATP Token。

OpenRouter 替代方案，指的是當 OpenRouter 的計費、控管或模型目錄不符合團隊的採購與治理方式時，另一種「用一個 API 呼叫多家模型」的做法。本文整理截至 2026 年 10 月 OpenRouter 的收費與控管功能，用同一份清單比較 LiteLLM、Vercel AI Gateway 與 ATP Token，最後附上遷移程式碼。

## 快速比較

| | OpenRouter | LiteLLM | Vercel AI Gateway | ATP Token |
|---|---|---|---|---|
| 部署方式 | 代管 | 自架、開源 | 代管 | 代管 |
| 你付的錢 | 供應商價格＋購買點數的手續費 | 自家供應商帳單＋主機成本 | 供應商定價，可能另有金流手續費 | 預付點數，依各模型定價扣抵 |
| 預算掛在哪 | API 金鑰、成員；工作區需 Enterprise | 金鑰、使用者、團隊、客戶 | 團隊、專案、金鑰、成員 | 組織 → 工作區之下的專案額度 |
| 到達上限時 | 拒絕請求 | 拒絕請求 | HTTP 402（軟上限） | 專案餘額用完回傳 HTTP 402 |
| 模型白名單 | 對成員或金鑰設 guardrails | 依金鑰或團隊設 access group | 供應商白名單（付費加購） | 每個專案一份，在送到供應商前檢查（403） |
| API 格式 | OpenAI 相容、Anthropic Messages | OpenAI 相容 | AI SDK、OpenAI Chat 與 Responses、Anthropic | OpenAI、Anthropic、Gemini |
| 模型目錄 | 500+ 模型、80+ 供應商 | 你設定的任何供應商 | 文字、圖像、影片、語音、嵌入 | 70+ 個文字、圖像、影片、音訊與嵌入模型 |

資料來源：[OpenRouter 定價](https://openrouter.ai/pricing)、[OpenRouter guardrails](https://openrouter.ai/docs/guides/features/guardrails)、[LiteLLM 預算](https://docs.litellm.ai/docs/proxy/users)、[Vercel AI Gateway 預算](https://vercel.com/docs/ai-gateway/observability-and-spend/budgets)、[ATP 運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)。

## OpenRouter 怎麼收費（截至 2026 年 10 月）

OpenRouter 不在 token 價格上加價，官方說法是照供應商價格轉嫁，費用收在購買點數時（[FAQ](https://openrouter.ai/docs/faq)）：

- Standard（按量付費）：刷卡 5.5%，最低 0.80 美元；加密貨幣 5%。
- Business：8%。Enterprise：另議。
- 自帶供應商金鑰（BYOK）：Standard 與 Business 每月前 25,000 美元定價用量免費，超過收 5%。

舉兩個例子。在 Standard 刷卡買 1,000 美元點數，實付 1,055 美元。買 10 美元則實付 10.80 美元，因為最低 0.80 美元高於 5.5%。

財務要注意兩條條款：OpenRouter 保留在購買一年後讓未使用點數失效的權利；未使用點數的退款必須在 24 小時內申請。開立發票（invoicing）只列在 Enterprise 方案。

## OpenRouter 已經能替團隊做的事

有些比較文章（包括本文的舊版）把 OpenRouter 描述成沒有團隊控管的開發者錢包，這已經過時。

- 組織共用一個點數池，只有管理員能購買點數、調整帳務、供應商與隱私設定。
- [工作區](https://openrouter.ai/docs/guides/features/workspaces)可以把 API 金鑰、路由預設、guardrails 與觀測分開，例如分成測試與正式環境。
- [Guardrails](https://openrouter.ai/docs/guides/features/guardrails) 可套在成員或金鑰上，組合按日、週、月重置的美元預算、模型白名單、供應商白名單、零資料保留規則，以及提示注入或個資過濾。多條同時適用時，以最嚴格的為準。
- 每把 API 金鑰都能設自己的點數上限，任何方案都可以。
- 所有方案都有活動紀錄與匯出，可依模型、金鑰或成員分組。
- Claude Code 可以接 OpenRouter 的 Anthropic 相容端點（[設定說明](https://openrouter.ai/docs/guides/guides/claude-code-integration)）。

如果這些控管已經夠用，手續費也能接受，繼續用 OpenRouter 是合理的。

## 團隊為什麼找替代方案

常見原因，每一條都對應文件上查得到的差異：

1. 閘道必須跑在公司網路內，或流量只能送到公司自己持有的供應商帳號。
2. 財務希望預算綁在產品線或成本中心。OpenRouter 在 Enterprise 以下，預算掛在成員與金鑰上；工作區預算要 Enterprise。
3. 財務希望用不會過期的預付點數，事先撥給每個專案。
4. 部分應用用的是 Google GenAI SDK，團隊希望閘道直接接受這個格式，不必改寫。

下面每個替代方案各自回應其中幾項。

## 逐一看替代方案

### LiteLLM：自架 proxy

- 適合：閘道必須放在自家雲端或 VPC，而且已經有供應商帳號的團隊。
- 費用：開源 proxy 免費；你直接付供應商帳單，加上維運成本。部分功能（例如使用者與金鑰層級的「依模型」預算）需要 Enterprise 授權。
- 控管：可依金鑰、使用者、團隊與客戶設預算，重置週期如 `30d`；模型權限用 access group 管理。
- 要注意：可用性、資料庫、升級與資安審查都歸你。Anthropic 的 Claude Code 文件提到有企業用 LiteLLM 依金鑰追蹤花費，也註明它與 Anthropic 無關、未經其稽核（[來源](https://code.claude.com/docs/en/costs)）。

### Vercel AI Gateway：代管，照供應商定價

- 適合：已經部署在 Vercel 的團隊，或想要代管閘道、又不想在 token 上付平台費的人。
- 費用：token 不加價、不收平台費；可能有金流手續費；Enterprise 可開發票（[定價](https://vercel.com/docs/ai-gateway/pricing)）。
- 控管：可對團隊、專案、API 金鑰或成員設預算，按日、週、月或不重置；超過回傳 HTTP 402；在 50%、75%、100% 寄信通知。
- 要注意：Vercel 自己說預算是軟上限，跨過上限的那一筆請求仍會完成。用自帶供應商金鑰的花費不計入預算。整個團隊層級的供應商白名單，每 1,000 筆請求收 0.10 美元。

### ATP Token：專案預付額度＋每個專案自己的模型白名單

- 適合：好幾個團隊共用一筆 AI 預算，財務希望每個專案先撥款、並只能用審核過的模型。
- 費用：依輸入與輸出 token、按各模型定價計量，從點數扣抵。1 點 = 0.01 美元，儲值 5 美元起，按量付費的點數不會過期（[點數](https://atptoken.ai/zh-tw/docs/credits)、[儲值](https://atptoken.ai/zh-tw/docs/topup)、[定價](https://atptoken.ai/zh-tw/pricing)）。
- 控管：點數由組織往下撥到工作區、再到專案，專案只能花被撥到的額度，用完回傳 402。每個專案有允許的模型清單，呼叫清單外的模型會在送到供應商之前回傳 403（[運作方式](https://atptoken.ai/zh-tw/docs/how-it-works)）。
- 格式：OpenAI、Anthropic、Google GenAI 官方 SDK 都能原樣使用，只換 base URL 與金鑰（[OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai)、[Google GenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-google)）。
- 要注意：模型目錄比 OpenRouter 小（11 家供應商、70+ 個模型，對比 500+）。點數不可退款。請求紀錄保留 7 天，月度檢討需要的資料請先匯出。

Portkey 與 Helicone 也常出現在「OpenRouter 替代方案」清單裡，放在 [LLM 閘道比較](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026)一起談。

## OpenRouter 與 LiteLLM 比較

差別在於誰來營運閘道。

| | OpenRouter | LiteLLM |
|---|---|---|
| 誰營運 | OpenRouter | 你自己 |
| 供應商帳號 | OpenRouter 的，或透過 BYOK 用你的 | 你的 |
| token 之外的成本 | 購買點數的手續費；BYOK 每月超過 2.5 萬美元收費 | 主機與維護人力 |
| 送出第一筆請求要多久 | 幾分鐘 | 幾小時到幾天，取決於內部基礎設施審查 |

五個人的團隊在試模型，通常從 OpenRouter 開始。流量不能經過第三方閘道的銀行，通常最後會用 LiteLLM。

## 怎麼選

| 情境 | 合理的選擇 |
|---|---|
| 一位工程師這週要比較 30 個模型 | OpenRouter |
| 閘道必須跑在自家 VPC | LiteLLM |
| 應用部署在 Vercel，想依 Vercel 專案設預算 | Vercel AI Gateway |
| 四個產品團隊共用一筆預算，財務要每個團隊先撥款、餘額用完就停 | ATP Token |
| 應用分散在 OpenAI、Anthropic、Google GenAI 三種 SDK，希望各自不改 | ATP Token |
| 研究需要長尾模型，正式環境需要固定白名單 | 研究用 OpenRouter，正式環境用有治理的閘道 |

## 把 OpenRouter 整合搬到 ATP Token

如果你的程式用 OpenAI SDK 呼叫 OpenRouter，搬家只要換 base URL、金鑰與模型 id。

1. 在主控台建立專案，勾選允許的模型，例如 [claude-sonnet-4-6](https://atptoken.ai/zh-tw/models/claude-sonnet-4-6/) 與 [deepseek-v4-flash](https://atptoken.ai/zh-tw/models/deepseek-v4-flash/)（[工作區與專案](https://atptoken.ai/zh-tw/docs/resources)）。
2. 撥點數給專案，這個金額就是它的上限（[預算上限設定](https://atptoken.ai/zh-tw/docs/cb-budget-caps)）。
3. 為專案建立金鑰，開頭是 `atp-`，只顯示一次（[管理金鑰](https://atptoken.ai/zh-tw/docs/console-keys)）。
4. 改 client 與模型 id。OpenRouter 的 id 帶供應商前綴（`vendor/model`）；ATP 的 id 以 `GET /v1/models` 回傳的為準。

```
from openai import OpenAI

# 原本：OpenAI(base_url="https://openrouter.ai/api/v1", api_key="sk-or-...")
client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")

r = client.chat.completions.create(
    model="claude-sonnet-4-6",
    messages=[{"role": "user", "content": "用兩行摘要這張工單。"}],
)
print(r.choices[0].message.content)
```

5. 送一筆測試請求，確認它出現在請求紀錄裡，並有輸入與輸出 token（[用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring)）。

Claude Code 也是同樣做法，設定四個環境變數即可（[在 ATP 上跑 Claude Code](https://atptoken.ai/zh-tw/docs/cb-claude-code)）。

[從快速開始上手](https://atptoken.ai/zh-tw/docs/quickstart)

## 延伸閱讀

- [LLM 閘道比較 2026](https://atptoken.ai/zh-tw/blog/ai-gateway-comparison-2026)
- [AI API 花費上限比較](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work)
- [OpenAI API 與 OpenAI 相容閘道](https://atptoken.ai/zh-tw/blog/openai-api-vs-enterprise-ai-gateway)

## 常見問題

### 最好的 OpenRouter 替代方案是哪一個？

看你想改變什麼。閘道必須跑在自家基礎設施時，常見選擇是 LiteLLM；應用已經部署在 Vercel，選 Vercel AI Gateway；財務希望每個專案先撥預付點數、並各自限定模型時，選 ATP Token。

### OpenRouter 怎麼收費？

截至 2026 年 10 月，OpenRouter 的 token 價格照供應商原價，另在購買點數時收平台費：按量付費的 Standard 方案刷卡 5.5%、最低 0.80 美元，Business 方案 8%，加密貨幣 5%。自帶供應商金鑰（BYOK）每月前 25,000 美元定價用量免費，超過收 5%。

### OpenRouter 可以設花費上限嗎？

可以。每把 API 金鑰都能設點數上限，按日、週或月重置；組織管理員也能用 guardrails 對成員或金鑰設預算、模型白名單與供應商白名單。工作區層級的預算屬於 Enterprise 方案。

### OpenRouter 和 LiteLLM 差在哪？

OpenRouter 是代管服務，你向它購買點數；LiteLLM 是開源 proxy，要自己部署並接上自家的供應商帳號。用 LiteLLM 沒有平台費，但主機、升級與資安審查都要自己負責。

### OpenRouter 和 ATP Token 可以一起用嗎？

可以。常見分工是用 OpenRouter 的大型模型目錄做評估，正式流量放在 ATP Token 的專案上，每個服務各有自己的金鑰、白名單與點數額度。

---

Tags: OpenRouter 替代方案, LLM 閘道, ATP
