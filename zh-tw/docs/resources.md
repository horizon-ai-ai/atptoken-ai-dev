# 工作區與專案

> Source: https://atptoken.ai/zh-tw/docs/resources/

「資源」頁是你建立工作區、專案（project），以及在它們之間搬移點數的地方。

## 1. 建立工作區

工作區把多個專案分在一起，並持有一池可往下分配的點數。多數團隊會為每個產品或環境用一個工作區。

## 2. 建立專案並挑選允許的模型

在工作區裡建立專案，並選擇它的 **allowed models**（至少一個）。只有這些模型能被該專案底下的每一把金鑰呼叫。模型存取權是設在專案，不是設在單一金鑰。

## 3. 分配點數

點數沿樹往下流：組織 → 工作區 → 專案。撥一筆預算給專案，它底下的金鑰才有額度可花。用詞說明見 [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/)。

## 看分配如何運作

拖動滑桿，看撥給專案的點數如何決定它的金鑰能不能花。

**誰能花多少** — _示意_

- 組織 Northwind — 10,000 點數
  - 工作區 Product — 收到 4,000 點數
    - 專案 support-bot — 已撥 1,200 點數；模型：claude-sonnet-5, gpt-5.5
      - 金鑰 support-bot-prod
      - 金鑰 support-bot-staging
    - 專案 web-app — 已撥 1,500 點數；模型：gpt-5.5, deepseek-v4-flash
      - 金鑰 web-app-prod
  - 工作區 Media lab — 收到 2,500 點數
    - 專案 video-lab — 已撥 2,500 點數；模型：seedance-2-0
      - 金鑰 video-lab-render

- **組織**：持有你儲值的點數，往下撥給工作區。
- **工作區**：把專案分成一組，持有一池可再往下撥給專案的點數——不會超過它收到的。
- **專案**：有自己的點數預算與允許模型；專案裡每一把金鑰只能呼叫這些模型。
- **金鑰**：只屬於一個專案，從該專案的餘額扣點。

## 下一步

- [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/) — 從剛撥好點數的專案建立金鑰。
- [點數如何運作](https://atptoken.ai/zh-tw/docs/credits/) — 可用、已收到、已分配與已用各代表什麼。
- [團隊與角色](https://atptoken.ai/zh-tw/docs/team/) — 在工作區或專案層級給成員權限。
