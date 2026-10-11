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
#  凭据来源（按优先级）：
#    EdgeOne : 环境变量 EDGEONE_PAGES_API_TOKEN → ./.edgeone/auth.json
#    Git     : 内嵌在 .git/config 的 remote URL 里（不入库）
# ============================================================

set -uo pipefail

PROJECT_NAME="game-price-board"
PROJECT_ID="makers-zrrxfmmcxb1t"
EDGEONE_AREA="overseas"
EDGEONE_ENV="production"
LIVE_URL="https://wj.ores.cc/"

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
fi

# ---------- 阶段 B：部署到 EdgeOne Pages ----------
if [ "$MODE" = "full" ]; then
  c_step "B. 部署到 EdgeOne Pages"

  TOKEN="${EDGEONE_PAGES_API_TOKEN:-}"
  if [ -z "$TOKEN" ] && [ -f "$REPO_ROOT/.edgeone/auth.json" ]; then
    TOKEN="$(python -c "import json;print(json.load(open(r'$REPO_ROOT/.edgeone/auth.json'))['EDGEONE_PAGES_API_TOKEN'])" 2>/dev/null)"
    [ -n "$TOKEN" ] && c_ok "凭据来源: ./.edgeone/auth.json"
  fi
  if [ -z "$TOKEN" ]; then
    c_err "找不到 EdgeOne 令牌。请设置环境变量 EDGEONE_PAGES_API_TOKEN，"
    c_err "或把 JSON 写入 ./.edgeone/auth.json（键名 EDGEONE_PAGES_API_TOKEN）"
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
      if git remote | grep -qx "$remote"; then
        if timeout 180 git -c credential.helper= -c http.proxy= push "$remote" main 2>&1 \
             | sed -E 's#//[^@]*@#//***@#g' | tail -3; then
          c_ok "推送成功: $remote"
          PUSHED=$((PUSHED+1))
        else
          c_warn "推送失败: $remote（本地提交已保留，可稍后重试）"
        fi
      else
        c_warn "未配置远程 $remote，跳过"
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
