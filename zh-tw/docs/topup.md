# 儲值與錢包

> Source: https://atptoken.ai/zh-tw/docs/topup/

你的隨用隨付（PAYG）錢包透過 Billing 頁的 Stripe 儲值。最低儲值為 **USD 5**，且每個級距一律以 100 credits 兌 1 美元換算：

| 方案 | 價格 | Credits |
|---|---|---|
| Starter | USD 5 | 500 |
| Standard | USD 50 | 5,000 |
| Pro | USD 200 | 20,000 |
| Scale | USD 1,000 | 100,000 |

每次儲值都會記進 Billing 歷史（日期、金額、加入的 credits、儲值後餘額、狀態）。**儲值與 credits 不可退款。** Credits 以單一 Wallet 餘額呈現。企業帳號另可持有承諾的 **contract credits**（帶到期日）；這些會計入該餘額，並列在 Billing 頁上。

> **Personal 與 Team organization 的差別**
>
> 儲值是充進你的 **個人帳戶**。在 **personal organization** 中，這份餘額就是你的 key 直接花用的來源。若是 **team organization**，要先把 credits 分配給它（Console → Resources）— team org 裡的 key 花的是 org 被分配到的 credits，不是個人錢包。
