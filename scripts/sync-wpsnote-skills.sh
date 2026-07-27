#!/usr/bin/env bash
# ============================================================================
# sync-wpsnote-skills.sh — 同步 wpsnote/wpsnote-skills 上游 skill 到 vendor 目录
#
# 上游特点（单仓库多 skill / 扁平）：
#   - wpsnote/wpsnote-skills 的 skills/ 下有 36 个 skill 子目录（无统一前缀）
#   - 一次 sparse-checkout skills/ 即可拿到全部
#   - 所有 skill 共享同一上游 commit
#   - 运行时主要依赖外部 CLI：wpsnote-cli（由 WPS 笔记「AI 实验室」提供）
#   - 部分 skill 含 Python 脚本（stdlib + 可选 pip 包：httpx/bs4/requests 等）
#   - image-gen / xiaohongshu 的 image_gen.py 已内联到各自 scripts/，
#     无需 vendor 上游根目录 comm_script/
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录
#   - 每个 skill 目录单独保存 .upstream-commit
#   - rsync 排除 tests/ 等非运行时噪声
#   - 同步后跑「自包含性自检」
#
# 用法：
#   ./scripts/sync-wpsnote-skills.sh                      # 检查并同步全部
#   ./scripts/sync-wpsnote-skills.sh wps-note             # 只同步 wps-note
#   ./scripts/sync-wpsnote-skills.sh --check              # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/wpsnote/<name>/
#   git add plugins/wpsnote/
#   git commit -m "chore(wpsnote): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/wpsnote"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="wpsnote"
UPSTREAM_REPO="wpsnote-skills"
UPSTREAM_SUBDIR="skills"

# 当前 vendor 目录下已有的 skill 列表（目录内含 SKILL.md，排除 .claude-plugin）
discover_skills() {
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
    | sed 's|.*/||' \
    | grep -v '^\.claude-plugin$' \
    | while IFS= read -r d; do
        [ -f "$SKILLS_DIR/$d/SKILL.md" ] && echo "$d"
      done \
    | sort
}

# ---------- 参数解析 ----------
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,36p' "$0" | sed 's/^# \?//'
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
# 允许：skill 内 scripts/bin/references、外部 CLI wpsnote-cli、公开 pip 包
# 告警：引用 skill 目录之外的 monorepo / comm_script 路径且本地无 scripts 副本
check_self_contained() {
  local dir="$1" skill="$2"
  local warnings=0

  if [ ! -f "$dir/SKILL.md" ]; then
    echo "  ⚠️  自检：缺少 SKILL.md"
    return 1
  fi

  # 相对路径跳出 skill 目录引用 monorepo / 公共脚本
  local outside
  outside=$(grep -rnE "comm_script/|packages/|from ['\"]\.\./\.\./" \
    --include='*.py' --include='*.sh' --include='*.md' \
    "$dir" 2>/dev/null \
    | grep -vE 'node_modules|/\.upstream-commit|tests/' || true)
  if [ -n "$outside" ]; then
    # 若 skill 自己 scripts/ 下已有同名脚本，仅提示，不视为断裂
    if [ -d "$dir/scripts" ] || [ -d "$dir/bin" ]; then
      echo "  ℹ️  自检：文档/元数据提到目录外路径，但本地 scripts|bin 存在，可运行"
    else
      echo "  ⚠️  自检：发现目录外路径引用，且无本地 scripts/bin 副本："
      echo "$outside" | head -5 | sed 's/^/      /'
      warnings=1
    fi
  fi

  if [ "$warnings" -eq 0 ]; then
    echo "  ✅ 自检通过"
  fi
  return 0
}

# rsync 排除项：保留运行时 scripts/bin/references/docs/assets，去掉测试噪声
RSYNC_EXCLUDES=(
  --exclude='.upstream-commit'
  --exclude='tests/'
  --exclude='**/__pycache__/'
  --exclude='*.pyc'
  --exclude='.pytest_cache/'
)

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local vendor_dir="$SKILLS_DIR/$skill"
  local src="$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$skill"
  local commit_file="$vendor_dir/.upstream-commit"
  local old_commit="" new_commit="$UPSTREAM_COMMIT"

  if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
    echo "  ⚠️  上游无 $skill/SKILL.md，跳过"
    return 0
  fi

  if [ -f "$commit_file" ]; then
    old_commit=$(tr -d '[:space:]' < "$commit_file")
  fi

  if [ -n "$old_commit" ] && [ "$old_commit" = "$new_commit" ]; then
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
  # 首次无旧 commit 时不带 --delete，降低误清风险；后续带上清理上游已删文件
  if [ -n "$old_commit" ]; then
    rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$src/" "$vendor_dir/"
  else
    rsync -a "${RSYNC_EXCLUDES[@]}" "$src/" "$vendor_dir/"
  fi
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")
  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 主流程 ----------
echo "=== wpsnote-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO ($UPSTREAM_SUBDIR/)"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

mkdir -p "$SKILLS_DIR"

# 一次性抓上游
UPSTREAM_TMP=$(mktemp -d)
trap 'rm -rf "$UPSTREAM_TMP"' EXIT
fetch_upstream "$UPSTREAM_TMP"
UPSTREAM_COMMIT=$(cd "$UPSTREAM_TMP" && git rev-parse HEAD)
echo "上游 HEAD: $UPSTREAM_COMMIT"
echo ""

if [ -n "$TARGET" ]; then
  if [ ! -d "$SKILLS_DIR/$TARGET" ] && [ ! -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$TARGET" ]; then
    echo "❌ 本地与上游均无 ${TARGET}"
    echo "可选: $(discover_skills | tr '\n' ' ')"
    exit 1
  fi
  # 允许首次直接指定上游已有、本地尚未 vendor 的 skill
  if [ ! -d "$SKILLS_DIR/$TARGET" ] && [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$SKILLS_DIR/$TARGET"
  fi
  sync_one "$TARGET"
else
  echo "--- 同步已 vendor 的 skill ---"
  local_count=0
  while IFS= read -r skill; do
    local_count=$((local_count + 1))
    sync_one "$skill" || true
  done < <(discover_skills)
  [ "$local_count" = "0" ] && echo "  （本地尚无 vendored skill）"

  echo ""
  echo "--- 检测上游新增 skill ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/SKILL.md" ] || continue
    if [ ! -d "$SKILLS_DIR/$sub" ] || [ ! -f "$SKILLS_DIR/$sub/SKILL.md" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$SKILLS_DIR/$sub"
        rsync -a "${RSYNC_EXCLUDES[@]}" \
          "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        check_self_contained "$SKILLS_DIR/$sub" "$sub"
        echo "  ⚠️  请手动编辑 plugins/wpsnote/.claude-plugin/plugin.json 和 marketplace.json 的 skills 数组加入 \"$sub\""
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
  echo "下一步：git diff plugins/wpsnote/  人工 review 后 commit"
fi

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
