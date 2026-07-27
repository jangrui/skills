#!/usr/bin/env bash
# ============================================================================
# sync-mattpocock-skills.sh — 同步 mattpocock/skills 的上游 skill 到 vendor 目录
#
# 上游特点（单仓库多 skill / 两层 bucket，但只 vendor promoted 两桶）：
#   - 单仓库多 skill：mattpocock/skills 的 skills/ 下按 bucket 分组
#     skills/engineering/<skill>/SKILL.md
#     skills/productivity/<skill>/SKILL.md
#   - 仅 engineering/ + productivity/ 为 promoted（与上游 .claude-plugin/plugin.json 一致）
#   - 故意不 vendor：misc/ / personal/ / in-progress/ / deprecated/
#   - 一次 sparse-checkout skills/ 即可拿到全部，再按白名单桶 rsync
#   - 所有 skill 共享同一上游 commit
#   - 纯 md + agents/openai.yaml（+ 极少数 shell 模板），无 monorepo 兄弟包
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录
#   - 保留两层结构：plugins/mattpocock/{engineering,productivity}/<skill>/
#   - 每个 skill 目录单独保存 .upstream-commit
#   - 同步后跑「自包含性自检」+ 与上游 plugin.json promoted 白名单对照
#
# 用法：
#   ./scripts/sync-mattpocock-skills.sh                          # 检查并同步全部
#   ./scripts/sync-mattpocock-skills.sh engineering/tdd          # 只同步某个
#   ./scripts/sync-mattpocock-skills.sh productivity             # 同步整个 bucket
#   ./scripts/sync-mattpocock-skills.sh --check                  # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff plugins/mattpocock/
#   git add plugins/mattpocock/
#   git commit -m "chore(mattpocock): sync upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/mattpocock"
UPSTREAM_OWNER="mattpocock"
UPSTREAM_REPO="skills"
UPSTREAM_SUBDIR="skills"
# 仅这两个 bucket 是 promoted；其余（misc/personal/in-progress/deprecated）永不 vendor
PROMOTED_BUCKETS=(engineering productivity)

# 当前 vendor 目录下已有的 bucket 列表（只认 promoted）
discover_buckets() {
  local b
  for b in "${PROMOTED_BUCKETS[@]}"; do
    [ -d "$PLUGIN_DIR/$b" ] && echo "$b"
  done
}

# 某个 bucket 下的 skill 列表（从本地目录扫描）
discover_skills_in() {
  local bucket="$1"
  [ -d "$PLUGIN_DIR/$bucket" ] || return 0
  find "$PLUGIN_DIR/$bucket" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
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

is_promoted_bucket() {
  local b="$1" x
  for x in "${PROMOTED_BUCKETS[@]}"; do
    [ "$x" = "$b" ] && return 0
  done
  return 1
}

# ---------- 抓取上游（sparse-checkout skills/） ----------
fetch_upstream() {
  local tmp="$1"
  if ! git clone --depth 1 --filter=blob:none --sparse \
       "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$tmp" >/dev/null 2>&1; then
    echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
    return 1
  fi
  # 同时拉 plugin.json 以便白名单校验（在仓库根）
  if ! (cd "$tmp" && git sparse-checkout set "$UPSTREAM_SUBDIR" ".claude-plugin") >/dev/null 2>&1; then
    echo "❌ sparse-checkout 失败：$UPSTREAM_SUBDIR + .claude-plugin"
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
# 参数：bucket  skill
sync_one() {
  local bucket="$1" skill="$2"
  local src="$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket/$skill"
  local vendor_dir="$PLUGIN_DIR/$bucket/$skill"
  local commit_file="$vendor_dir/.upstream-commit"

  if ! is_promoted_bucket "$bucket"; then
    echo "  ⚠️  跳过 ${bucket}/${skill}：不在 promoted 白名单（${PROMOTED_BUCKETS[*]}）"
    return 0
  fi

  if [ ! -d "$src" ]; then
    echo "  ⚠️  上游已移除 ${bucket}/${skill}，本地保留（如需删除请手动）"
    return 0
  fi
  if [ ! -f "$src/SKILL.md" ]; then
    echo "  ⚠️  跳过 ${bucket}/${skill}：上游无 SKILL.md（可能不是 skill 目录）"
    return 0
  fi

  local new_commit="$UPSTREAM_COMMIT"
  local old_commit=""
  [ -f "$commit_file" ] && old_commit=$(cat "$commit_file")

  if [ "$new_commit" = "$old_commit" ]; then
    echo "  ✓ $bucket/$skill 已是最新 ($new_commit)"
    return 0
  fi

  if [ -n "$old_commit" ]; then
    echo "  ⚡ $bucket/$skill 有更新"
    echo "    旧: $old_commit"
    echo "    新: $new_commit"
  else
    echo "  ⚡ $bucket/$skill 首次同步（无 .upstream-commit）"
    echo "    新: $new_commit"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "  ℹ️  dry-run，不修改"
    return 0
  fi

  mkdir -p "$vendor_dir"
  # 排除桶级/上游噪声；保留 agents/ 与 scripts/
  rsync -a --delete \
    --exclude='.upstream-commit' \
    --exclude='README.md' \
    --exclude='LICENSE' \
    --exclude='.git' \
    "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $bucket/$skill"
  UPDATED_SKILLS+=("$bucket/$skill")

  check_self_contained "$vendor_dir"
}

# 同步整个 bucket
sync_bucket() {
  local bucket="$1"
  echo "--- $bucket ---"
  local found=0
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    sync_one "$bucket" "$skill" || true
    found=1
  done < <(discover_skills_in "$bucket")
  if [ "$found" = "0" ]; then
    echo "  （本地 $bucket 下无 skill 目录）"
  fi
  return 0
}

# ---------- 主流程 ----------
echo "=== mattpocock-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO ($UPSTREAM_SUBDIR/{${PROMOTED_BUCKETS[*]}}/)"
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

# 如果指定了 TARGET，按形式分派：含 / 视为 bucket/skill，否则视为 bucket
if [ -n "$TARGET" ]; then
  if [[ "$TARGET" == */* ]]; then
    bucket="${TARGET%%/*}"
    skill="${TARGET#*/}"
    if ! is_promoted_bucket "$bucket"; then
      echo "❌ $bucket 不在 promoted 白名单：${PROMOTED_BUCKETS[*]}"
      exit 1
    fi
    if [ ! -d "$PLUGIN_DIR/$bucket/$skill" ] && [ "$DRY_RUN" = "1" ]; then
      echo "❌ 本地无 $TARGET（dry-run 不会新建）"
      exit 1
    fi
    if [ ! -d "$PLUGIN_DIR/$bucket/$skill" ] && [ "$DRY_RUN" != "1" ]; then
      echo "  ℹ️  本地尚无 $TARGET，将从上游首次 vendor"
    fi
    sync_one "$bucket" "$skill"
  else
    if ! is_promoted_bucket "$TARGET"; then
      echo "❌ $TARGET 不在 promoted 白名单：${PROMOTED_BUCKETS[*]}"
      exit 1
    fi
    sync_bucket "$TARGET"
  fi
else
  # 同步全部已 vendor 的 skill（扫本地 promoted bucket）
  while IFS= read -r bucket; do
    [ -n "$bucket" ] || continue
    sync_bucket "$bucket"
  done < <(discover_buckets)

  # 检测上游 promoted 桶内新增 skill（本地没有的）
  echo ""
  echo "--- 检测上游 promoted 桶新增 ---"
  local_added=0
  for bucket in "${PROMOTED_BUCKETS[@]}"; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket" ] || continue
    if [ ! -d "$PLUGIN_DIR/$bucket" ]; then
      echo "  🆕 上游 promoted bucket ${bucket} 本地尚无"
      local_added=1
    fi
    while IFS= read -r sub; do
      [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket/$sub" ] || continue
      [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket/$sub/SKILL.md" ] || continue
      if [ ! -d "$PLUGIN_DIR/$bucket/$sub" ]; then
        echo "  🆕 上游新增 ${bucket}/${sub}（本地未 vendor）"
        if [ "$DRY_RUN" = "1" ]; then
          echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
        else
          mkdir -p "$PLUGIN_DIR/$bucket/$sub"
          rsync -a --delete \
            --exclude='.upstream-commit' \
            --exclude='README.md' \
            --exclude='LICENSE' \
            --exclude='.git' \
            "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket/$sub/" "$PLUGIN_DIR/$bucket/$sub/"
          echo "$UPSTREAM_COMMIT" > "$PLUGIN_DIR/$bucket/$sub/.upstream-commit"
          echo "  ✅ 已 vendor 新 skill: $bucket/$sub"
          echo "  ⚠️  请手动把 \"./$bucket/$sub\" 加入 plugins/mattpocock/.claude-plugin/plugin.json"
          echo "     以及根 .claude-plugin/marketplace.json 中 mattpocock-skills 的 skills 数组"
          UPDATED_SKILLS+=("$bucket/$sub")
          local_added=1
          check_self_contained "$PLUGIN_DIR/$bucket/$sub"
        fi
      fi
    done < <(ls "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$bucket" 2>/dev/null)
  done
  if [ "$local_added" = "0" ]; then
    echo "  （无新增）"
  fi

  # 对照上游 plugin.json promoted 白名单（若存在）
  echo ""
  echo "--- 对照上游 plugin.json promoted 白名单 ---"
  UPSTREAM_PLUGIN_JSON="$UPSTREAM_TMP/.claude-plugin/plugin.json"
  if [ -f "$UPSTREAM_PLUGIN_JSON" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$UPSTREAM_PLUGIN_JSON" "$PLUGIN_DIR" <<'PY'
import json, sys
from pathlib import Path
plugin_json = Path(sys.argv[1])
plugin_dir = Path(sys.argv[2])
data = json.loads(plugin_json.read_text())
listed = []
for s in data.get("skills") or []:
    # ./skills/engineering/tdd  or ./engineering/tdd
    p = s[2:] if s.startswith("./") else s
    parts = Path(p).parts
    if parts and parts[0] == "skills":
        parts = parts[1:]
    if len(parts) >= 2:
        listed.append(f"{parts[0]}/{parts[1]}")
listed_set = set(listed)
local = set()
for bucket in ("engineering", "productivity"):
    b = plugin_dir / bucket
    if not b.is_dir():
        continue
    for d in b.iterdir():
        if d.is_dir() and (d / "SKILL.md").exists():
            local.add(f"{bucket}/{d.name}")
only_upstream = sorted(listed_set - local)
only_local = sorted(local - listed_set)
if only_upstream:
    print("  ⚠️  上游 plugin.json 有、本地未 vendor：")
    for x in only_upstream:
        print(f"     - {x}")
else:
    print("  ✅ 本地覆盖上游 plugin.json 全部 promoted skill")
if only_local:
    print("  ⚠️  本地有、但不在上游 plugin.json：")
    for x in only_local:
        print(f"     - {x}")
else:
    print("  ✅ 无本地多余 skill")
print(f"  统计：上游 promoted {len(listed_set)} / 本地 {len(local)}")
PY
  else
    echo "  （跳过：无上游 plugin.json 或无 python3）"
  fi
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff plugins/mattpocock/  人工 review 后 commit"
fi

# CI 模式
if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
