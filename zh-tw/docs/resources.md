# Workspaces 與 projects

> Source: https://atptoken.ai/zh-tw/docs/resources/

Resources 頁是你建立 workspace、project，以及在它們之間搬移 credits 的地方。

## 1. 建立 workspace

Workspace 把多個 project 分在一起，並持有一池可往下分配的 credits。多數團隊會為每個產品或環境用一個 workspace。

## 2. 建立 project 並挑選允許的模型

在 workspace 裡建立 project，並選擇它的 **allowed models**（至少一個）。只有這些模型能被該 project 底下的每一把 key 呼叫。模型存取權是設在 project，不是設在單一 key。

## 3. 分配 credits

Credits 沿樹往下流：organization → workspace → project。撥一筆預算給 project，它底下的 key 才有額度可花。用詞說明見 [點數如何運作](#credits)。
