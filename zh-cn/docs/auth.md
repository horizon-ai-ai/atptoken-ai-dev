# 密钥放在哪里

> Source: https://atptoken.ai/zh-cn/docs/auth/

Gateway 可从下列位置读取项目（project）API 密钥。`Authorization: Bearer` 和 `x-api-key` 在每个端点都有效，所以官方 OpenAI、Anthropic、Google GenAI SDK 都不用改，只要换 base URL。Gateway 会在转送请求前移除这把密钥。

## 先拿到密钥

密钥不是从 API 申请的。到 [atptoken.ai](https://atptoken.ai) 登录，依序选择或建立 组织 → 工作区 → 项目，再到项目里建立密钥。一把密钥属于一个项目：能用哪些模型、费用算在谁头上，都由那个项目决定。见[管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/)。

## 密钥放在哪里

| 位置 | 使用者 |
|---|---|
| `Authorization: Bearer atp-…` | OpenAI SDK、curl |
| `x-api-key: atp-…` | Anthropic SDK（`api_key=`）、curl |
| `x-goog-api-key: atp-…` | Google GenAI SDK |
| `?key=atp-…` | Gemini REST client。Log 会遮蔽这个 query param——可以的话优先用 header。 |

## 验证失败时

没带、被停用、过期或不存在的密钥，都回 `401`，代码是 `token_revoked`，消息是「API key has been revoked or does not exist」。**完全没送密钥也是同一个错误**，所以先确认 header 真的有送出去，再怀疑密钥本身。

`403` 是另一回事：密钥没问题，但模型不在这个项目的允许清单上。见[错误码](https://atptoken.ai/zh-cn/docs/errors/)。

## 登录控制台

申请密钥、充值、读控制台 API，起点都一样：有一个人到 [atptoken.ai](https://atptoken.ai) 登录。在你依赖登录做任何东西之前，有两件事要先知道。

### 登录要过人机验证

登录需要通过人机验证，而只有浏览器答得出来。没带答案的请求回 `400`，`reason` 是 `captcha_required`；答案验不过的回 `400`，`reason` 是 `captcha_invalid`。

它存在的理由是：有人被锁在自己的账号外面。脚本一个账号一个账号地猜密码，而唯一的防线是单一账号的失败次数上限——那挡住的是真正的持有人，对脚本毫无作用，因为它换下一个账号就好。人机验证在第一个请求就挡下整轮。验证失败不会让你付代价：只有密码真的错了，失败次数才会增加。

每一次登录都要过。没有「失败几次之后才开始要求」这种门槛，也没有可以申请的例外。

### 连结外部登录方式之后，密码就不能用了

你可以把一个外部登录方式连结到账号上，用它取代密码。连结第一个时同样要过人机验证，而且它会改变这个账号：账号变成无密码，原本的密码会被删除。你记得的那组密码就不再是入口——不是暂停，是删掉。

之后再连结第二个不会再有变化，因为密码在第一个就一起走了。

要把密码这条路拿回来，是管理员的动作：由管理员把账号改回密码模式，你再用「忘记密码」设一组新的。从你自己的账号里，没有任何操作能把原来那组找回来。

用密码登录、而且还没连结任何外部登录方式时，控制台会问你要不要连结一个。跳过是完整的答案——你的密码照样能用——而下次登录时它会再问一次。

## 下一步

- [管理 API 密钥](https://atptoken.ai/zh-cn/docs/console-keys/) — 建立项目密钥，以及撤销密钥
- [错误码](https://atptoken.ai/zh-cn/docs/errors/) — `401` 代表什么、先检查什么
- [快速开始](https://atptoken.ai/zh-cn/docs/quickstart/) — 用项目密钥送出第一个请求
