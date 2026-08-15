#!/usr/bin/env bash
# ============================================================================
# sync-taste-skills.sh — 同步 Leonxlnx/taste-skill 的上游 skill 到 vendor 目录
#
# 上游特点（单仓库多 skill / 扁平）：
#   - Leonxlnx/taste-skill 的 skills/ 下每个 skill 一个子目录
#     skills/<skill>/SKILL.md
#   - 一套连贯的 anti-slop 前端设计框架（前端代码 + 图片生成驱动 prompt）
#   - 根目录无 package.json，无 workspaces，无运行时脚本依赖
#     （skill.sh / scripts/ / research/ 均为仓库维护资产，不 vendor）
#   - 所有 skill 共享同一上游 commit
#   - 纯 SKILL.md（+ stitch-skill 的 DESIGN.md），自包含
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录
#   - 扁平结构：skills/taste/<skill>/
#   - 每个 skill 目录单独保存 .upstream-commit
#   - 同步后跑「自包含性自检」
#
# 用法：
#   ./scripts/sync-taste-skills.sh                  # 检查并同步全部
#   ./scripts/sync-taste-skills.sh taste-skill      # 只同步某个
#   ./scripts/sync-taste-skills.sh --check          # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff skills/taste/
#   git add skills/taste/
#   git commit -m "chore(taste): sync upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/taste"
UPSTREAM_OWNER="Leonxlnx"
UPSTREAM_REPO="taste-skill"
UPSTREAM_SUBDIR="skills"

# 当前 vendor 目录下已有的 skill 列表（从本地目录扫描）
discover_skills() {
  [ -d "$PLUGIN_DIR" ] || return 0
  find "$PLUGIN_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
    | sed 's|.*/||' | sort
}

# ---------- 参数解析 ----------
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    -*)
      echo "❌ 未知参数：${arg}"
      exit 1 ;;
    *)
      if [ -n "$TARGET" ]; then
        echo "❌ 只能指定一个 target，已有：${TARGET}，又收到：${arg}"
        exit 1
      fi
      TARGET="$arg" ;;
  esac
done

# CI 模式：记录变更到 $CI_CHANGES_FILE 供 workflow 读取
CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 抓取上游（sparse-checkout skills/） ----------
fetch_upstream() {
  local tmp="$1"
  if ! git clone --depth 1 --filter=blob:none --sparse \
       "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$tmp" >/dev/null 2>&1; then
    echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
    return 1
  fi
  if ! (cd "$tmp" && git sparse-checkout set "$UPSTREAM_SUBDIR") >/dev/null 2>&1; then
    echo "❌ sparse-checkout 失败：$UPSTREAM_SUBDIR"
    return 1
  fi
  if [ ! -d "$tmp/$UPSTREAM_SUBDIR" ]; then
    echo "❌ 上游无 $UPSTREAM_SUBDIR 子目录，请检查仓库结构是否变更"
    return 1
  fi
}

# ---------- 自包含性自检 ----------
check_self_contained() {
  local dir="$1"
  local warnings=0

  local brother
  brother=$(grep -rn "import.*from\s*['\"]@\|require(['\"]@" \
    --include='*.py' --include='*.ts' --include='*.js' --include='*.mjs' \
    "$dir" 2>/dev/null | grep -vE 'node_modules|http[s]?://' || true)
  if [ -n "$brother" ]; then
    echo "  ⚠️  自检：发现兄弟包依赖（@xxx/yyy），vendor 可能断裂："
    echo "$brother" | head -5 | sed 's/^/      /'
    warnings=1
  fi

  # monorepo 相对路径依赖
  local rel
  rel=$(grep -rn "from ['\"]\\.\\./\\.\\./packages\|require(['\"]\\.\\./\\.\\./packages" \
    --include='*.py' --include='*.ts' --include='*.js' --include='*.mjs' \
    "$dir" 2>/dev/null || true)
  if [ -n "$rel" ]; then
    echo "  ⚠️  自检：发现 monorepo packages/ 相对路径依赖："
    echo "$rel" | head -5 | sed 's/^/      /'
    warnings=1
  fi

  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：无兄弟包依赖"
  else
    echo "  ❗ 自检告警：上游可能已重构为非自包含，请人工确认"
  fi
}

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local src="$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$skill"
  local vendor_dir="$PLUGIN_DIR/$skill"
  local commit_file="$vendor_dir/.upstream-commit"

  if [ ! -d "$src" ]; then
    echo "  ⚠️  上游已移除 ${skill}，本地保留（如需删除请手动）"
    return 0
  fi
  if [ ! -f "$src/SKILL.md" ]; then
    echo "  ⚠️  跳过 ${skill}：上游无 SKILL.md（可能不是 skill 目录）"
    return 0
  fi

  local new_commit="$UPSTREAM_COMMIT"
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ $skill 已是最新 ($new_commit)"
    return 0
  fi

  if [ -n "$old_commit" ]; then
    echo "  ⚡ $skill 有更新"
    echo "    旧: $old_commit"
    echo "    新: $new_commit"
  else
    echo "  ⚡ $skill 首次同步（无 .upstream-commit）"
    echo "    新: $new_commit"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️  dry-run，不修改"
    return 0
  fi

  mkdir -p "$vendor_dir"
  rsync -a --delete \
    --exclude='.upstream-commit' \
    --exclude='README.md' \
    --exclude='LICENSE' \
    --exclude='.git' \
    "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")

  check_self_contained "$vendor_dir"
}

# ---------- 主流程 ----------
echo "=== taste-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO ($UPSTREAM_SUBDIR/)"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

# 一次性抓上游
UPSTREAM_TMP=$(mktemp -d)
trap 'rm -rf "$UPSTREAM_TMP"' EXIT
fetch_upstream "$UPSTREAM_TMP"
UPSTREAM_COMMIT=$(cd "$UPSTREAM_TMP" && git rev-parse HEAD)
echo "上游 HEAD: $UPSTREAM_COMMIT"
echo ""

if [ -n "$TARGET" ]; then
  if [ ! -d "$PLUGIN_DIR/$TARGET" ] && [ "$DRY_RUN" = "1" ]; then
    echo "❌ 本地无 $TARGET（dry-run 不会新建）"
    exit 1
  fi
  if [ ! -d "$PLUGIN_DIR/$TARGET" ] && [ "$DRY_RUN" != "1" ]; then
    echo "  ℹ️  本地尚无 $TARGET，将从上游首次 vendor"
  fi
  sync_one "$TARGET"
else
  # 同步全部已 vendor 的 skill
  found_any=0
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    sync_one "$skill" || true
    found_any=1
  done < <(discover_skills)
  if [ "$found_any" = "0" ]; then
    echo "  （本地 taste 下无 skill 目录）"
  fi

  # 检测上游新增 skill（本地没有的）
  echo ""
  echo "--- 检测上游新增 ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/SKILL.md" ] || continue
    if [ ! -d "$PLUGIN_DIR/$sub" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$PLUGIN_DIR/$sub"
        rsync -a --delete \
          --exclude='.upstream-commit' \
          --exclude='README.md' \
          --exclude='LICENSE' \
          --exclude='.git' \
          "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/" "$PLUGIN_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$PLUGIN_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        UPDATED_SKILLS+=("$sub")
        local_added=1
        check_self_contained "$PLUGIN_DIR/$sub"
      fi
    fi
  done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SUBDIR" 2>/dev/null)
  if [ "$local_added" = "0" ]; then
    echo "  （无新增）"
  fi
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff skills/taste/  人工 review 后 commit"
fi

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
