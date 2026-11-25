# 金鑰放在哪裡

> Source: https://atptoken.ai/zh-tw/docs/auth/

Gateway 可從下列位置讀取專案（project）API 金鑰。`Authorization: Bearer` 和 `x-api-key` 在每個端點都有效，所以官方 OpenAI、Anthropic、Google GenAI SDK 都不用改，只要換 base URL。Gateway 會在轉送請求前移除這把金鑰。

## 先拿到金鑰

金鑰不是從 API 申請的。到 [atptoken.ai](https://atptoken.ai) 登入，依序選擇或建立 組織 → 工作區 → 專案，再到專案裡建立金鑰。一把金鑰屬於一個專案：能用哪些模型、費用算在誰頭上，都由那個專案決定。見[管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/)。

## 金鑰放在哪裡

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、curl |
| `x-api-key: atp-…` | Anthropic SDK（`api_key=`）、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK |
| `?key=atp-…` | Gemini REST client。Log 會遮蔽這個 query param——可以的話優先用 header。 |

## 驗證失敗時

沒帶、被停用、過期或不存在的金鑰，都回 `401`，代碼是 `token_revoked`，訊息是「API key has been revoked or does not exist」。**完全沒送金鑰也是同一個錯誤**，所以先確認 header 真的有送出去，再懷疑金鑰本身。

`403` 是另一回事：金鑰沒問題，但模型不在這個專案的允許清單上。見[錯誤碼](https://atptoken.ai/zh-tw/docs/errors/)。

## 登入主控台

申請金鑰、儲值、讀主控台 API，起點都一樣：有一個人到 [atptoken.ai](https://atptoken.ai) 登入。在你依賴登入做任何東西之前，有兩件事要先知道。

### 登入要過人機驗證

登入需要通過人機驗證，而只有瀏覽器答得出來。沒帶答案的請求回 `400`，`reason` 是 `captcha_required`；答案驗不過的回 `400`，`reason` 是 `captcha_invalid`。

它存在的理由是：有人被鎖在自己的帳號外面。腳本一個帳號一個帳號地猜密碼，而唯一的防線是單一帳號的失敗次數上限——那擋住的是真正的持有人，對腳本毫無作用，因為它換下一個帳號就好。人機驗證在第一個請求就擋下整輪。驗證失敗不會讓你付代價：只有密碼真的錯了，失敗次數才會增加。

每一次登入都要過。沒有「失敗幾次之後才開始要求」這種門檻，也沒有可以申請的例外。

### 連結外部登入方式之後，密碼就不能用了

你可以把一個外部登入方式連結到帳號上，用它取代密碼。連結第一個時同樣要過人機驗證，而且它會改變這個帳號：帳號變成無密碼，原本的密碼會被刪除。你記得的那組密碼就不再是入口——不是暫停，是刪掉。

之後再連結第二個不會再有變化，因為密碼在第一個就一起走了。

要把密碼這條路拿回來，是管理員的動作：由管理員把帳號改回密碼模式，你再用「忘記密碼」設一組新的。從你自己的帳號裡，沒有任何操作能把原來那組找回來。

用密碼登入、而且還沒連結任何外部登入方式時，主控台會問你要不要連結一個。跳過是完整的答案——你的密碼照樣能用——而下次登入時它會再問一次。

## 下一步

- [管理 API 金鑰](https://atptoken.ai/zh-tw/docs/console-keys/) — 建立專案金鑰，以及撤銷金鑰
- [錯誤碼](https://atptoken.ai/zh-tw/docs/errors/) — `401` 代表什麼、先檢查什麼
- [快速開始](https://atptoken.ai/zh-tw/docs/quickstart/) — 用專案金鑰送出第一個請求
