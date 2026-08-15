#!/usr/bin/env bash
# ============================================================================
# sync-gzh-skills.sh — 同步 isjiamu/gzh-design-skill 上游更新到 vendor 目录
#
# 机制：
#   - 浅克隆 + rsync 排除非运行时文件（archive/ 为上游 v1 旧版主题、docs/
#     为展示页，均无运行时引用，一并排除）
#   - 用 .upstream-commit 记录当前 vendor 的上游 commit，秒判是否最新
#   - 同步后自动跑「自包含性自检」：兄弟包依赖 + package.json 外部依赖
#     + Python import 标准库检查（本 skill 的 scripts/ 是纯 Python，标准库
#     检查是通用自检覆盖不到的盲区）
#
# 用法：
#   ./scripts/sync-gzh-skills.sh                  # 检查并同步
#   ./scripts/sync-gzh-skills.sh --check          # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff skills/gzh/gzh-design/
#   git add skills/gzh/
#   git commit -m "chore(gzh): sync gzh-design upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/gzh"
UPSTREAM_OWNER="isjiamu"
UPSTREAM_REPO="gzh-design-skill"
LOCAL_DIR="gzh-design"                # vendor 目录名

# ---------- 参数解析 ----------
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    -*|*)
      echo "❌ 未知参数：${arg}（仅支持 --check / -n / --help）"
      exit 1 ;;
  esac
done

# CI 模式：记录变更到 $CI_CHANGES_FILE 供 workflow 读取
CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 同步 ----------
echo "=== gzh-skills 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO"
echo "本地: $LOCAL_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"

VENDOR_DIR="$PLUGIN_DIR/$LOCAL_DIR"
COMMIT_FILE="$VENDOR_DIR/.upstream-commit"

# 浅克隆整仓，后续用 rsync 排除非运行时文件
TMP_DIR=$(mktemp -d)
# 必须用 EXIT：macOS 系统 bash 3.2 在脚本顶层不会触发 RETURN trap，
# 会导致 clone 目录泄漏（已实测：RETURN 静默不触发，EXIT 正常清理）。
trap 'rm -rf "$TMP_DIR"' EXIT

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
  --exclude='archive/' \
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

# Python import 标准库检查：scripts/ 必须 stdlib-only（零第三方依赖是本 skill 的卖点）
PY_STDLIB_OK=$(VENDOR_DIR="$VENDOR_DIR" python3 - <<'PYEOF'
import ast, os, pathlib, sys

stdlib = sys.stdlib_module_names
bad = []
for f in pathlib.Path(os.environ['VENDOR_DIR']).rglob('*.py'):
    tree = ast.parse(f.read_text(encoding='utf-8'))
    for node in ast.walk(tree):
        mods = []
        if isinstance(node, ast.Import):
            mods = [a.name.split('.')[0] for a in node.names]
        elif isinstance(node, ast.ImportFrom) and node.module and node.level == 0:
            mods = [node.module.split('.')[0]]
        for mod in mods:
            if mod not in stdlib:
                bad.append(f'{f}: import {mod}')
print('OK' if not bad else '\n'.join(bad))
PYEOF
)
if [ "$PY_STDLIB_OK" != "OK" ]; then
  echo "⚠️  Python 脚本引入了非标准库 import："
  echo "$PY_STDLIB_OK" | head -5 | sed 's/^/      /'
  WARNINGS=1
fi

if [ "$WARNINGS" = "0" ]; then
  echo "✅ 自检通过：无兄弟包依赖，Python 脚本 stdlib-only，vendor 安全"
else
  echo "❗ 自检告警：上游可能已重构为非自包含，请人工确认是否改用整仓库引用"
fi

echo ""
echo "=== 完成 ==="
echo "下一步：git diff skills/gzh/ 人工 review 后 commit"

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
