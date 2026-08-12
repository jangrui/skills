#!/usr/bin/env bash
# ============================================================================
# sync-writing-skills.sh — 同步写作润色类 skill 的上游更新到 vendor 目录
#
# 当前覆盖：humanizer-zh (op7418/Humanizer-zh)、stop-slop (hardikpandya/stop-slop)
#
# 与 sync-diagram-skills.sh 的差异：
#   - humanizer-zh 上游是「根目录即 skill」（SKILL.md 在仓库根，无 skills/ 子目录）
#   - 因此用整仓库浅克隆 + rsync 精选文件（SKILL.md + LICENSE），
#     而非 sparse-checkout skills/<name>/
#
# 机制：
#   - git clone --depth 1 浅克隆上游（仅 4 个文件，体积可忽略）
#   - rsync 只取 SKILL.md + skill 自带子目录（丢弃 README/LICENSE/.gitignore 等仓库级文件）
#   - 用 .upstream-commit 记录当前 vendor 的上游 commit，秒判是否最新
#   - 同步后自动跑「自包含性自检」
#
# 用法：
#   ./scripts/sync-writing-skills.sh             # 检查并同步全部
#   ./scripts/sync-writing-skills.sh humanizer-zh # 只同步指定
#   ./scripts/sync-writing-skills.sh --check      # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/writing/<name>/
#   git add plugins/writing/
#   git commit -m "chore(writing): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/writing"

# skill 元数据：key | 本地目录名 | 上游 owner | 上游 repo | 上游 skill 路径模式
#   path_mode:
#     root   = 上游根目录即 skill（如 humanizer、Humanizer-zh）
#     subdir = 上游 skills/<name>/ 下（如 baoyu 那种，预留）
# 注：humanizer (blader/humanizer) 虽本身是标准 plugin，但为与 humanizer-zh 共用
#     writing 聚合项，按 B 方案 vendor 进来（只取 SKILL.md，排除上游 plugin 声明）
SKILL_NAMES=(humanizer humanizer-zh stop-slop)
meta_for() {
  case "$1" in
    humanizer)
      # local_dir|owner|repo|path_mode
      echo "humanizer|blader|humanizer|root"
      ;;
    humanizer-zh)
      echo "humanizer-zh|op7418|Humanizer-zh|root"
      ;;
    stop-slop)
      echo "stop-slop|hardikpandya|stop-slop|root"
      ;;
    *) return 1 ;;
  esac
}

# ---------- 参数解析 ----------
# 支持任意位置的 --check/-n（避免 `script.sh humanizer --check` 被当成真实同步）
DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \?//'
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
  local meta
  meta=$(meta_for "$skill") || { echo "❌ 未知 skill：$skill"; return 1; }
  local localdir owner repo path_mode
  IFS='|' read -r localdir owner repo path_mode <<< "$meta"
  local vendor_dir="$PLUGIN_DIR/$localdir"
  local commit_file="$vendor_dir/.upstream-commit"

  echo "▶ $skill  (upstream: $owner/$repo → local: $localdir, mode: $path_mode)"

  # 浅克隆上游（这些仓库都很小，整仓克隆即可）
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  if ! git clone --depth 1 "https://github.com/$owner/$repo.git" "$tmp/$repo" >/dev/null 2>&1; then
    echo "  ❌ clone 失败：$owner/$repo"
    return 1
  fi

  local src
  case "$path_mode" in
    root)   src="$tmp/$repo" ;;                              # 根目录即 skill
    subdir) src="$tmp/$repo/skills/$localdir" ;;             # skills/<name>/ 下
    *) echo "  ❌ 未知 path_mode: $path_mode"; return 1 ;;
  esac

  if [ ! -f "$src/SKILL.md" ]; then
    echo "  ❌ $src 下无 SKILL.md，请检查上游结构是否变更"
    return 1
  fi

  local new_commit
  new_commit=$(cd "$tmp/$repo" && git rev-parse HEAD)
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ 已是最新 ($new_commit)"
    return 0
  fi

  if [ -n "$old_commit" ]; then
    echo "  ⚡ 有更新"
    echo "    旧: $old_commit"
    echo "    新: $new_commit"
    echo "    diff: https://github.com/$owner/$repo/compare/$old_commit...$new_commit"
  else
    echo "  ⚡ 首次同步（无 .upstream-commit 记录）"
    echo "    新: $new_commit"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️  dry-run 模式，不修改文件"
    return 0
  fi

  # rsync 精选 skill 本体文件：SKILL.md + 同目录下的子目录(references 等)
  # 排除所有仓库级/非运行时文件：
  #   .claude-plugin/  上游 plugin 声明（避免和本 writing plugin.json 冲突）
  #   agents/          上游的 OpenAI Codex 展示配置等
  #   scripts/         上游的 CI/校验脚本（如 humanizer 的 validate-package.py）
  #   .github/         上游 CI
  #   AGENTS.md        上游 agent 指南
  #   README/LICENSE   文档与许可证
  mkdir -p "$vendor_dir"
  rsync -a --delete \
    --exclude='.upstream-commit' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='.claude-plugin' \
    --exclude='.github' \
    --exclude='agents' \
    --exclude='scripts' \
    --exclude='AGENTS.md' \
    --exclude='LICENSE' \
    --exclude='CHANGELOG.md' \
    --exclude='README.md' \
    --exclude='README.zh.md' \
    --exclude='package.json' \
    --exclude='package-lock.json' \
    --exclude='node_modules' \
    "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新到 $new_commit"
  UPDATED_SKILLS+=("$skill")

  # 同步后自检
  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 自包含性自检 ----------
check_self_contained() {
  local dir="$1" skill="$2"
  local warnings=0

  # 检查：是否有 SKILL.md
  if [ ! -f "$dir/SKILL.md" ]; then
    echo "  ⚠️  自检：缺 SKILL.md"
    warnings=1
  fi

  # 检查：可执行脚本里是否 import 兄弟包
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
    echo "  ✅ 自检通过：SKILL.md 就位，无兄弟包依赖"
  else
    echo "  ❗ 自检告警：请人工确认是否改用整仓库引用"
  fi
}

# ---------- 主流程 ----------
echo "=== writing-skills 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

if [ -n "$TARGET" ]; then
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
  echo "下一步：git diff plugins/writing/  人工 review 后 commit"
fi

# CI 模式：把本次更新的 skill 列表写入文件
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
