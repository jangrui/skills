#!/usr/bin/env bash
# ============================================================================
# sync-illustration-skills.sh — 同步插图类上游更新到 vendor 目录
#
# 支持两个 skill（使用不同同步策略）：
#   1. ian-xiaohei-illustrations — SKILL.md 在子目录（sparse-checkout）
#   2. guizang-social-card       — SKILL.md 在根目录（浅克隆 + rsync）
#
# 用法：
#   ./scripts/sync-illustration-skills.sh                        # 全部
#   ./scripts/sync-illustration-skills.sh ian-xiaohei-illustrations  # 单个
#   ./scripts/sync-illustration-skills.sh --check                # dry-run
#
# 同步后请人工 review：
#   git diff plugins/illustration/
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/illustration"

SKILL_NAMES=(ian-xiaohei-illustrations guizang-social-card)

# skill key → (owner, repo, 上游子目录，同步策略)
# 上游子目录: SKILL.md 所在的上游目录（空字符串=根目录）
# 同步策略: "sparse" = sparse-checkout, "root" = 浅克隆+rsync
owner_of() {    case "$1" in ian-xiaohei-illustrations) echo "helloianneo" ;; guizang-social-card) echo "op7418" ;; *) echo "" ;; esac; }
repo_of() {     case "$1" in ian-xiaohei-illustrations) echo "ian-xiaohei-illustrations" ;; guizang-social-card) echo "guizang-social-card-skill" ;; *) echo "" ;; esac; }
subdir_of() {   case "$1" in ian-xiaohei-illustrations) echo "ian-xiaohei-illustrations" ;; guizang-social-card) echo "" ;; *) echo "" ;; esac; }

# ---------- 参数解析 ----------
# 支持任意位置的 --check/-n（避免 `script.sh ian-xiaohei-illustrations --check` 被当成真实同步）
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
      valid=0
      for s in "${SKILL_NAMES[@]}"; do [ "$s" = "$arg" ] && valid=1 && break; done
      [ "$valid" = "1" ] || { echo "❌ 未知 skill: ${arg}，可选: ${SKILL_NAMES[*]}"; exit 1; }
      TARGET="$arg" ;;
  esac
done

CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# ---------- 依赖检查 ----------
for cmd in git rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

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
  [ "$warnings" = "0" ] && echo "  ✅ 自检通过：无兄弟包依赖，vendor 安全" \
                       || echo "  ❗ 自检告警：上游可能已重构为非自包含，请人工确认"
}

# ---------- 同步策略 A：SKILL.md 在子目录（sparse-checkout）----------
sync_sparse() {
  local skill="$1"
  local owner; owner=$(owner_of "$skill")
  local repo; repo=$(repo_of "$skill")
  local subdir; subdir=$(subdir_of "$skill")
  local vendor_dir="$PLUGIN_DIR/$skill"
  local commit_file="$vendor_dir/.upstream-commit"

  local tmp
  tmp=$(mktemp -d)

  if ! git clone --depth 1 --filter=blob:none --sparse \
       "https://github.com/$owner/$repo.git" "$tmp/$repo" >/dev/null 2>&1; then
    echo "  ❌ clone 失败"
    rm -rf "$tmp"; return 1
  fi
  # 不要吞掉 sparse-checkout 失败：空源 + rsync --delete 会清空已有 vendor
  if ! (cd "$tmp/$repo" && git sparse-checkout set "$subdir") >/dev/null 2>&1; then
    echo "  ❌ sparse-checkout 失败：$subdir"
    rm -rf "$tmp"; return 1
  fi

  local src="$tmp/$repo/$subdir"
  if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
    echo "  ❌ 上游无 $subdir/SKILL.md"
    rm -rf "$tmp"; return 1
  fi

  local new_commit
  new_commit=$(cd "$tmp/$repo" && git rev-parse HEAD)
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ 已是最新 ($new_commit)"
    rm -rf "$tmp"; return 0
  fi

  [ -n "$old_commit" ] && echo "  ⚡ $old_commit → $new_commit" || echo "  ⚡ 首次同步 → $new_commit"
  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️ dry-run，不修改"
    rm -rf "$tmp"; return 0
  fi

  mkdir -p "$vendor_dir"
  rsync -a --delete --exclude='.upstream-commit' --exclude='agents/' "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新"
  UPDATED_SKILLS+=("$skill")
  check_self_contained "$vendor_dir" "$skill"
  rm -rf "$tmp"
}

# ---------- 同步策略 B：SKILL.md 在根目录（浅克隆 + rsync）----------
sync_root() {
  local skill="$1"
  local owner; owner=$(owner_of "$skill")
  local repo; repo=$(repo_of "$skill")
  local vendor_dir="$PLUGIN_DIR/$skill"
  local commit_file="$vendor_dir/.upstream-commit"

  local tmp
  tmp=$(mktemp -d)

  if ! git clone --depth 1 "https://github.com/$owner/$repo.git" "$tmp/$repo" >/dev/null 2>&1; then
    echo "  ❌ clone 失败"
    rm -rf "$tmp"; return 1
  fi

  local new_commit
  new_commit=$(cd "$tmp/$repo" && git rev-parse HEAD)
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ 已是最新 ($new_commit)"
    rm -rf "$tmp"; return 0
  fi

  [ -n "$old_commit" ] && echo "  ⚡ $old_commit → $new_commit" || echo "  ⚡ 首次同步 → $new_commit"
  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️ dry-run，不修改"
    rm -rf "$tmp"; return 0
  fi

  mkdir -p "$vendor_dir"
  rsync -a --delete \
    --exclude='.git/' \
    --exclude='.gitignore' \
    --exclude='AGENT.md' \
    --exclude='COMMERCIAL_LICENSING.md' \
    --exclude='HANDOFF.md' \
    --exclude='PRODUCT.md' \
    --exclude='LICENSE' \
    --exclude='README*' \
    --exclude='agents/' \
    --exclude='package-lock.json' \
    --exclude='.upstream-commit' \
    "$tmp/$repo/" "$vendor_dir/"
  rm -f "$vendor_dir/scripts/check-skill-docs.mjs"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新"
  UPDATED_SKILLS+=("$skill")
  check_self_contained "$vendor_dir" "$skill"
  rm -rf "$tmp"
}

# ---------- 主流程 ----------
echo "=== illustration-skills 同步工具 ==="
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

sync_one() {
  local skill="$1"
  local owner; owner=$(owner_of "$skill")
  local repo; repo=$(repo_of "$skill")
  echo "▶ $skill  ($owner/$repo)"
  if [ -z "$(subdir_of "$skill")" ]; then
    sync_root "$skill"
  else
    sync_sparse "$skill"
  fi
}

if [ -n "$TARGET" ]; then
  sync_one "$TARGET"
else
  for skill in "${SKILL_NAMES[@]}"; do
    sync_one "$skill"
    echo ""
  done
fi

echo "=== 完成 ==="
[ "$DRY_RUN" != "1" ] && echo "下一步：git diff plugins/illustration/  人工 review 后 commit"

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
