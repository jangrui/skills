#!/usr/bin/env bash
# ============================================================================
# sync-lark-skills.sh — 同步飞书官方 lark-cli 的上游 skill 到 vendor 目录
#
# 上游特点（与 diagram / writing 不同）：
#   - 单仓库多 skill：larksuite/cli 的 skills/ 下有 27 个 lark-* 子目录
#   - 一次 sparse-checkout skills/ 即可拿到全部，无需循环 clone 27 次
#   - 所有 skill 共享同一上游 commit（同一仓库的同一 HEAD）
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录（不要 .git/cmd/internal/tests）
#   - 每个 skill 目录单独保存 .upstream-commit（虽然值相同，但便于单 skill 回退定位）
#   - 同步后自动跑「自包含性自检」，防止上游引入兄弟包依赖导致 vendor 断裂
#
# 用法：
#   ./scripts/sync-lark-skills.sh                  # 检查并同步全部
#   ./scripts/sync-lark-skills.sh lark-base        # 只同步 lark-base
#   ./scripts/sync-lark-skills.sh --check          # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/lark/<name>/
#   git add plugins/lark/
#   git commit -m "chore(lark): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/lark"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="larksuite"
UPSTREAM_REPO="cli"
UPSTREAM_SUBDIR="skills"

# 当前 vendor 目录下已有的 skill 列表（从本地目录扫描，而非硬编码——上游新增 skill 时自动纳入）
discover_skills() {
  # 兼容 BSD find（macOS）与 GNU find：不用 -printf
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -name 'lark-*' 2>/dev/null \
    | sed 's|.*/||' | grep -v '^\.claude-plugin$' | sort
}

# ---------- 参数解析 ----------
DRY_RUN=0
TARGET=""
case "${1:-}" in
  --check|-n) DRY_RUN=1 ;;
  -h|--help)
    sed -n '2,24p' "$0" | sed 's/^# \?//'
    exit 0 ;;
  "") : ;;  # 全部
  *) TARGET="$1" ;;
esac

# CI 模式：记录变更到 $CI_CHANGES_FILE 供 workflow 读取
CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 抓取上游（一次 sparse-checkout 拿全部 skill） ----------
fetch_upstream() {
  local tmp="$1"
  if ! git clone --depth 1 --filter=blob:none --sparse \
       "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$tmp" >/dev/null 2>&1; then
    echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
    return 1
  fi
  (cd "$tmp" && git sparse-checkout set "$UPSTREAM_SUBDIR") 2>/dev/null || true
  if [ ! -d "$tmp/$UPSTREAM_SUBDIR" ]; then
    echo "❌ 上游无 $UPSTREAM_SUBDIR 子目录，请检查仓库结构是否变更"
    return 1
  fi
}

# ---------- 自包含性自检（防止上游引入兄弟包依赖）----------
check_self_contained() {
  local dir="$1" skill="$2"
  local warnings=0

  # 检查：可执行脚本里是否 import @xxx/yyy 形式的兄弟包
  local brother
  brother=$(grep -rn "import.*from\s*['\"]@\|require(['\"]@" \
    --include='*.py' --include='*.ts' --include='*.js' --include='*.mjs' \
    "$dir" 2>/dev/null | grep -vE 'node_modules|http[s]?://' || true)
  if [ -n "$brother" ]; then
    echo "  ⚠️  自检：发现兄弟包依赖（@xxx/yyy），vendor 可能断裂："
    echo "$brother" | head -5 | sed 's/^/      /'
    warnings=1
  fi
  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：无兄弟包依赖"
  else
    echo "  ❗ 自检告警：上游可能已重构为非自包含，请人工确认是否改用整仓库引用"
  fi
}

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local src="$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$skill"
  local vendor_dir="$SKILLS_DIR/$skill"
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
  rsync -a --delete --exclude='.upstream-commit' "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")

  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 主流程 ----------
echo "=== lark-skills 同步工具 ==="
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

# 如果指定了 TARGET，校验并只同步一个；否则扫本地目录同步全部
if [ -n "$TARGET" ]; then
  if [ ! -d "$SKILLS_DIR/$TARGET" ]; then
    echo "❌ 本地无 ${TARGET}（本地目录名即 skill key，如 lark-base）"
    echo "可选: $(discover_skills | tr '\n' ' ')"
    exit 1
  fi
  sync_one "$TARGET"
else
  # 同时检测上游新增的 skill（本地没有的）
  echo "--- 同步已 vendor 的 skill ---"
  while IFS= read -r skill; do
    sync_one "$skill" || true
  done < <(discover_skills)

  # 检测上游新增
  echo ""
  echo "--- 检测上游新增 skill ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/SKILL.md" ] || continue
    if [ ! -d "$SKILLS_DIR/$sub" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$SKILLS_DIR/$sub"
        rsync -a --delete --exclude='.upstream-commit' "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        echo "  ⚠️  请手动编辑 plugins/lark/.claude-plugin/plugin.json 和 marketplace.json 的 skills 数组加入 \"$sub\""
        UPDATED_SKILLS+=("$sub")
        local_added=1
      fi
    fi
  done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SUBDIR")
  [ "$local_added" = "0" ] && echo "  （无新增）"
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff plugins/lark/  人工 review 后 commit"
fi

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
