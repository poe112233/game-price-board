# 杜康-QQ三国-游戏物价波动看板

用于追踪游戏内物品物价波动：币价走势、涨跌幅排行、分类筛选与模糊搜索。

## 在线访问

站点有两个可用入口：

| 地址 | 承载方式 | 状态 | 当前数据 |
|---|---|---|---|
| **<https://dk-game-price-board.app.workbuddy.host/>** | WorkBuddy 应用（`wbapp_fVLn3065PYBq1apGj7hetI`） | ✅ **主站** | **10.17** |
| <https://wj.ores.cc> | EdgeOne Pages（Makers 海外区） | ✅ 备用 | **10.17** |
| ~~<https://game-price-board.app.workbuddy.host>~~ | 旧遗留应用（已删除） | ❌ **永久不可用** | — |

> ⭐ **为什么旧地址 `game-price-board.app.workbuddy.host` 再也拿不回来（2026-10-11 实测确证）**
>
> **WorkBuddy 的裸域名只在该前缀"从未被任何应用使用过"时才分配。前缀一旦被用过，就永久只能拿到 `前缀-5位随机数` 的形态 —— 删掉应用也回不来，没有冷却期，也没有任何接口可改。**
>
> | 请求的前缀 | 是否首次使用 | 实际拿到的域名 |
> |---|---|---|
> | `game-price-board` | ❌ 已被旧遗留应用用过 | `game-price-board-28438` / `game-price-board-00179` |
> | `dk-game-price-board` | ✅ 全新 | **`dk-game-price-board`（裸域名）** |
> | `oe-brand` / `oe-brand-gallery` | ✅ 首次使用 | 裸域名 |
> | `link-translator` | ❌ 已被用过 | `link-translator-96457` |
>
> 附带现象：请求"已用过的前缀"时后端还会返回 `bindCloudService: backend returned an incomplete publicConfig`（平台缺陷），并已把应用建出来但不返回域名。
>
> **⇒ 结论：不要去抢已被使用过的前缀，换一个全新前缀（加账号缩写/日期）即可立刻拿到干净裸域名。**
>
> 另一个必须记住的点：**`workbuddy_sites_deploy` 是"整目录覆盖"，目标应用由本地目录/会话登记决定。任何探测目录都不得走发布通道，否则会顶掉线上内容。** 另外 `workbuddy_cloud_service activate` 创建应用时会重写会话登记表，**副作用是可能把上一个应用的发布踢下线**（`-00179` 就是这样变成 404 的），不要反复试探。

### 关于 wj.ores.cc —— 完整归属链（2026-10-11 审计）

| 环节 | 归属 | 依据 |
|---|---|---|
| 域名注册商 | **Spaceship, Inc.** | RDAP：`registration 2026-09-13`、`expiration` **2027-09-13**、状态 `client transfer prohibited` |
| DNS 托管 | **Spaceship** | NS = `launch1.spaceship.net` / `launch2.spaceship.net` |
| DNS 记录 | `wj` → CNAME `wj.ores.cc.pages.dnsoe8.com` | `Resolve-DnsName wj.ores.cc` |
| 托管平台 | **EdgeOne Makers（海外区）**，项目 `game-price-board` | Project ID `makers-zrrxfmmcxb1t`；响应头 `Server: edgeone makers` |
| 平台账号 | **用户本人腾讯云账号** `1049388745@qq.com`（Account ID `450200529839`） | `edgeone whoami` |
| 是否匿名部署 | **否**，是账号内的正式项目 | 全盘无 `.edgeone/anonymous.json`，无需 `makers claim` |
| 控制台 | <https://console.tencentcloud.com/edgeone/pages/project/makers-zrrxfmmcxb1t> | — |
| 部署通道 | `tools/deploy.sh` 阶段 B（令牌在项目目录之外） | 见「凭据」表 |

链路健康度（实测）：

- `http://wj.ores.cc` → **302** → `https://wj.ores.cc`（强制 HTTPS 已生效）
- `https://wj.ores.cc` → **200**，46303 B，MD5 `4783d249…`，与 WorkBuddy 主站**逐字节一致**
- `Cache-Control: public, max-age=0, must-revalidate` —— 部署后立即生效，不用等 CDN 刷新

> ⏰ **续费提醒**：`ores.cc` 注册于 **2026-09-13**，**到期 2027-09-13**（1 年期）。请到 Spaceship 后台**开启自动续费** —— 域名一旦过期，`wj` / `wdzl` / `ibuy` 三条子域会同时失效。

> 该域名是**用户自有域名**，不会像 `.app.workbuddy.host` 那样被平台"消耗掉前缀"，因此作为对外备用入口长期保留。

#### `ores.cc` 各子域当前归属

| 子域 | 指向 | 用途 |
|---|---|---|
| `wj.ores.cc` | EdgeOne Makers 项目 `game-price-board` | 物价看板备用入口 |
| `wdzl.ores.cc` | EdgeOne Makers 另一项目（CNAME 后缀 `dnsoe7.com`） | 链接转换站 |
| `ibuy.ores.cc` | `poe112233.github.io`（GitHub Pages） | 跳转页 |
| `ores.cc`（根域） | 返回 301/302 | — |
| `www.ores.cc` | 无记录 | — |

### ⚠️ 追加币价历史时必看：`COIN_DATES` 不能整段重写

2026-10-11 发现过一次真实事故：把 10.10 并入时，脚本误以为 `COIN_DATES` 只到 9.8，于是从 `9.9` 又追加了一整段，结果数组变成 **72 项、`9.9`~`9.21` 各重复两次且整体乱序**。页面用 `COIN.slice(-n)` 取窗口，重复项会把「近 30 天」算成跨两个月的错位区间。

正确做法：**先确认数组最后一项是哪天，只追加它之后的日期**，并断言不重复、严格升序：

```python
assert D == sorted(D, key=lambda s: [int(x) for x in s.split('.')])
assert len(set(D)) == len(D)
```

现网基线：`COIN_DATES` / `COIN` 各 **60 项**，范围 `8.13 → 10.17`；`RAW` **211** 行；`DATES` 6 期。

## 功能特性

- 💰 **币价走势面板**：近 7 天 / 近 30 天切换，KPI 指标 + 趋势图（出币）
- 📈 **波动排行**：涨幅 / 跌幅 TOP10，点击行查看详情弹窗
- 🔍 **模糊搜索**：支持中文、拼音首字母（如 `lls`、`fy`）
- 🏷️ **分类筛选**：按分类 chip 过滤，显示各类物品数量
- ↕️ **多维排序**：默认 / 涨幅 / 跌幅 / 波动幅度 / 最新价格 / 名称
- 🌗 **明暗主题**：一键切换，localStorage 记忆，默认浅色
- 📱 **响应式布局**：桌面 / 移动端自适应

## 单位说明

- `W` = 万，`E` = 亿
- 原表 E 列中以「W」结尾的数值（如 130W）即为 130 万
- 涨跌幅按统一换算为「万」后的数值计算，不受单位影响

## 技术栈

- 纯 HTML + CSS + 原生 JavaScript，零依赖、零构建
- 图表为手写 SVG，无需任何第三方库

---

## 部署与同步流程

> ⚠️ **本项目不使用任何 CI/CD 流水线。** 由本地直接部署，再同步到两个代码仓库。
> （旧 `.cnb.yml` 流水线已废弃：它依赖仓库环境变量 `EDGEONE_API_TOKEN`，从未配置，导致 2026-09-13 起每次 push 的构建都静默失败，9.10 / 9.21 两轮数据更新因此漏上线。）

### 仓库拓扑

| 远程名 | 位置 | 可见性 |
|---|---|---|
| `origin` | <https://cnb.cool/yume-2026/git-poe/game-price-board> | Private |
| `github` | <https://github.com/poe112233/game-price-board> | **Public** |

两边保持同一条历史线。`tools/deploy.sh` 会自动推送到这两个远程。

> ✅ **GitHub 推送已恢复正常（2026-10-11 20:35 实测）**
>
> 之前不通的原因是**令牌本身失效**（`401 Bad credentials` / 推送报 `remote: Invalid username or token.`），与权限配置无关——仓库确实是 Public 且存在。
> 20:30 用户重新生成细粒度令牌后，`git push github main` 已成功：`50464f2..76319b4`，两个远程现在同处一条历史线。
>
> **凭据存放（令牌不再写进 `.git/config`）**
>
> | 用途 | 文件 | 键 |
> |---|---|---|
> | GitHub | `~/.workbuddy/github/game-price-board.json` | `GITHUB_TOKEN` / `GITHUB_USER` |
> | CNB | `~/.workbuddy/cnb/game-price-board.json` | `CNB_TOKEN` / `CNB_USER` |
> | EdgeOne | `~/.workbuddy/edgeone/game-price-board.json` | `EDGEONE_PAGES_API_TOKEN` |
>
> 推送时由 `tools/deploy.sh` 用 `git -c http.extraheader="Authorization: Basic <base64(user:token)>"` **临时注入**。之所以不用凭据助手：沙箱里 git 凭据助手子进程会被 SIGTERM；之所以不把令牌写进 remote URL：明文落盘是隐患（历史上就是这么做的，已清理）。
>
> **令牌过期后怎么续**：重新生成一枚细粒度令牌 —— Repository access 选 **Only select repositories → `poe112233/game-price-board`**，Permissions → Repository permissions → **Contents: Read and write**，Expiration 建议 ≥ 90 天，然后把新值写回上表对应的 JSON 即可。
>
> ⚠️ **GitHub 连接器不可用于推送**：它以 `poe112233` 身份 OAuth 授权但**只读**，写入返回 `403 Resource not accessible by integration`。

### 一键操作

```bash
bash tools/deploy.sh              # 部署上线 + 双推同步 + 线上校验   ← 常用
bash tools/deploy.sh --sync-only  # 只提交推送，不部署
bash tools/deploy.sh --check-only # 只比对线上与本地，零改动
bash tools/deploy.sh --dry-run    # 演练，不做实际变更
```

### 脚本做了什么

1. 从 `index.html` 读出数据周期，与预期比对
2. 打包 `dist/`（只放 `index.html`，避免把 `node_modules`、`.git` 传上 CDN）
3. 用 EdgeOne CLI 直接部署到 `game-price-board` 项目生产环境
4. 把 `index.html` 同步到主站镜像目录 `dk-price/`（防止两处漂移）
5. 把变更提交并推送到 `origin`(CNB) 与 `github` 两个远程
6. 轮询线上站点，确认数据周期已收敛（CDN 有缓存，需重试几次），并顺便校验 WorkBuddy 主站版本

### 发布到 WorkBuddy 应用

```bash
# 由 AI 调用 workbuddy_sites_deploy
# directory     = C:\Users\10493\WorkBuddy\dk-price   （主站的镜像目录）
# domainPrefix  = dk-game-price-board
# → 目标应用 wbapp_fVLn3065PYBq1apGj7hetI → https://dk-game-price-board.app.workbuddy.host/
```

主站采用**"镜像目录 + 独立应用"**结构：`dk-price/` 是 `index.html` 的镜像副本（与项目根的文件逐字节一致，当前 46303 B / MD5 `4783d249ba6cd2c137b19d0e29cb9c56`），发布只认这个目录。这样做是为了把"发布通道"与"代码仓库目录"解耦——项目根目录里含 `.git`、`node_modules`、`tools/`，绝不整目录上传。

**数据更新后，要让主站生效，必须同时更新两处 `index.html`**（项目根 + `dk-price/`），然后发布 `dk-price/`。

⚠️ **发布前必须确认项目根目录内没有密钥文件**。WorkBuddy 发布是**整目录上传**，只有 `.git` / `node_modules` / 构建产物被排除，`.edgeone/auth.json` 这类文件**会被当作静态资源公开**。EdgeOne 令牌已因此移出项目目录（见下表）。

### 凭据

| 用途 | 位置 | 备注 |
|---|---|---|
| EdgeOne 部署令牌 | 环境变量 `EDGEONE_PAGES_API_TOKEN`，或 `~/.workbuddy/edgeone/game-price-board.json` | **已移出项目目录**，避免被整目录发布带出去 |
| GitHub 推送 | `~/.workbuddy/github/game-price-board.json`（`GITHUB_TOKEN` / `GITHUB_USER`） | ✅ 可用 |
| CNB 推送 | `~/.workbuddy/cnb/game-price-board.json`（`CNB_TOKEN` / `CNB_USER`） | ✅ 可用 |

**三个令牌全部存放在项目目录之外**，`.git/config` 里不再有任何明文令牌（2026-10-11 已清理）。

脚本会自动绕过本机残留代理（`NO_PROXY=*`），并清空 git 凭据助手——沙箱里凭据助手子进程会被终止，所以改由 `http.extraheader` 注入 `Authorization: Basic`。这两个动作都不能省，否则推送会静默失败。

### 更新数据的方法

页面数据是**手动录入**的，没有自动抓取源。在 `index.html` 顶部数据区维护四个数组：

| 数组 | 含义 | 新增方式 |
|---|---|---|
| `DATES` | 价格快照日期（如 `["8.15","8.23","9.5","9.21","10.10","10.17"]`） | 末尾追加日期 |
| `RAW` | 物品清单 `["名称","分类","单位W/E",[各期价格]]` | 每个物品的 `prices` 数组末尾追加该期价格 |
| `COIN_DATES` | 币价日期（逐日） | 末尾追加日期 |
| `COIN` | 出币价（逐日） | 末尾追加当日币价 |

改完跑 `bash tools/deploy.sh` 即可，脚本会自动部署+双推+校验。

## 数据更新

数据更新至 **10.17**，持续更新中。

| 数组 | 现网基线 |
|---|---|
| `DATES` | 6 期：8.15 / 8.23 / 9.5 / 9.21 / 10.10 / 10.17 |
| `RAW` | 211 行物品（含 10.17 首次出现的 6 条羽灵） |
| `COIN_DATES` / `COIN` | 各 60 项：8.13 → 10.17（10.17 出币价 **284**） |

> 10.17 数据来源：公众号文章《QQ三国，10.17杜康解忧最低杂物价格》正文图片（9 张）。
> 文章每张图只给 **9.21 / 10.10 / 10.17** 三列。录入按「物品名」逐条映射（不按行号），并做两步校验：
> ① **异常波动筛查** —— 10.17 对站点 10.10 的涨跌幅，仅 6 条超过 ±25%（`坠星1F +30%`、`装备模（中）+26.7%`、`火纹玉 +25%`、`蝶之羽1C +25%`、`1黄 +25%`、`装备模（高）-25%`），逐条回图核对都是真实波动，排除错行/量级错误；
> ② **币价** —— 284 由文章表头 `币价: 284 | 283.5 | 284` 直接佐证。
>
> **10.17 新增品类**：`1/10/20/30/40/50级羽灵` 共 6 条，此前各期文章未出现，故前 5 期记为 `null`。
> 页面已支持缺失值：`null` 不参与图表折线、不参与涨跌幅统计，卡片上显示 `—` 与「新增」徽标。
> 新增品类时按同样格式把前几期填 `null` 即可，无需改动渲染逻辑。
