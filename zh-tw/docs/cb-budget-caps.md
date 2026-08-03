# 建立帶預算上限的團隊

> Source: https://atptoken.ai/zh-tw/docs/cb-budget-caps/

沿 organization → workspace → project 樹往下撥 credits，給團隊自己的花費上限。project 只能花被分配到的額度，所以「分配額」就是上限。

## 1. 建立 Team organization

首次登入（或從 org 切換器）建立一個 **Team** organization — 它能邀請成員並指派角色，這點和 Personal org 不同。見 [設定你的 organization](https://atptoken.ai/zh-tw/docs/console-setup/)。

## 2. 建立 workspace 與 project

在 Resources 建一個 workspace 把相關工作分組，再在裡面建 project。選擇 project 的 **allowed models** — 只有這些能被它的 key 呼叫。見 [Workspaces 與 projects](https://atptoken.ai/zh-tw/docs/resources/)。

## 3. 撥預算（上限）

Credits 沿樹往下流：organization → workspace → project。撥一筆固定金額給 project — 這個金額就是它的天花板。花超過分配額時，project 會被標為 **In debt**，直到再儲值。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## 4. 加人並給對的角色

邀請夥伴，在 workspace 或 project 層級指派 Owner / Admin / Member，讓他們能用預算但不能搬動它。見 [團隊與角色](https://atptoken.ai/zh-tw/docs/team/)。

## 5. 盯著消耗

Usage 頁顯示每一層的 Allocated 對 Consumed，讓你在 project 快到上限前就看得到。見 [追蹤消耗](https://atptoken.ai/zh-tw/docs/spend/)。

> **團隊額度來自分配，不是錢包**
>
> 在 team organization 裡，key 花的是 org 被分配到的 credits — 不是個人錢包。儲值是充進你的個人帳戶；再從那裡於 Resources 撥給 org。見 [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/)。

「分配額即上限」的設計理由見 [有效的 AI 花費上限](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work/)。
