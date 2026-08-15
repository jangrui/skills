#!/usr/bin/env bash
# 由各 sync 脚本 source：只在已收录 skill 的实际内容发生变化时升市场组版本。

# 参数：仓库根目录、此次同步覆盖的 skills 范围、DRY_RUN 标识。
# 在任何 rsync 前调用，将内容指纹保存在当前 shell；--check 保持只读。
marketplace_version_snapshot() {
  local repo_root="$1"
  local scope="${2:-}"
  local dry_run="${3:-0}"

  if [ "$dry_run" = "1" ]; then
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 缺少依赖：python3（市场版本同步需要它）" >&2
    return 1
  fi
  if [ -z "$scope" ]; then
    scope="$repo_root/skills"
  fi

  MARKETPLACE_VERSION_REPO_ROOT="$repo_root"
  MARKETPLACE_VERSION_SCOPE="$scope"
  MARKETPLACE_VERSION_SNAPSHOT=$(python3 "$repo_root/scripts/bump-marketplace-versions.py" snapshot \
    --marketplace "$repo_root/.claude-plugin/marketplace.json" \
    --scope "$scope" \
    --output -)
}

# 参数：DRY_RUN 标识。依赖调用方已定义 UPDATED_SKILLS 数组。
# 仅在同步脚本成功完成后、写 CI_CHANGES_FILE 前调用。
marketplace_version_apply() {
  local dry_run="${1:-0}"
  if [ "$dry_run" = "1" ] || [ "${#UPDATED_SKILLS[@]}" -eq 0 ]; then
    return 0
  fi
  if [ -z "${MARKETPLACE_VERSION_SNAPSHOT:-}" ]; then
    echo "❌ 未找到同步前的市场版本快照" >&2
    return 1
  fi

  local version_command=(
    python3 "$MARKETPLACE_VERSION_REPO_ROOT/scripts/bump-marketplace-versions.py"
    apply
    --marketplace "$MARKETPLACE_VERSION_REPO_ROOT/.claude-plugin/marketplace.json"
    --scope "$MARKETPLACE_VERSION_SCOPE"
  )
  if [ "${MARKETPLACE_VERSION_DEFER:-0}" = "1" ]; then
    if [ -z "${MARKETPLACE_VERSION_GROUPS_FILE:-}" ]; then
      echo "❌ MARKETPLACE_VERSION_DEFER=1 时必须设置 MARKETPLACE_VERSION_GROUPS_FILE" >&2
      return 1
    fi
    version_command+=(--defer-file "$MARKETPLACE_VERSION_GROUPS_FILE")
  fi
  version_command+=(--before-stdin --updated "${UPDATED_SKILLS[@]}")

  if ! printf '%s' "$MARKETPLACE_VERSION_SNAPSHOT" | "${version_command[@]}"; then
    return 1
  fi
  unset MARKETPLACE_VERSION_SNAPSHOT MARKETPLACE_VERSION_SCOPE MARKETPLACE_VERSION_REPO_ROOT
}
