# 杜康-QQ三国-游戏物价波动看板

用于追踪游戏内物品物价波动：币价走势、涨跌幅排行、分类筛选与模糊搜索。

## 在线访问

🔗 **主站**：<https://game-price-board.app.workbuddy.host>
🔗 **镜像站**：<https://wj.ores.cc>

两个地址指向的是**同一份内容**，可任选其一访问。

| 地址 | 托管方 | 说明 |
|---|---|---|
| <https://game-price-board.app.workbuddy.host> | WorkBuddy 应用托管 | 主站，对外分享用这个 |
| <https://wj.ores.cc> | EdgeOne Pages（海外区） | 镜像 / 技术备份 |

**EdgeOne 侧明细**
- 项目名 `game-price-board`，Project ID `makers-zrrxfmmcxb1t`
- 控制台：<https://console.tencentcloud.com/edgeone/pages/project/makers-zrrxfmmcxb1t>
- 自定义域：`wj.ores.cc` → CNAME `wj → wj.ores.cc.pages.dnsoe8.com`

> ⛔ **已废弃、勿再使用**：`98762c0e60af4ab7a1844f0627f6f35c.app.workbuddy.link`（旧版，数据停在 9.8）

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

> ⚠️ **关于主站**：`game-price-board.app.workbuddy.host` 走的是 WorkBuddy 应用托管，**没有命令行通道**，只能在 WorkBuddy 对话里用「发布为应用」重新发布。
> 所以完整的发版流程是：**跑 `deploy.sh`（EdgeOne 镜像 + 双推） → 再让 Agent 重新发布一次 WorkBuddy 应用（主站）**。
> 只跑脚本的话，主站会停留在上一版。

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
