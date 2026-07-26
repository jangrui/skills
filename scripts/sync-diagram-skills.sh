#!/usr/bin/env bash
# ============================================================================
# sync-diagram-skills.sh — 同步绘图五件套上游更新到 vendor 目录
#
# 机制：
#   - 用 git sparse-checkout 只拉上游仓库的 skills/<name>/ 子目录（不要 .git/tests/docs）
#   - 用 .upstream-commit 记录当前 vendor 的上游 commit，秒判是否最新
#   - 同步后自动跑「自包含性自检」，防止上游引入兄弟包依赖导致 vendor 断裂
#
# 用法：
#   ./scripts/sync-diagram-skills.sh             # 检查并同步全部 5 个
#   ./scripts/sync-diagram-skills.sh drawio      # 只同步 drawio
#   ./scripts/sync-diagram-skills.sh --check     # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/diagram/<name>/
#   git add plugins/diagram/
#   git commit -m "chore(diagram): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/diagram"
SKILLS_DIR="$PLUGIN_DIR"          # skill 直接放在 plugin 根下，无中间 skills/ 层
UPSTREAM_OWNER="Agents365-ai"

# skill 的三个名字（B 方案：本地目录名去掉 -skill 后缀）：
#   - skill key:     drawio              (用户传参、日志显示)
#   - 本地目录名:     drawio              (vendor 后的目录，已去后缀)
#   - 上游仓库名:     drawio-skill        (clone 用的 repo 名)
#   - 上游子目录名:   skills/drawio-skill (sparse-checkout 路径)
SKILL_NAMES=(drawio mermaid excalidraw tldraw plantuml)
repo_for() {                # skill key → 上游仓库名
  case "$1" in
    drawio)     echo "drawio-skill" ;;
    mermaid)    echo "mermaid-skill" ;;
    excalidraw) echo "excalidraw-skill" ;;
    tldraw)     echo "tldraw-skill" ;;
    plantuml)   echo "plantuml-skill" ;;
    *) echo "$1-skill" ;;
  esac
}
local_name() {              # skill key → 本地 vendor 目录名（= skill key，去后缀）
  echo "$1"
}

# ---------- 参数解析 ----------
# 支持任意位置的 --check/-n（避免 `script.sh drawio --check` 被当成真实同步）
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
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

# CI 模式：记录变更到 $CI_CHANGES_FILE 供 workflow 读取
CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local repo
  repo=$(repo_for "$skill")
  local localdir
  localdir=$(local_name "$skill")
  local vendor_dir="$SKILLS_DIR/$localdir"
  local commit_file="$vendor_dir/.upstream-commit"

  echo "▶ $skill  (upstream: $UPSTREAM_OWNER/$repo → local: $localdir)"

  # 抓取上游（sparse 只取 skills/<repo>/）
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  if ! git clone --depth 1 --filter=blob:none --sparse \
       "https://github.com/$UPSTREAM_OWNER/$repo.git" "$tmp/$repo" >/dev/null 2>&1; then
    echo "  ❌ clone 失败：$UPSTREAM_OWNER/$repo"
    return 1
  fi
  # 不要吞掉 sparse-checkout 失败：空源 + rsync --delete 会清空已有 vendor
  if ! (cd "$tmp/$repo" && git sparse-checkout set "skills/$repo") >/dev/null 2>&1; then
    echo "  ❌ sparse-checkout 失败：skills/$repo"
    return 1
  fi

  local src="$tmp/$repo/skills/$repo"
  if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
    echo "  ❌ 上游无 skills/$repo/SKILL.md，请检查仓库结构是否变更"
    return 1
  fi

  local new_commit
  new_commit=$(cd "$tmp/$repo" && git rev-parse HEAD)
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  # 判断是否有更新
  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ 已是最新 ($new_commit)"
    return 0
  fi

  if [ -n "$old_commit" ]; then
    echo "  ⚡ 有更新"
    echo "    旧: $old_commit"
    echo "    新: $new_commit"
    # 尝试拉旧 commit 做 diff（depth=1 拉不到历史时降级为只提示）
    local diff_url="https://github.com/$UPSTREAM_OWNER/$repo/compare/$old_commit...$new_commit"
    echo "    diff: $diff_url"
  else
    echo "  ⚡ 首次同步（无 .upstream-commit 记录）"
    echo "    新: $new_commit"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️  dry-run 模式，不修改文件"
    return 0
  fi

  # 用 rsync 同步：--delete 删除上游已删的文件，但保留 .upstream-commit
  mkdir -p "$vendor_dir"
  rsync -a --delete --exclude='.upstream-commit' "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新到 $new_commit"
  UPDATED_SKILLS+=("$skill")

  # 同步后自检
  check_self_contained "$vendor_dir" "$skill"
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

  # 检查：skill 内 package.json 是否新增外部依赖
  local pj
  pj=$(find "$dir" -name package.json -not -path '*/node_modules/*' 2>/dev/null || true)
  if [ -n "$pj" ]; then
    while IFS= read -r f; do
      local deps
      deps=$(python3 -c "
import json,sys
try:
    d=json.load(open('$f'))
    dd=d.get('dependencies',{})
    print(' , '.join(dd.keys()) if dd else '')
except: pass
" 2>/dev/null || true)
      if [ -n "$deps" ]; then
        echo "  ⚠️  自检：$f 声明外部依赖：$deps"
        warnings=1
      fi
    done <<< "$pj"
  fi

  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：无兄弟包依赖，vendor 安全"
  else
    echo "  ❗ 自检告警：上游可能已重构为非自包含，请人工确认是否改用整仓库引用"
  fi
}

# ---------- 主流程 ----------
echo "=== diagram-skills 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

if [ -n "$TARGET" ]; then
  # 校验 skill 名合法
  valid=0
  for s in "${SKILL_NAMES[@]}"; do [ "$s" = "$TARGET" ] && valid=1 && break; done
  if [ "$valid" = "0" ]; then
    echo "❌ 未知 skill：$TARGET"
    echo "可选: ${SKILL_NAMES[*]}"
    exit 1
  fi
  sync_one "$TARGET"
else
  for skill in "${SKILL_NAMES[@]}"; do
    sync_one "$skill" || true
    echo ""
  done
fi

echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff plugins/diagram/  人工 review 后 commit"
fi

# CI 模式：把本次更新的 skill 列表写入文件，供 workflow 读取决定是否开 PR
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
