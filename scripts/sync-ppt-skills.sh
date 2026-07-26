#!/usr/bin/env bash
# ============================================================================
# sync-ppt-skills.sh — 同步 guizang-ppt-skill 上游更新到 vendor 目录
#
# 机制：
#   - 浅克隆 + rsync 排除非运行时文件
#   - 用 .upstream-commit 记录当前 vendor 的上游 commit，秒判是否最新
#   - 同步后自动跑「自包含性自检」，防止上游引入兄弟包依赖导致 vendor 断裂
#
# 用法：
#   ./scripts/sync-ppt-skills.sh                  # 检查并同步
#   ./scripts/sync-ppt-skills.sh --check          # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/ppt/guizang-ppt/
#   git add plugins/ppt/
#   git commit -m "chore(ppt): sync guizang-ppt upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/ppt"
UPSTREAM_OWNER="op7418"
UPSTREAM_REPO="guizang-ppt-skill"
LOCAL_DIR="guizang-ppt"                # vendor 目录名

# ---------- 参数解析 ----------
DRY_RUN=0
case "${1:-}" in
  --check|-n) DRY_RUN=1 ;;
  -h|--help)
    sed -n '2,18p' "$0" | sed 's/^# \?//'
    exit 0 ;;
esac

# CI 模式：记录变更到 $CI_CHANGES_FILE 供 workflow 读取
CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 同步 ----------
echo "=== ppt-skills 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO"
echo "本地: $LOCAL_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

VENDOR_DIR="$PLUGIN_DIR/$LOCAL_DIR"
COMMIT_FILE="$VENDOR_DIR/.upstream-commit"

# 浅克隆整仓，后续用 rsync 排除非运行时文件
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' RETURN

if ! git clone --depth 1 --filter=blob:none \
     "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$TMP_DIR/$UPSTREAM_REPO" >/dev/null 2>&1; then
  echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
  exit 1
fi

# 注意：本 skill 的 SKILL.md 在仓库根目录（非 skills/ 子目录），
# 因此不能用 sparse-checkout cone 模式（只认目录不认文件）。
# 改用浅克隆整仓 + rsync 排除非运行时文件。
CLONE_DIR="$TMP_DIR/$UPSTREAM_REPO"

NEW_COMMIT=$(cd "$CLONE_DIR" && git rev-parse HEAD)
OLD_COMMIT=""
[ -f "$COMMIT_FILE" ] && OLD_COMMIT=$(cat "$COMMIT_FILE")

# 判断是否有更新
if [ "$NEW_COMMIT" = "$OLD_COMMIT" ]; then
  echo "✓ $LOCAL_DIR 已是最新 ($NEW_COMMIT)"
  exit 0
fi

if [ -n "$OLD_COMMIT" ]; then
  echo "⚡ $LOCAL_DIR 有更新"
  echo "   旧: $OLD_COMMIT"
  echo "   新: $NEW_COMMIT"
  echo "   diff: https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO/compare/$OLD_COMMIT...$NEW_COMMIT"
else
  echo "⚡ $LOCAL_DIR 首次同步（无 .upstream-commit 记录）"
  echo "   新: $NEW_COMMIT"
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "ℹ️  dry-run 模式，不修改文件"
  exit 0
fi

# 用 rsync 同步：浅克隆有 .git/，用 -a 时不带 --delete（首次同步时目标为空无意义）
# 后续同步启用 --delete 清理上游已删的非运行时文件，但保留我们添加的 .upstream-commit
mkdir -p "$VENDOR_DIR"
rsync -a \
  ${OLD_COMMIT:+--delete} \
  --exclude='.upstream-commit' \
  --exclude='.git/' \
  --exclude='.gitignore' \
  --exclude='.github/' \
  --exclude='.claude-plugin/' \
  --exclude='docs/' \
  --exclude='assets/ppt-skill-showcase.png' \
  --exclude='README*' \
  --exclude='CONTRIBUTING*' \
  --exclude='SPONSORS*' \
  --exclude='LICENSE' \
  "$CLONE_DIR/" "$VENDOR_DIR/"
echo "$NEW_COMMIT" > "$COMMIT_FILE"
echo "✅ $LOCAL_DIR 已更新到 $NEW_COMMIT"
UPDATED_SKILLS+=("$LOCAL_DIR")

# ---------- 自包含性自检 ----------
echo ""
echo "--- 自包含性自检 ---"
WARNINGS=0
BROTHER=$(grep -rn "import.*from\s*['\"]@\|require(['\"]@" \
  --include='*.py' --include='*.ts' --include='*.js' --include='*.mjs' \
  "$VENDOR_DIR" 2>/dev/null | grep -vE 'node_modules|http[s]?://' || true)
if [ -n "$BROTHER" ]; then
  echo "⚠️  发现兄弟包依赖（@xxx/yyy），vendor 可能断裂："
  echo "$BROTHER" | head -5 | sed 's/^/      /'
  WARNINGS=1
fi

PJ=$(find "$VENDOR_DIR" -name package.json -not -path '*/node_modules/*' 2>/dev/null || true)
if [ -n "$PJ" ]; then
  while IFS= read -r f; do
    DEPS=$(python3 -c "
import json,sys
try:
    d=json.load(open('$f'))
    dd=d.get('dependencies',{})
    print(' , '.join(dd.keys()) if dd else '')
except: pass
" 2>/dev/null || true)
    if [ -n "$DEPS" ]; then
      echo "⚠️  $f 声明外部依赖：$DEPS"
      WARNINGS=1
    fi
  done <<< "$PJ"
fi

if [ "$WARNINGS" = "0" ]; then
  echo "✅ 自检通过：无兄弟包依赖，vendor 安全"
else
  echo "❗ 自检告警：上游可能已重构为非自包含，请人工确认是否改用整仓库引用"
fi

echo ""
echo "=== 完成 ==="
echo "下一步：git diff plugins/ppt/ 人工 review 后 commit"

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
