# 管理 API 金鑰

> Source: https://atptoken.ai/zh-tw/docs/console-keys/

「建立 API 金鑰」精靈會帶你完成：命名金鑰、選擇（或建立）工作區與專案（project），並可選擇順便撥一筆起始點數。一把金鑰一律只屬於一個專案，並繼承該專案的模型與點數餘額。

> **完整密鑰只會顯示一次**
>
> 金鑰以 `atp-` 開頭、長度 92 個字元。完整密鑰只會在建立當下顯示一次——請複製並妥善保存。之後只看得到 prefix。

## 搜尋與撤銷金鑰

**API 金鑰** 頁列出這個組織底下、跨所有工作區與專案的每一把金鑰。可依名稱或 prefix 搜尋、依工作區篩選，並隨時撤銷某把金鑰——撤銷後該金鑰會立即失效，但仍會留在名冊中供稽核。

## 一個專案一把金鑰

以專案為範圍的金鑰才能把花費與存取歸帳。操作模式見 [一專案一金鑰](https://atptoken.ai/zh-tw/blog/one-project-one-key/)。

## 下一步

- [驗證方式](https://atptoken.ai/zh-tw/docs/auth/) — 金鑰放在請求的哪裡。
- [工作區與專案](https://atptoken.ai/zh-tw/docs/resources/) — 設定金鑰會繼承的模型與點數。
- [用量與紀錄](https://atptoken.ai/zh-tw/docs/monitoring/) — 查看每把金鑰的 token 總量與請求。
