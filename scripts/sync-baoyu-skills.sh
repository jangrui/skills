#!/usr/bin/env bash
# ============================================================================
# sync-baoyu-skills.sh — 同步 JimLiu/baoyu-skills 上游 skill 到 vendor 目录
#
# 上游特点：
#   - 单仓库多 skill：JimLiu/baoyu-skills 的 skills/ 下有 21 个 baoyu-* 子目录
#   - 一次 sparse-checkout skills/ 即可拿到全部
#   - 所有 skill 共享同一上游 commit
#   - monorepo packages/ 下的兄弟包（baoyu-chrome-cdp / baoyu-md / baoyu-fetch）
#     已发布到 npm；skill 内 scripts/package.json 以版本号声明依赖，
#     运行时 `bun install` 可从 npm 拉取，无需 vendor packages/
#   - baoyu-codex-imagegen / baoyu-fetch 源码已内联到对应 skill 的 scripts/ 中
#
# 机制：
#   - git sparse-checkout 只拉上游 skills/ 子目录
#   - 每个 skill 目录单独保存 .upstream-commit
#   - rsync 排除 *.test.ts（上游测试噪声）
#   - 同步后跑「自包含性自检」
#
# 用法：
#   ./scripts/sync-baoyu-skills.sh                     # 检查并同步全部
#   ./scripts/sync-baoyu-skills.sh baoyu-image-gen     # 只同步 baoyu-image-gen
#   ./scripts/sync-baoyu-skills.sh --check             # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff -- skills/baoyu/<name>/ .claude-plugin/marketplace.json
#   git add skills/baoyu/
#   git commit -m "chore(baoyu): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/baoyu"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="JimLiu"
UPSTREAM_REPO="baoyu-skills"
UPSTREAM_SUBDIR="skills"

# npm 已发布的兄弟包（bare name，非 workspace-only）——这些依赖允许出现
# 运行时由 skill 内 scripts/ 的 package.json + bun install 解析
KNOWN_NPM_BROTHER_PACKAGES="baoyu-chrome-cdp baoyu-md baoyu-fetch"

# 当前 vendor 目录下已有的 skill 列表（从本地目录扫描）
discover_skills() {
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -name 'baoyu-*' 2>/dev/null \
    | sed 's|.*/||' | grep -v '^\.claude-plugin$' | sort
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
        echo "❌ 只能指定一个 skill，已有：${TARGET}，又收到：${arg}"
        exit 1
      fi
      TARGET="$arg" ;;
  esac
done

CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# 市场组版本只跟随已收录 skill 的实际内容变化；--check 保持只读。
source "$REPO_ROOT/scripts/lib/marketplace-version.sh"
marketplace_version_snapshot "$REPO_ROOT" "$PLUGIN_DIR" "$DRY_RUN"

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
# 允许：npm 已发布的 baoyu-* 包、公开 npm 包
# 禁止：未发布的 workspace 兄弟包、相对路径引用 monorepo packages/
check_self_contained() {
  local dir="$1" skill="$2"
  local warnings=0

  # 1) 相对路径引用 monorepo packages/ —— 绝对禁止
  local rel_pkg
  rel_pkg=$(grep -rn "packages/baoyu-\|from ['\"]\.\./\.\./\.\./packages\|from ['\"]\.\./\.\./packages" \
    --include='*.py' --include='*.ts' --include='*.js' --include='*.mjs' \
    "$dir" 2>/dev/null | grep -vE 'node_modules|\.test\.' || true)
  if [ -n "$rel_pkg" ]; then
    echo "  ⚠️  自检：发现相对路径引用 monorepo packages/，vendor 会断裂："
    echo "$rel_pkg" | head -5 | sed 's/^/      /'
    warnings=1
  fi

  # 2) package.json 里声明的 baoyu-* 依赖：确认是已知 npm 包
  local pj
  pj=$(find "$dir" -name package.json -not -path '*/node_modules/*' 2>/dev/null || true)
  if [ -n "$pj" ]; then
    while IFS= read -r f; do
      local unknown
      unknown=$(python3 -c "
import json
d=json.load(open('$f'))
known=set('''$KNOWN_NPM_BROTHER_PACKAGES'''.split())
deps=d.get('dependencies',{}) or {}
for k in deps:
    if k.startswith('baoyu-') and k not in known and not str(deps[k]).startswith('./'):
        print(k + '=' + str(deps[k]))
" 2>/dev/null || true)
      if [ -n "$unknown" ]; then
        echo "  ⚠️  自检：$f 声明了未知 baoyu-* 依赖（可能未发布到 npm）："
        echo "$unknown" | sed 's/^/      /'
        warnings=1
      fi
    done <<< "$pj"
  fi

  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：无 monorepo 路径依赖，baoyu-* 包均可 npm 解析"
  else
    echo "  ❗ 自检告警：上游可能引入了无法独立安装的依赖，请人工确认"
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
  # 首次同步无 old_commit 时不带 --delete（目标可能为空，删无可删）；
  # 后续同步带 --delete 以清理上游已删除的文件。
  # 排除 *.test.ts：上游测试噪声，非运行时必需。
  rsync -a ${old_commit:+--delete} \
    --exclude='.upstream-commit' \
    --exclude='*.test.ts' \
    "$src/" "$vendor_dir/"
  echo "$new_commit" > "$commit_file"
  echo "  ✅ 已更新 $skill"
  UPDATED_SKILLS+=("$skill")

  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 主流程 ----------
echo "=== baoyu-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/$UPSTREAM_REPO ($UPSTREAM_SUBDIR/)"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

UPSTREAM_TMP=$(mktemp -d)
trap 'rm -rf "$UPSTREAM_TMP"' EXIT
fetch_upstream "$UPSTREAM_TMP"
UPSTREAM_COMMIT=$(cd "$UPSTREAM_TMP" && git rev-parse HEAD)
echo "上游 HEAD: $UPSTREAM_COMMIT"
echo ""

if [ -n "$TARGET" ]; then
  if [ ! -d "$SKILLS_DIR/$TARGET" ] && [ "$DRY_RUN" = "1" ]; then
    # dry-run 首次：本地可能还没有目录，允许对上游存在的 skill 做 dry-run 检查
    if [ ! -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$TARGET" ]; then
      echo "❌ 上游无 ${TARGET}"
      exit 1
    fi
  elif [ ! -d "$SKILLS_DIR/$TARGET" ]; then
    echo "❌ 本地无 ${TARGET}（本地目录名即 skill key，如 baoyu-image-gen）"
    echo "可选: $(discover_skills | tr '\n' ' ')"
    echo "提示: 首次同步请不带 skill 名跑全量，或先确认上游有此 skill"
    # 首次全量前本地为空：若上游有该 skill，允许直接同步
    if [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$TARGET" ] && [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$TARGET/SKILL.md" ]; then
      echo "  （上游存在，将作为首次 vendor）"
    else
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
    echo "  （本地尚无 baoyu-* skill，将全部从上游首次 vendor）"
  fi

  echo ""
  echo "--- 检测上游新增 skill ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/SKILL.md" ] || continue
    # 只纳入 baoyu-* 前缀
    case "$sub" in baoyu-*) ;; *) continue ;; esac
    if [ ! -d "$SKILLS_DIR/$sub" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$SKILLS_DIR/$sub"
        rsync -a \
          --exclude='.upstream-commit' \
          --exclude='*.test.ts' \
          "$UPSTREAM_TMP/$UPSTREAM_SUBDIR/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        check_self_contained "$SKILLS_DIR/$sub" "$sub"
        echo "  ⚠️  请手动编辑 skills/baoyu/.claude-plugin/plugin.json 和 marketplace.json 的 skills 数组加入 \"$sub\""
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
  echo "下一步：git diff -- skills/baoyu/ .claude-plugin/marketplace.json  人工 review 后 commit"
fi

marketplace_version_apply "$DRY_RUN"

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
