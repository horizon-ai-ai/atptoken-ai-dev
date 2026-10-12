# 從 OpenAI 遷移

> Source: https://atptoken.ai/zh-tw/docs/cb-migrate-openai/

把既有的 OpenAI 整合搬到 ATP，通常只是兩行改動：把 base URL 換成 Gateway、API 金鑰換成專案（project）金鑰。你的 request 與 response 結構完全不變。

## 1. 拿一把專案金鑰

在主控台建立專案 API 金鑰。它以 `atp-` 開頭，繼承所屬專案的允許模型與點數。見 [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/)。

## 2. 換掉 base URL 與金鑰

把 OpenAI SDK 指向 Gateway、用 `atp-` 金鑰。其餘——messages、tools、串流——都不變。

```
from openai import OpenAI

# Before: client = OpenAI(api_key="sk-...")
client = OpenAI(base_url="https://api.atptoken.ai/v1", api_key="atp-...")

r = client.chat.completions.create(
    model="<model from GET /v1/models>",
    messages=[{"role": "user", "content": "hi"}],
)
print(r.choices[0].message.content)
```

## 3. 對應你的模型 ID

ATP 的模型 ID 來自 [GET /v1/models](https://atptoken.ai/zh-tw/docs/models/)，不是 OpenAI 的型錄。列出後把 `model` 欄位改成你專案已啟用的 id——未啟用的模型會回 `403`。

## 4. 測試並確認

送一個請求，再看主控台：它會出現在請求紀錄（含 input / output tokens），花掉的點數顯示在用量頁。見 [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/)。

> **結構一樣，帳單合一**
>
> 因為 OpenAI wire format 原樣通過，你 app 裡解析 response 的部分不用改。現在跨所有模型的用量都以點數計量。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## 下一步

- [OpenAI SDK](https://atptoken.ai/zh-tw/docs/sdk-openai/) — 用 OpenAI SDK 接 Gateway 的完整設定。
- [/v1/chat/completions](https://atptoken.ai/zh-tw/docs/chat/) — 遷移後的呼叫打的端點。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 用量如何以點數計量。
