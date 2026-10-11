# 杜康-QQ三国-游戏物价波动看板

用于追踪游戏内物品物价波动：币价走势、涨跌幅排行、分类筛选与模糊搜索。

## 在线访问

站点有三个入口，状态各不相同，**别混用**：

| 地址 | 承载方式 | 我方能否更新 | 当前数据 |
|---|---|---|---|
| <https://game-price-board-28438.app.workbuddy.host> | WorkBuddy 应用（`wbapp_Kd0rD6gY15PTAGrPEwMLqb`） | ✅ 能 | **10.10** |
| <https://wj.ores.cc> | EdgeOne Pages（Makers 海外区） | ✅ 能 | **10.10** |
| <https://game-price-board.app.workbuddy.host> | WorkBuddy 遗留应用 | ❌ 不能 | 9.21（卡住） |

> ⚠️ **`game-price-board.app.workbuddy.host` 为什么更新不了**
> 它是**在另一台已停用的电脑上发布的旧应用**。本机 `applications.yaml`、部署历史、会话应用列表（`workbuddy_cloud_service inspect` 只返回 1 个应用）里**都查不到它**，因此本机的发布通道无法指向它。
> 更关键的是：**发布目标由「本地目录」决定，不由人指定** —— `workbuddy_sites_deploy` 只会把本项目目录映射到 `wbapp_Kd0rD6gY15PTAGrPEwMLqb`（即 `-28438` 那个应用）。所以只要那个旧应用还占着 `game-price-board` 这个域名前缀，我们就拿不到这个地址。
> **要拿回这个域名**：需在 WorkBuddy「设置—数据管理—应用」里把它删除，释放域名前缀后，再用一个全新目录 + `domainPrefix=game-price-board` 新建应用。

### 关于 wj.ores.cc

托管于 **EdgeOne Pages（Makers）海外区**
- 项目名 `game-price-board`，Project ID `makers-zrrxfmmcxb1t`
- 控制台：<https://console.tencentcloud.com/edgeone/pages/project/makers-zrrxfmmcxb1t>
- 自定义域：`wj.ores.cc` → CNAME `wj → wj.ores.cc.pages.dnsoe8.com`

> 该域名目前**仍在正常服务最新数据**；是否继续作为对外主站**尚未定论**（待与 `.app.workbuddy.host` 的归属一起决定）。

### ⚠️ 追加币价历史时必看：`COIN_DATES` 不能整段重写

2026-10-11 发现过一次真实事故：把 10.10 并入时，脚本误以为 `COIN_DATES` 只到 9.8，于是从 `9.9` 又追加了一整段，结果数组变成 **72 项、`9.9`~`9.21` 各重复两次且整体乱序**。页面用 `COIN.slice(-n)` 取窗口，重复项会把「近 30 天」算成跨两个月的错位区间。

正确做法：**先确认数组最后一项是哪天，只追加它之后的日期**，并断言不重复、严格升序：

```python
assert D == sorted(D, key=lambda s: [int(x) for x in s.split('.')])
assert len(set(D)) == len(D)
```

现网基线：`COIN_DATES` / `COIN` 各 **59 项**，范围 `8.13 → 10.10`；`RAW` **205** 行；`DATES` 5 期。

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

> ⚠️ **GitHub 推送当前不可用（2026-10-11 实测）**
> 两条通道都试过，都不通：
> 1. **PAT** —— 用户手上的细粒度令牌返回 `401 Bad credentials`（令牌格式本身合规：93 字符 = 11 + 22 + 1 + 59）；系统凭据管理器里存的旧经典令牌 `ghp_…` 同样 401。二者都不是权限问题，是令牌本身已失效。
> 2. **GitHub 连接器** —— 以 `poe112233` 身份 OAuth 授权，**只读**：读取正常，但写入返回 `403 Resource not accessible by integration`（连 `create_or_update_file` 写一个临时探针文件也被拒）。GitHub App 安装未授予 `Contents: write`。
>
> **恢复方式（任选其一）**：① 重新生成一个「Contents: Read and write」的细粒度令牌，填进 `.git/config` 的 `github` remote；② 在 GitHub 上给该连接器的 App 安装补上 `Contents: Read and write` 权限。
>
> 在此之前，`bash tools/deploy.sh` 的 GitHub 环节会失败并给出告警，**CNB 与线上部署不受影响**（脚本把两个远程分开处理，一个失败不影响另一个）。

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
4. 把变更提交并推送到 `origin`(CNB) 与 `github` 两个远程
5. 轮询线上站点，确认数据周期已收敛（CDN 有缓存，需重试几次）

### 发布到 WorkBuddy 应用

```bash
# 由 AI 调用 workbuddy_sites_deploy，directory 固定为项目根
# → 目标应用固定为 wbapp_Kd0rD6gY15PTAGrPEwMLqb → game-price-board-28438.app.workbuddy.host
```

⚠️ **发布前必须确认项目根目录内没有密钥文件**。WorkBuddy 发布是**整目录上传**，只有 `.git` / `node_modules` / 构建产物被排除，`.edgeone/auth.json` 这类文件**会被当作静态资源公开**。EdgeOne 令牌已因此移出项目目录（见下表）。

### 凭据

| 用途 | 位置 | 备注 |
|---|---|---|
| EdgeOne 部署令牌 | 环境变量 `EDGEONE_PAGES_API_TOKEN`，或 `~/.workbuddy/edgeone/game-price-board.json` | **已移出项目目录**，避免被整目录发布带出去 |
| CNB / GitHub 推送 | 内嵌在 `.git/config` 的 remote URL | 不入库 |

脚本会自动绕过本机残留代理（`NO_PROXY=*`），并清空 git 凭据助手——沙箱里凭据助手子进程会被终止，必须用「令牌内嵌 URL + `credential.helper=""`」这一组合。

### 更新数据的方法

页面数据是**手动录入**的，没有自动抓取源。在 `index.html` 顶部数据区维护四个数组：

| 数组 | 含义 | 新增方式 |
|---|---|---|
| `DATES` | 价格快照日期（如 `["8.15","8.23","9.5","9.21","10.10"]`） | 末尾追加日期 |
| `RAW` | 物品清单 `["名称","分类","单位W/E",[各期价格]]` | 每个物品的 `prices` 数组末尾追加该期价格 |
| `COIN_DATES` | 币价日期（逐日） | 末尾追加日期 |
| `COIN` | 出币价（逐日） | 末尾追加当日币价 |

改完跑 `bash tools/deploy.sh` 即可，脚本会自动部署+双推+校验。

## 数据更新

数据更新至 **10.10**，持续更新中。

| 数组 | 现网基线 |
|---|---|
| `DATES` | 5 期：8.15 / 8.23 / 9.5 / 9.21 / 10.10 |
| `RAW` | 205 行物品 |
| `COIN_DATES` / `COIN` | 各 59 项：8.13 → 10.10（10.10 出币价 **283.5**） |

> 10.10 两列数据来源：公众号文章《QQ三国，10.10杜康解忧最低杂物价格》正文图片。
> 录入时用文章里的 **9.5 / 9.21 两列**与站点既有数据做了逐行交叉校验，205 行**零差异**，据此确认读数无误；币价 283.5 另有文章表头 `币价: 284 | 284 | 283.5` 直接佐证。
