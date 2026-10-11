#!/usr/bin/env bash
# ============================================================
#  game-price-board 一键部署 / 同步脚本
#  —— 不依赖任何 CI 流水线，本机直接部署 + 双仓库同步
#
#  用法：
#    bash tools/deploy.sh              # 部署上线 + 同步 CNB/GitHub + 校验
#    bash tools/deploy.sh --sync-only  # 只提交推送，不部署
#    bash tools/deploy.sh --check-only # 只校验线上，不改动任何东西
#    bash tools/deploy.sh --dry-run    # 演练，不做实际变更
#
#  凭据来源（全部在项目目录之外，绝不写进 .git/config）：
#    EdgeOne  : 环境变量 EDGEONE_PAGES_API_TOKEN → ~/.workbuddy/edgeone/game-price-board.json
#    GitHub   : ~/.workbuddy/github/game-price-board.json  → { GITHUB_TOKEN, GITHUB_USER }
#    CNB      : ~/.workbuddy/cnb/game-price-board.json     → { CNB_TOKEN, CNB_USER }
#    推送时用 git -c http.extraheader="Authorization: Basic <base64(user:token)>" 临时注入，
#    不用凭据助手（沙箱里凭据助手子进程会被 SIGTERM），也不把令牌写进 remote URL。
#
#  ⚠️ 脚本只负责「EdgeOne 部署 + 双仓库推送」。
#     WorkBuddy 主站（MAIN_URL）需由 AI 单独调用 workbuddy_sites_deploy 发布 MIRROR_DIR，
#     脚本仅做镜像目录一致性同步，并对主站做校验。
# ============================================================

set -uo pipefail

PROJECT_NAME="game-price-board"
PROJECT_ID="makers-zrrxfmmcxb1t"
EDGEONE_AREA="overseas"
EDGEONE_ENV="production"
LIVE_URL="https://wj.ores.cc/"                               # EdgeOne 备用入口（脚本直接部署）
MAIN_URL="https://dk-game-price-board.app.workbuddy.host/"   # WorkBuddy 主站（AI 发布 dk-price/）
MIRROR_DIR="C:/Users/10493/WorkBuddy/dk-price"               # 主站镜像目录，必须与 index.html 一致

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

MODE="full"
case "${1:-}" in
  --sync-only)  MODE="sync" ;;
  --check-only) MODE="check" ;;
  --dry-run)    MODE="dry" ;;
  "")           MODE="full" ;;
  *) echo "未知参数: $1"; exit 2 ;;
esac

# ---------- 输出工具 ----------
c_ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
c_warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
c_err()  { printf '  \033[31m✘\033[0m %s\n' "$1"; }
c_step() { printf '\n\033[36m▶ %s\033[0m\n' "$1"; }

# 绕过本机残留代理（git/curl 走 libcurl 会受影响）
export NO_PROXY="*"
export no_proxy="*"
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy 2>/dev/null || true

# ---------- 凭据读取（项目目录之外） ----------
cred_token() {   # $1=凭据文件  $2=键名
  local f="$1" key="$2"
  [ -f "$f" ] || return 1
  "C:/Users/10493/.workbuddy/binaries/python/versions/3.13.12/python.exe" -c \
    "import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])" \
    "$(cygpath -w "$f")" "$key" 2>/dev/null
}

auth_header() {  # $1=用户名  $2=令牌
  printf 'Authorization: Basic %s' "$(printf '%s:%s' "$1" "$2" | base64 -w0)"
}

# ---------- 1. 读取线上数据周期（校验用） ----------
live_period() {
  local html
  html="$(curl -s --noproxy '*' -m 30 -H 'Cache-Control: no-cache' \
          -H 'Pragma: no-cache' "${LIVE_URL}?_cb=$RANDOM$RANDOM")" || return 1
  printf '%s' "$html" | grep -oE '8\.[0-9]+-[0-9]+\.[0-9]+' | head -1
}

# ---------- 2. 读取本地数据周期 ----------
local_period() {
  grep -oE '8\.[0-9]+-[0-9]+\.[0-9]+' index.html | head -1
}

# ============================================================
#  --check-only
# ============================================================
if [ "$MODE" = "check" ]; then
  c_step "线上校验"
  echo "  本地文件数据周期 : $(local_period)"
  echo "  线上实际数据周期 : $(live_period)"
  echo "  线上体积         : $(curl -s --noproxy '*' -m 25 -o /dev/null -w '%{size_download}' "${LIVE_URL}?_cb=$RANDOM") 字节"
  echo "  线上 MD5         : $(curl -s --noproxy '*' -m 25 "${LIVE_URL}?_cb=$RANDOM" | md5sum | cut -d' ' -f1)"
  echo "  本地 MD5         : $(md5sum index.html | cut -d' ' -f1)"
  exit 0
fi

# ============================================================
#  正式流程
# ============================================================
echo "============================================"
echo " game-price-board 部署 / 同步"
echo " 模式: $MODE"
echo " 目录: $REPO_ROOT"
echo "============================================"

LOCAL_P="$(local_period)"
if [ -z "$LOCAL_P" ]; then
  c_err "index.html 里读不到数据周期，文件可能损坏，已中止"
  exit 1
fi
c_ok "本地数据周期: $LOCAL_P"

# ---------- 阶段 A：打包 ----------
DIST="$REPO_ROOT/dist"
if [ "$MODE" = "full" ] || [ "$MODE" = "dry" ]; then
  c_step "A. 打包部署产物"
  rm -rf "$DIST"; mkdir -p "$DIST"
  # 只放需要上线的静态文件，避免把 node_modules/.git 等传上去
  for f in index.html; do
    [ -f "$f" ] && cp "$f" "$DIST/" && c_ok "打包 $f"
  done
  c_ok "dist 内容: $(ls "$DIST" | tr '\n' ' ')"

  # 同步 WorkBuddy 主站镜像目录，避免两处 index.html 漂移
  if [ -d "$(dirname "$MIRROR_DIR")" ]; then
    mkdir -p "$MIRROR_DIR"
    if cmp -s index.html "$MIRROR_DIR/index.html"; then
      c_ok "主站镜像已是最新: $MIRROR_DIR/index.html"
    else
      cp index.html "$MIRROR_DIR/index.html" && c_ok "已同步主站镜像: $MIRROR_DIR/index.html"
    fi
  else
    c_warn "镜像目录不存在，跳过：$MIRROR_DIR"
  fi
fi

# ---------- 阶段 B：部署到 EdgeOne Pages ----------
if [ "$MODE" = "full" ]; then
  c_step "B. 部署到 EdgeOne Pages"

  # 令牌刻意放在项目目录之外：WorkBuddy 发布是整目录上传，
  # 放在项目里会被当成静态资源公开出去。
  AUTH_JSON="$HOME/.workbuddy/edgeone/game-price-board.json"
  TOKEN="${EDGEONE_PAGES_API_TOKEN:-}"
  if [ -z "$TOKEN" ] && [ -f "$AUTH_JSON" ]; then
    TOKEN="$("C:/Users/10493/.workbuddy/binaries/python/versions/3.13.12/python.exe" -c \
      "import json,sys;print(json.load(open(sys.argv[1]))['EDGEONE_PAGES_API_TOKEN'])" \
      "$(cygpath -w "$AUTH_JSON")" 2>/dev/null)"
    [ -n "$TOKEN" ] && c_ok "凭据来源: $AUTH_JSON"
  fi
  if [ -z "$TOKEN" ]; then
    c_err "找不到 EdgeOne 令牌。请设置环境变量 EDGEONE_PAGES_API_TOKEN，"
    c_err "或把 JSON 写入 $AUTH_JSON（键名 EDGEONE_PAGES_API_TOKEN）"
    exit 1
  fi

  EO_BIN=""
  for cand in "$REPO_ROOT/node_modules/.bin/edgeone" \
              "C:/Users/10493/WorkBuddy/2026-09-13-13-33-19/node_modules/.bin/edgeone"; do
    [ -x "$cand" ] && EO_BIN="$cand" && break
  done
  if [ -z "$EO_BIN" ]; then
    c_warn "未找到本地 edgeone，改用 npx（首次较慢）"
    EO_CMD="npx --yes edgeone@1.6.39"
  else
    EO_CMD="$EO_BIN"
    c_ok "使用本地 CLI: $EO_BIN"
  fi

  if [ "$MODE" = "dry" ]; then
    c_warn "演练模式，跳过实际部署"
  else
    set -o pipefail
    $EO_CMD pages deploy "$DIST" -n "$PROJECT_NAME" -a "$EDGEONE_AREA" \
              -e "$EDGEONE_ENV" -t "$TOKEN" 2>&1 \
      | grep -vE '^Warning:|system-ca-bundle' \
      | sed -E 's/(token|TOKEN)[=: ]+[A-Za-z0-9+/=._-]{8,}/\1=***/g'
    DEPLOY_RC=${PIPESTATUS[0]}
    if [ "$DEPLOY_RC" -ne 0 ]; then
      c_err "部署失败（退出码 $DEPLOY_RC）"
      exit 1
    fi
    c_ok "部署命令执行完成"
  fi
fi

# ---------- 阶段 C：同步两个仓库 ----------
if [ "$MODE" = "full" ] || [ "$MODE" = "sync" ]; then
  c_step "C. 同步到 CNB 与 GitHub"

  # dist 不入库
  git rm -r --cached dist -q 2>/dev/null || true
  rm -rf dist 2>/dev/null || true

  git add -A
  if git diff --cached --quiet; then
    c_ok "无文件变更，跳过提交"
  else
    MSG="chore(data): 物价快照更新至 ${LOCAL_P##*-}，本地直部署"
    if [ "$MODE" = "dry" ]; then
      c_warn "演练模式，跳过提交: $MSG"
    else
      git commit -q -m "$MSG" && c_ok "已提交: $MSG"
    fi
  fi

  PUSHED=0
  if [ "$MODE" = "dry" ]; then
    c_warn "演练模式，跳过推送"
  else
    for remote in origin github; do
      if ! git remote | grep -qx "$remote"; then
        c_warn "未配置远程 $remote，跳过"
        continue
      fi

      # 组装 Authorization 头（令牌从项目外的凭据文件读，不进 remote URL）
      HDR_OPT=()
      if [ "$remote" = "github" ]; then
        CRED="$HOME/.workbuddy/github/game-price-board.json"
        TK="$(cred_token "$CRED" GITHUB_TOKEN)" || TK=""
        US="$(cred_token "$CRED" GITHUB_USER)"  || US=""
        [ -n "$TK" ] || c_warn "未找到 GitHub 令牌（$CRED），将尝试匿名推送"
      else
        CRED="$HOME/.workbuddy/cnb/game-price-board.json"
        TK="$(cred_token "$CRED" CNB_TOKEN)" || TK=""
        US="$(cred_token "$CRED" CNB_USER)"  || US=""
      fi
      if [ -n "$TK" ]; then
        HDR_OPT=(-c "http.extraheader=$(auth_header "${US:-cnb}" "$TK")")
      fi

      if timeout 180 git -c credential.helper= -c http.proxy= ${HDR_OPT[@]+"${HDR_OPT[@]}"} \
           push "$remote" main 2>&1 \
           | sed -E -e 's#//[^@]*@#//***@#g' -e 's#(Basic) [A-Za-z0-9+/=]{16,}#\1 ***#g' | tail -3; then
        c_ok "推送成功: $remote"
        PUSHED=$((PUSHED+1))
      else
        c_warn "推送失败: $remote（本地提交已保留，可稍后重试）"
      fi
    done
  fi
fi

# ---------- 阶段 D：线上校验 ----------
if [ "$MODE" = "full" ] && [ "${DEPLOY_RC:-1}" -eq 0 ]; then
  c_step "D. 线上校验"
  EXPECT="$LOCAL_P"
  for i in 1 2 3 4 5 6; do
    sleep 10
    GOT="$(live_period)"
    if [ "$GOT" = "$EXPECT" ]; then
      c_ok "第 $i 次探测：线上数据周期 = $GOT  与本地一致 ✅"
      SZ="$(curl -s --noproxy '*' -m 25 -o /dev/null -w '%{size_download}' "${LIVE_URL}?_cb=$RANDOM$RANDOM")"
      echo "     体积 $SZ 字节 | MD5 $(curl -s --noproxy '*' -m 25 "${LIVE_URL}?_cb=$RANDOM$RANDOM" | md5sum | cut -d' ' -f1)"
      echo
      echo "============================================"
      echo " ✅ 部署完成： $LIVE_URL"
      echo "============================================"

      # WorkBuddy 主站一致性与线上版本校验
      MP="$(curl -s --noproxy '*' -m 25 -H 'Cache-Control: no-cache' \
             "${MAIN_URL}?_cb=$RANDOM$RANDOM" | grep -oE '8\.[0-9]+-[0-9]+\.[0-9]+' | head -1)"
      if [ "$MP" = "$EXPECT" ]; then
        c_ok "WorkBuddy 主站已同步: $MAIN_URL ($MP)"
      else
        c_warn "WorkBuddy 主站线上为 ${MP:-不可达}，需由 AI 发布 $MIRROR_DIR 目录后才能生效"
      fi
      exit 0
    fi
    c_warn "第 $i 次探测：线上 $GOT（期望 $EXPECT），CDN 可能仍在刷新…"
  done
  c_err "部署命令成功但线上未收敛，请稍后手动确认：$LIVE_URL"
  exit 1
fi

echo
echo "============================================"
echo " 完成（模式: $MODE）"
echo "============================================"
