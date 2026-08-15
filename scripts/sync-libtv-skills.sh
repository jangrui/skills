#!/usr/bin/env bash
# ============================================================================
# sync-libtv-skills.sh — 同步 libtv-labs/libtv-skills 上游 skill 到 vendor 目录
#
# 上游特点：
#   - 单仓库单 skill 形态（当前仅 skills/libtv-skill/ 一个 skill）
#   - SKILL.md 在 skills/<name>/ 子目录，可用 sparse-checkout
#   - skill 为 Python 脚本（仅标准库），运行时依赖 python3 + LIBTV_ACCESS_KEY
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录
#   - 每个 skill 目录保存 .upstream-commit
#   - 同步后跑自包含性自检
#
# 用法：
#   ./scripts/sync-libtv-skills.sh              # 检查并同步全部
#   ./scripts/sync-libtv-skills.sh libtv-skill  # 只同步 libtv-skill
#   ./scripts/sync-libtv-skills.sh --check      # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff skills/libtv/
#   git add skills/libtv/
#   git commit -m "chore(libtv): sync upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/libtv"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="libtv-labs"
UPSTREAM_REPO="libtv-skills"
UPSTREAM_SUBDIR="skills"

# 当前 vendor 目录下已有的 skill 列表（从本地目录扫描）
discover_skills() {
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
    | sed 's|.*/||' | grep -v '^\.claude-plugin$' | sort
}

# ---------- 参数解析 ----------
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,22p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    -*)
      echo "❌ 未知参数：${arg}"
      exit 1 ;;
    *)
      if [ -n "$TARGET" ]; then
        echo "❌ 只能指定一个 skill，已有：${TARGET}，又收到：${arg}"
        exit 1
      fi
      TARGET="$arg" ;;
  esac
done

CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 抓取上游 ----------
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
  local dir="$1" skill="$2"
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
  # 首次同步（无旧 commit）时不带 --delete，避免源异常时误清
  # --exclude='__pycache__'：防御上游误提交 .pyc 缓存产物
  if [ -n "$old_commit" ]; then
    rsync -a --delete --exclude='.upstream-commit' --exclude='__pycache__' "$src/" "$vendor_dir/"
  else
    rsync -a --exclude='.upstream-commit' --exclude='__pycache__' "$src/" "$vendor_dir/"
  fi
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")

  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 主流程 ----------
echo "=== libtv-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO ($UPSTREAM_SUBDIR/)"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

UPSTREAM_TMP=$(mktemp -d)
# 必须用 EXIT：macOS 系统 bash 3.2 在脚本顶层不会触发 RETURN trap
trap 'rm -rf "$UPSTREAM_TMP"' EXIT
fetch_upstream "$UPSTREAM_TMP"
UPSTREAM_COMMIT=$(cd "$UPSTREAM_TMP" && git rev-parse HEAD)
echo "上游 HEAD: $UPSTREAM_COMMIT"
echo ""

if [ -n "$TARGET" ]; then
  if [ ! -d "$SKILLS_DIR/$TARGET" ]; then
    echo "❌ 本地无 ${TARGET}（本地目录名即 skill key，如 libtv-skill）"
    echo "可选: $(discover_skills | tr '\n' ' ')"
    exit 1
  fi
  sync_one "$TARGET"
else
  echo "--- 同步已 vendor 的 skill ---"
  while IFS= read -r skill; do
    sync_one "$skill" || true
  done < <(discover_skills)

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
        rsync -a --exclude='.upstream-commit' --exclude='__pycache__' \
          "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        echo "  ⚠️  请手动编辑 .claude-plugin/marketplace.json 的 plugins 数组加入 libtv 条目（如尚未添加）"
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
  echo "下一步：git diff skills/libtv/  人工 review 后 commit"
fi

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
