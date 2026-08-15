#!/usr/bin/env bash
# ============================================================================
# sync-grafana-skills.sh — 同步 grafana/skills 的上游 skill 到 vendor 目录
#
# 上游特点（与 lark 相似，但多嵌套一层 category）：
#   - 单仓库多 skill：grafana/skills 的 skills/ 下按 category 分组
#     skills/grafana-<category>/<skill>/SKILL.md
#   - 7 个 category：grafana-app-sdk / grafana-cloud / grafana-core /
#     grafana-datasources / grafana-k6 / grafana-lgtm / grafana-plugins
#   - 一次 sparse-checkout skills/ 即可拿到全部 48 个 skill，无需循环 clone
#   - 所有 skill 共享同一上游 commit（同一仓库的同一 HEAD）
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录（不要 .git/scripts/template/.github）
#   - 保留两层结构：skills/grafana/grafana-<category>/<skill>/
#   - 每个 skill 目录单独保存 .upstream-commit（同 lark 策略，便于单点回退）
#   - 同步后自动跑「自包含性自检」，防止上游引入兄弟包依赖导致 vendor 断裂
#
# 用法：
#   ./scripts/sync-grafana-skills.sh                          # 检查并同步全部
#   ./scripts/sync-grafana-skills.sh grafana-core/promql      # 只同步某个（category/skill）
#   ./scripts/sync-grafana-skills.sh grafana-k6               # 同步整个 category
#   ./scripts/sync-grafana-skills.sh --check                  # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff skills/grafana/<category>/<skill>/
#   git add skills/grafana/
#   git commit -m "chore(grafana): sync upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/grafana"
UPSTREAM_OWNER="grafana"
UPSTREAM_REPO="skills"
UPSTREAM_SUBDIR="skills"

# 当前 vendor 目录下已有的 category 列表（从本地目录扫描，而非硬编码）
discover_categories() {
  find "$PLUGIN_DIR" -maxdepth 1 -mindepth 1 -type d -name 'grafana-*' 2>/dev/null \
    | sed 's|.*/||' | sort
}

# 某个 category 下的 skill 列表（从本地目录扫描）
discover_skills_in() {
  local cat="$1"
  [ -d "$PLUGIN_DIR/$cat" ] || return 0
  find "$PLUGIN_DIR/$cat" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
    | sed 's|.*/||' | sort
}

# ---------- 参数解析 ----------
# 支持任意位置的 --check/-n（避免 `script.sh grafana-k6 --check` 被当成真实同步）
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's/^# \?//'
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

# ---------- 抓取上游（一次 sparse-checkout 拿全部 skill） ----------
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

# ---------- 自包含性自检（防止上游引入兄弟包依赖） ----------
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
  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：无兄弟包依赖"
  else
    echo "  ❗ 自检告警：上游可能已重构为非自包含，请人工确认是否改用整仓库引用"
  fi
}

# ---------- 同步单个 skill ----------
# 参数：category  skill
sync_one() {
  local cat="$1" skill="$2"
  local src="$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat/$skill"
  local vendor_dir="$PLUGIN_DIR/$cat/$skill"
  local commit_file="$vendor_dir/.upstream-commit"

  if [ ! -d "$src" ]; then
    echo "  ⚠️  上游已移除 ${cat}/${skill}，本地保留（如需删除请手动）"
    return 0
  fi
  if [ ! -f "$src/SKILL.md" ]; then
    echo "  ⚠️  跳过 ${cat}/${skill}：上游无 SKILL.md（可能不是 skill 目录）"
    return 0
  fi

  local new_commit="$UPSTREAM_COMMIT"
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ $cat/$skill 已是最新 ($new_commit)"
    return 0
  fi

  if [ -n "$old_commit" ]; then
    echo "  ⚡ $cat/$skill 有更新"
    echo "    旧: $old_commit"
    echo "    新: $new_commit"
  else
    echo "  ⚡ $cat/$skill 首次同步（无 .upstream-commit）"
    echo "    新: $new_commit"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️  dry-run，不修改"
    return 0
  fi

  mkdir -p "$vendor_dir"
  rsync -a --delete --exclude='.upstream-commit' "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $cat/$skill"
  UPDATED_SKILLS+=("$cat/$skill")

  check_self_contained "$vendor_dir"
}

# 同步整个 category
sync_category() {
  local cat="$1"
  echo "--- $cat ---"
  local found=0
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    sync_one "$cat" "$skill" || true
    found=1
  done < <(discover_skills_in "$cat")
  if [ "$found" = "0" ]; then
    echo "  （本地 $cat 下无 skill 目录）"
  fi
  return 0
}

# ---------- 主流程 ----------
echo "=== grafana-skills 同步工具 ==="
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

# 如果指定了 TARGET，按形式分派：含 / 视为 category/skill，否则视为 category
if [ -n "$TARGET" ]; then
  if [[ "$TARGET" == */* ]]; then
    # category/skill 形式
    cat="${TARGET%%/*}"
    skill="${TARGET#*/}"
    if [ ! -d "$PLUGIN_DIR/$cat/$skill" ]; then
      echo "❌ 本地无 $TARGET"
      echo "可选 category: $(discover_categories | tr '\n' ' ')"
      exit 1
    fi
    sync_one "$cat" "$skill"
  else
    # category 形式
    if [ ! -d "$PLUGIN_DIR/$TARGET" ]; then
      echo "❌ 本地无 category $TARGET"
      echo "可选: $(discover_categories | tr '\n' ' ')"
      exit 1
    fi
    sync_category "$TARGET"
  fi
else
  # 同步全部已 vendor 的 skill（扫本地 category）
  while IFS= read -r cat; do
    [ -n "$cat" ] || continue
    sync_category "$cat"
  done < <(discover_categories)

  # 检测上游新增的 category / skill（本地没有的）
  echo ""
  echo "--- 检测上游新增 ---"
  local_added=0
  while IFS= read -r cat; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat" ] || continue
    if [ ! -d "$PLUGIN_DIR/$cat" ]; then
      echo "  🆕 上游新增 category ${cat}（本地未 vendor）"
      local_added=1
    fi
    while IFS= read -r sub; do
      [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat/$sub" ] || continue
      [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat/$sub/SKILL.md" ] || continue
      if [ ! -d "$PLUGIN_DIR/$cat/$sub" ]; then
        echo "  🆕 上游新增 ${cat}/${sub}（本地未 vendor）"
        if [ "$DRY_RUN" = "1" ]; then
          echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
        else
          mkdir -p "$PLUGIN_DIR/$cat/$sub"
          rsync -a --delete --exclude='.upstream-commit' \
            "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat/$sub/" "$PLUGIN_DIR/$cat/$sub/"
          echo "$UPSTREAM_COMMIT" > "$PLUGIN_DIR/$cat/$sub/.upstream-commit"
          echo "  ✅ 已 vendor 新 skill: $cat/$sub"
          echo "  ⚠️  请手动把 \"$cat/$sub\" 加入根 .claude-plugin/marketplace.json 中对应 category plugin（名为 ${cat}）的 skills 数组"
          UPDATED_SKILLS+=("$cat/$sub")
          local_added=1
        fi
      fi
    done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$cat" 2>/dev/null)
  done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SUBDIR" 2>/dev/null)
  if [ "$local_added" = "0" ]; then
    echo "  （无新增）"
  fi
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff skills/grafana/  人工 review 后 commit"
fi

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
