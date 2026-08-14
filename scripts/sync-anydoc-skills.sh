#!/usr/bin/env bash
# ============================================================================
# sync-anydoc-skills.sh — 同步 firecrawl/anydoc 上游 skill 到 vendor 目录
#
# 上游特点：
#   - 单仓库单 skill（未来可能扩展），skill 在 skills/<name>/ 子目录
#   - 上游主体是 Rust 库 + Node/Python/WASM 绑定，仓库巨大；skill 目录
#     与代码分离，sparse-checkout 只拉 skills/ 目录（cone 模式认目录，
#     此处合法：skills/ 是目录而非根目录文件）
#   - skill 为纯 SKILL.md，运行时依赖 npx @firecrawl/anydoc（npm 已发布，
#     已验证），Node 20+ 免安装
#
# 机制：
#   - git sparse-checkout cone 模式拉上游 skills/ 目录
#   - 每个 skill 目录单独保存 .upstream-commit
#   - 自动检测上游新增 skill
#
# 用法：
#   ./scripts/sync-anydoc-skills.sh                     # 检查并同步全部
#   ./scripts/sync-anydoc-skills.sh convert-documents-to-markdown
#   ./scripts/sync-anydoc-skills.sh --check             # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/anydoc/<name>/
#   git add plugins/anydoc/
#   git commit -m "chore(anydoc): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/anydoc"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="firecrawl"
UPSTREAM_REPO="anydoc"
UPSTREAM_SKILLS_SUBDIR="skills"

# rsync 排除规则（通用约定：不 vendor README/LICENSE/agents/.github 等）
RSYNC_EXCLUDES=(
  --exclude='.upstream-commit'
  --exclude='.git'
  --exclude='.github'
  --exclude='.claude-plugin'
  --exclude='agents'
  --exclude='README*'
  --exclude='LICENSE'
)

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
      sed -n '2,30p' "$0" | sed 's/^# \?//'
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
# 上游仓库含完整 Rust 源码 + 测试 fixture，很大；用 --filter=blob:none
# 的稀疏克隆只检出 skills/ 目录，避免拉整个仓库。
fetch_upstream() {
  local tmp="$1"
  if ! git clone --depth 1 --filter=blob:none --sparse \
      "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$tmp" >/dev/null 2>&1; then
    echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
    return 1
  fi
  if ! (cd "$tmp" && git sparse-checkout set "$UPSTREAM_SKILLS_SUBDIR") >/dev/null 2>&1; then
    echo "❌ sparse-checkout 失败：$UPSTREAM_SKILLS_SUBDIR（上游结构可能已变）"
    return 1
  fi
}

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local src="$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$skill"
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
  # 首次同步无 old_commit 时不带 --delete（目标可能为空，删无可删）；
  # 后续同步带 --delete 以清理上游已删除的文件。
  rsync -a ${old_commit:+--delete} "${RSYNC_EXCLUDES[@]}" "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")
}

# ---------- 主流程 ----------
echo "=== anydoc 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/${UPSTREAM_REPO}（skill 在 $UPSTREAM_SKILLS_SUBDIR/ 子目录）"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

UPSTREAM_TMP=$(mktemp -d)
trap 'rm -rf "$UPSTREAM_TMP"' EXIT
fetch_upstream "$UPSTREAM_TMP"
# 注意：必须在 clone 目录内取 commit hash
UPSTREAM_COMMIT=$(cd "$UPSTREAM_TMP" && git rev-parse HEAD)
echo "上游 HEAD: $UPSTREAM_COMMIT"
echo ""

if [ -n "$TARGET" ]; then
  if [ ! -d "$SKILLS_DIR/$TARGET" ] && [ "$DRY_RUN" != "1" ]; then
    if [ ! -d "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$TARGET" ]; then
      echo "❌ 上游无 ${TARGET}"
      exit 1
    fi
    if [ ! -f "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$TARGET/SKILL.md" ]; then
      echo "❌ 上游 ${TARGET} 无 SKILL.md，不是 skill 目录"
      exit 1
    fi
  fi
  sync_one "$TARGET"
else
  echo "--- 同步已 vendor 的 skill ---"
  local_count=0
  while IFS= read -r skill; do
    sync_one "$skill" || true
    local_count=$((local_count + 1))
  done < <(discover_skills)
  if [ "$local_count" = "0" ]; then
    echo "  （本地尚无 anydoc skill，将全部从上游首次 vendor）"
  fi

  echo ""
  echo "--- 检测上游新增 skill ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$sub/SKILL.md" ] || continue
    if [ ! -d "$SKILLS_DIR/$sub" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$SKILLS_DIR/$sub"
        rsync -a "${RSYNC_EXCLUDES[@]}" "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        echo "  ⚠️  请手动编辑 plugins/anydoc/.claude-plugin/plugin.json 和 marketplace.json 的 skills 数组加入 \"$sub\""
        UPDATED_SKILLS+=("$sub")
        local_added=1
      fi
    fi
  done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SKILLS_SUBDIR")
  [ "$local_added" = "0" ] && echo "  （无新增）"
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff plugins/anydoc/  人工 review 后 commit"
fi

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
