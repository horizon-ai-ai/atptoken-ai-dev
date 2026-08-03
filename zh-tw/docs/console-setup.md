# 設定你的 organization

> Source: https://atptoken.ai/zh-tw/docs/console-setup/

Console 裡的一切都掛在一個四層結構下。你只會建立一次 organization，然後在裡面層層放進 workspace、project 與 key。

| 層級 | 裝什麼 |
|---|---|
| Organization | Billing 與團隊的邊界。分 Personal 或 Team。 |
| Workspace | 一個 credit 容器，把相關的 project 分在一起。 |
| Project | 設定允許的模型清單，並持有一份 credit balance。 |
| API key | 範圍受限的憑證，繼承所屬 project 的模型與 credits。 |

首次登入時，onboarding 會請你輸入 organization 名稱（會自動產生一個選填的小寫 slug）。**Team** organization 可以邀請成員並指派角色；**Personal** organization 為單人使用，並會隱藏 Team 頁。
