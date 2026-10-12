# 建立帶預算上限的團隊

> Source: https://atptoken.ai/zh-tw/docs/cb-budget-caps/

沿組織 → 工作區 → 專案（project）樹往下撥點數，給團隊自己的花費上限。專案只能花被分配到的額度，所以「分配額」就是上限。

## 1. 建立 Team 組織

首次登入（或從 org 切換器）建立一個 **Team** 組織——它能邀請成員並指派角色，這點和 Personal org 不同。見 [設定你的組織](https://atptoken.ai/zh-tw/docs/console-setup/)。

## 2. 建立工作區與專案

在「資源」建一個工作區把相關工作分組，再在裡面建專案。選擇專案的 **allowed models**——只有這些能被它的金鑰呼叫。見 [工作區與專案](https://atptoken.ai/zh-tw/docs/resources/)。

## 3. 撥預算（上限）

點數沿樹往下流：組織 → 工作區 → 專案。撥一筆固定金額給專案——這個金額就是它的天花板。花超過分配額時，專案會被標為 **In debt**，直到再儲值。見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## 4. 加人並給對的角色

邀請夥伴，在工作區或專案層級指派 Owner / Admin / Member，讓他們能用預算但不能搬動它。見 [團隊與角色](https://atptoken.ai/zh-tw/docs/team/)。

## 5. 盯著消耗

用量頁顯示每一層的已分配對已用，讓你在專案快到上限前就看得到。見 [追蹤消耗](https://atptoken.ai/zh-tw/docs/spend/)。

> **團隊額度來自分配，不是錢包**
>
> 在 team 組織裡，金鑰花的是 org 被分配到的點數——不是個人錢包。儲值是充進你的個人帳戶；再從那裡於「資源」撥給 org。見 [儲值與錢包](https://atptoken.ai/zh-tw/docs/topup/)。

「分配額即上限」的設計理由見 [有效的 AI 花費上限](https://atptoken.ai/zh-tw/blog/ai-spending-caps-that-work/)。

## 下一步

- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 可用、已收到、已分配與已用各代表什麼。
- [團隊與角色](https://atptoken.ai/zh-tw/docs/team/) — Owner、Admin 與 Member 各能做什麼。
- [追蹤消耗](https://atptoken.ai/zh-tw/docs/spend/) — 盯著每一層的已分配與已用。
