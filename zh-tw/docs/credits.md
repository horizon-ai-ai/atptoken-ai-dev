# 點數如何運作

> Source: https://atptoken.ai/zh-tw/docs/credits/

用量是用 credits 支付。**1 credit = USD 0.01**（100 credits = USD 1）。隨用隨付（PAYG）的 credits 不會過期（合約承諾的 contract credits 可能帶到期日 — 見「儲值與錢包」）。餘額顯示到小數點後四位；非零但低於此的金額會顯示為 `<0.0001`。

Credits 沿階層往下流 — organization → workspace → project — 一把 key 從其 project 的餘額扣款。每一層都回報相同的四個數字：

| 用詞 | 意義 |
|---|---|
| Available | 這一層可花用或可分配的 credits。 |
| Received | 從上一層收到的 credits 總額。 |
| Allocated | 已往下撥給子 workspace 或 project 的 credits。 |
| Consumed | 實際花在 API 呼叫上的 credits（project 層級）。 |

若某個 project 花得比被分配的還多，會被標為 **In debt**，直到再儲值為止。
