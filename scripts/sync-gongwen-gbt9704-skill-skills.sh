#!/usr/bin/env bash
# ============================================================================
# sync-gongwen-gbt9704-skill-skills.sh — 同步 mizzlelover/gongwen-gbt9704-skill 上游
#
# 上游特点：
#   - 单仓库单 skill，SKILL.md 在仓库根目录（禁用 sparse-checkout，用整仓浅克隆 + rsync）
#   - 零 npm 依赖：生成/校验脚本只 import node: 内置模块，
#     execFileSync 仅调用本地工具（fc-list / zip / unzip）
#   - 上游 87MB 中约 48MB 为推广与截图资产。marketplace 条目 source 为 "./"，
#     ZCode 会为每个场景组缓存整仓，故以下非运行时内容一律不入库：
#       dist/（TraeWork/WorkBuddy 安装包 zip）、marketing/ 与 punk-assets/（推广图文）、
#       docs/（上游自装平台说明）、references/assets/（视觉核验截图证据，5MB；
#       其结论已记录在 references/*.md 文本中）、scripts/install.sh|ps1 与
#       tests/test-install.sh（上游自装通道，本仓库走市场安装）
#
# 机制：
#   - 浅克隆 + rsync 排除非运行时文件（README/LICENSE/.github/agents 等）
#   - 用 .upstream-commit 记录当前 vendor 的上游 commit，秒判是否最新
#   - 同步后自动跑「自包含性自检」，防止上游引入 npm 依赖导致 vendor 断裂
#
# 用法：
#   ./scripts/sync-gongwen-gbt9704-skill-skills.sh            # 检查并同步
#   ./scripts/sync-gongwen-gbt9704-skill-skills.sh --check    # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff -- skills/gongwen-gbt9704-skill/ .claude-plugin/marketplace.json
#   git add skills/gongwen-gbt9704-skill/
#   git commit -m "chore(gongwen-gbt9704-skill): sync upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/gongwen-gbt9704-skill"
UPSTREAM_OWNER="mizzlelover"
UPSTREAM_REPO="gongwen-gbt9704-skill"
LOCAL_DIR="gongwen"                     # vendor 目录名（= SKILL.md name）

# ---------- 参数解析 ----------
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,29p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *)
      echo "❌ 未知参数：${arg}（仅支持 --check / -n / --help）"
      exit 1 ;;
  esac
done

CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# 市场组版本只跟随已收录 skill 的实际内容变化；--check 保持只读。
source "$REPO_ROOT/scripts/lib/marketplace-version.sh"
marketplace_version_snapshot "$REPO_ROOT" "$PLUGIN_DIR" "$DRY_RUN"

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 同步 ----------
echo "=== gongwen-gbt9704-skill 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO"
echo "本地: $LOCAL_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

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

# 用 rsync 同步：首次（目标为空）不带 --delete；后续启用 --delete
# 清理上游已删的非运行时文件，但保留 .upstream-commit
mkdir -p "$VENDOR_DIR"
rsync -a \
  ${OLD_COMMIT:+--delete} \
  --exclude='.upstream-commit' \
  --exclude='.git/' \
  --exclude='.gitignore' \
  --exclude='.github/' \
  --exclude='.claude-plugin/' \
  --exclude='agents/' \
  --exclude='README*' \
  --exclude='LICENSE' \
  --exclude='dist/' \
  --exclude='marketing/' \
  --exclude='punk-assets/' \
  --exclude='docs/' \
  --exclude='references/assets/' \
  --exclude='scripts/install.sh' \
  --exclude='scripts/install.ps1' \
  --exclude='tests/test-install.sh' \
  "$CLONE_DIR/" "$VENDOR_DIR/"
echo "$NEW_COMMIT" > "$COMMIT_FILE"

echo "✅ $LOCAL_DIR 已更新到 $NEW_COMMIT"
UPDATED_SKILLS+=("$LOCAL_DIR")

# ---------- 自包含性自检 ----------
echo ""
echo "--- 自包含性自检 ---"
WARNINGS=0

# 本 skill 定位为零 npm 依赖：任何非 node: 前缀的模块导入都视为断裂信号
NON_NODE_IMPORTS=$(grep -rn "import .* from ['\"][^.'\"][^'\"]*['\"]\|require(['\"][^.'\"][^'\"]*)" \
  --include='*.js' --include='*.mjs' --include='*.cjs' \
  "$VENDOR_DIR" 2>/dev/null \
  | grep -v "from ['\"]node:" || true)
if [ -n "$NON_NODE_IMPORTS" ]; then
  echo "⚠️  发现非 node: 内置模块的导入，vendor 可能断裂："
  echo "$NON_NODE_IMPORTS" | head -5 | sed 's/^/      /'
  WARNINGS=1
fi

# vendored SKILL.md 的 name 必须与目录名一致（marketplace 条目按路径收录）
SKILL_NAME=$(sed -n 's/^name:[[:space:]]*//p' "$VENDOR_DIR/SKILL.md" | head -1)
if [ "$SKILL_NAME" != "$LOCAL_DIR" ]; then
  echo "⚠️  SKILL.md name（$SKILL_NAME）与目录名（$LOCAL_DIR）不一致，请人工确认"
  WARNINGS=1
fi

if [ "$WARNINGS" = "0" ]; then
  echo "✅ 自检通过：无外部包依赖，vendor 安全"
else
  echo "❗ 自检告警：上游可能已重构为非自包含，请人工确认"
fi

echo ""
echo "=== 完成 ==="
echo "下一步：git diff -- skills/gongwen-gbt9704-skill/ .claude-plugin/marketplace.json 人工 review 后 commit"

# CI 模式
marketplace_version_apply "$DRY_RUN"

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
