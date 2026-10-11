# 杜康-QQ三国-游戏物价波动看板

用于追踪游戏内物品物价波动：币价走势、涨跌幅排行、分类筛选与模糊搜索。

## 在线访问

🔗 **线上地址**：<https://wj.ores.cc>

托管于 **EdgeOne Pages（Makers）海外区**
- 项目名 `game-price-board`，Project ID `makers-zrrxfmmcxb1t`
- 控制台：<https://console.tencentcloud.com/edgeone/pages/project/makers-zrrxfmmcxb1t>
- 自定义域：`wj.ores.cc` → CNAME `wj → wj.ores.cc.pages.dnsoe8.com`

> ⚠️ **为什么不用 `game-price-board.app.workbuddy.host`**
> 那个地址虽然能访问，但它是**在另一台已停用的电脑上、用另一个 WorkBuddy 账号发布的旧应用**，本机与当前账号都查不到它的记录，**无法更新也无法删除**。它随时可能失效（账号停用即消失）。
> 同理 `98762c0e60af4ab7a1844f0627f6f35c.app.workbuddy.link`（数据停在 9.8）也是遗留物。
> **对外分享、写进文档一律用 `wj.ores.cc`。**

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
> （旧 `.cnb.yml` 流水线已废弃删除：它依赖仓库环境变量 `EDGEONE_API_TOKEN`，从未配置，导致 2026-09-13 起每次 push 的构建都静默失败，9.10 / 9.21 两轮数据更新因此漏上线整整一个月。）

### 仓库拓扑

| 远程名 | 位置 | 可见性 |
|---|---|---|
| `origin` | <https://cnb.cool/yume-2026/git-poe/game-price-board> | Private |
| `github` | <https://github.com/poe112233/game-price-board> | **Public** |

两边保持同一条历史线，`git push origin main && git push github main` 即可。`tools/deploy.sh` 会自动推送到这两个远程。

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

> ✅ **发版只需一条命令**：`bash tools/deploy.sh` 跑完，线上站（`wj.ores.cc`）、CNB、GitHub 三处就是最新的。
> 本项目**不涉及** WorkBuddy 应用托管（历史遗留的 `.app.workbuddy.host` 地址不在我们控制内，见上文说明）。

### 凭据

| 用途 | 位置 | 备注 |
|---|---|---|
| EdgeOne 部署令牌 | 环境变量 `EDGEONE_PAGES_API_TOKEN` 或 `./.edgeone/auth.json` | 已 gitignore |
| CNB / GitHub 推送 | 内嵌在 `.git/config` 的 remote URL | 不入库 |

脚本会自动绕过本机残留代理（`NO_PROXY=*`），并清空 git 凭据助手——沙箱里凭据助手子进程会被终止，必须用「令牌内嵌 URL + `credential.helper=""`」这一组合。

### 更新数据的方法

页面数据是**手动录入**的，没有自动抓取源。在 `index.html` 顶部数据区维护四个数组：

| 数组 | 含义 | 新增方式 |
|---|---|---|
| `DATES` | 价格快照日期（如 `["8.15","8.23","9.5","9.21"]`） | 末尾追加日期 |
| `RAW` | 物品清单 `["名称","分类","单位W/E",[各期价格]]` | 每个物品的 `prices` 数组末尾追加该期价格 |
| `COIN_DATES` | 币价日期（逐日） | 末尾追加日期 |
| `COIN` | 出币价（逐日） | 末尾追加当日币价 |

改完跑 `bash tools/deploy.sh` 即可，脚本会自动部署+双推+校验。

## 数据更新

数据更新至 **9.21**，持续更新中。
