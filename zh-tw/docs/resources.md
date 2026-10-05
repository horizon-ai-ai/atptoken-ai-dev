# Workspaces 與 projects

> Source: https://atptoken.ai/zh-tw/docs/resources/

Resources 頁是你建立 workspace、project，以及在它們之間搬移 credits 的地方。

## 1. 建立 workspace

Workspace 把多個 project 分在一起，並持有一池可往下分配的 credits。多數團隊會為每個產品或環境用一個 workspace。

## 2. 建立 project 並挑選允許的模型

在 workspace 裡建立 project，並選擇它的 **allowed models**（至少一個）。只有這些模型能被該 project 底下的每一把 key 呼叫。模型存取權是設在 project，不是設在單一 key。

## 3. 分配 credits

Credits 沿樹往下流：organization → workspace → project。撥一筆預算給 project，它底下的 key 才有額度可花。用詞說明見 [點數如何運作](#credits)。

拖動滑桿，看撥給 project 的點數如何決定它的 key 能不能花。

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
