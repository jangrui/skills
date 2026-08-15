#!/usr/bin/env bash
# ============================================================================
# sync-khazix-skills.sh — 同步 KKKKhazix/khazix-skills 上游 skill 到 vendor 目录
#
# 上游特点：
#   - 单仓库多 skill，扁平：skill 目录直接在仓库根（aihot/ hv-analysis/
#     khazix-writer/ leader/ neat-freak/ storage-analyzer/），每目录一个 SKILL.md
#   - 脚本自动扫上游根目录发现 skill（含 SKILL.md 的子目录）
#   - 所有 skill 共享同一上游 commit
#   - Python 依赖：storage-analyzer 纯标准库；hv-analysis 需已发布的
#     pip 公开包 weasyprint / markdown（SKILL.md 内注明安装命令）
#
# 排除项（除通用约定外）：
#   - evals/            上游评测 fixture（100+ 假数据文件，SKILL.md 未引用）
#   - install.sh        上游官网一行安装入口，与本仓库分发渠道冲突
#   - manifest.sha256   校验对象含未 vendor 的 LICENSE/agents 文件，必然失配
#   - .gitignore        本仓库根 .gitignore 忽略一切嵌套 .gitignore，
#                       留在工作区会造成 git 状态不一致
#
# 机制：
#   - git sparse-checkout 拉上游各 skill 目录（cone 模式认目录，此处合法）
#   - 每个 skill 目录单独保存 .upstream-commit
#   - 同步后跑「自包含性自检」（含 Python 非标准库 import 告警）
#
# 用法：
#   ./scripts/sync-khazix-skills.sh                     # 检查并同步全部
#   ./scripts/sync-khazix-skills.sh neat-freak          # 只同步 neat-freak
#   ./scripts/sync-khazix-skills.sh --check             # 仅检查不修改（dry-run）
#
# 同步后请人工 review：
#   git diff skills/khazix/<name>/
#   git add skills/khazix/
#   git commit -m "chore(khazix): sync <name> upstream <old>→<new>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/khazix"
SKILLS_DIR="$PLUGIN_DIR"
UPSTREAM_OWNER="KKKKhazix"
UPSTREAM_REPO="khazix-skills"

# 已确认可 vendor 的非标准库 Python 包（PyPI 已发布）
KNOWN_PIP_PACKAGES="weasyprint markdown"

# rsync 排除规则（上游仓库根整体拉到本地后按 skill 目录同步时生效）
RSYNC_EXCLUDES=(
  --exclude='.upstream-commit'
  --exclude='.git'
  --exclude='.github'
  --exclude='.claude-plugin'
  --exclude='agents'
  --exclude='README*'
  --exclude='LICENSE'
  --exclude='evals'
  --exclude='install.sh'
  --exclude='manifest.sha256'
  --exclude='.gitignore'
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
      sed -n '2,40p' "$0" | sed 's/^# \?//'
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
# 上游 skill 在仓库根，sparse-checkout set 各 skill 目录（cone 模式认目录）。
# 先完整浅克隆再读目录列表，避免「先知道目录名才能 set」的鸡蛋问题。
fetch_upstream() {
  local tmp="$1"
  if ! git clone --depth 1 "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO.git" "$tmp" >/dev/null 2>&1; then
    echo "❌ clone 失败：$UPSTREAM_OWNER/$UPSTREAM_REPO"
    return 1
  fi
}

# ---------- 自包含性自检 ----------
# 允许：Python 标准库、已确认发布的 pip 公开包
# 告警：未知非标准库 import（可能是未发布依赖，vendor 会断裂）
check_self_contained() {
  local dir="$1" skill="$2"
  local warnings=0

  local py_files
  py_files=$(find "$dir" -name '*.py' 2>/dev/null || true)
  if [ -n "$py_files" ]; then
    # 收集所有顶层 import 的模块名
    local mods
    mods=$(grep -h '^import \|^from ' $py_files 2>/dev/null \
      | sed -e 's/^from \([A-Za-z0-9_.]*\).*/\1/' -e 's/^import \([A-Za-z0-9_.]*\).*/\1/' \
      | cut -d. -f1 | sort -u || true)
    local nonstdlib
    nonstdlib=$(python3 -c "
import sys
known = set('''$KNOWN_PIP_PACKAGES'''.split())
mods = '''$mods'''.split()
for m in mods:
    if m in known or m in sys.builtin_module_names:
        continue
    if m in sys.stdlib_module_names:
        continue
    print(m)
" 2>/dev/null || echo "$mods")
    if [ -n "$nonstdlib" ]; then
      echo "  ⚠️  自检：发现非标准库 import（请人工确认已发布到 PyPI）："
      echo "$nonstdlib" | sed 's/^/      /'
      warnings=1
    fi
  fi

  if [ "$warnings" = "0" ]; then
    echo "  ✅ 自检通过：Python 脚本仅标准库 / 已确认的公开 pip 包"
  else
    echo "  ❗ 自检告警：出现未知 Python 依赖，请人工确认可独立安装后再 commit"
  fi
}

# ---------- 同步单个 skill ----------
sync_one() {
  local skill="$1"
  local src="$UPSTREAM_TMP/$skill"
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

  check_self_contained "$vendor_dir" "$skill"
}

# ---------- 主流程 ----------
echo "=== khazix-skills 同步工具 ==="
echo "上游: $UPSTREAM_OWNER/${UPSTREAM_REPO}（skill 在仓库根，扁平）"
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
    if [ ! -d "$UPSTREAM_TMP/$TARGET" ]; then
      echo "❌ 上游无 ${TARGET}"
      exit 1
    fi
    if [ ! -f "$UPSTREAM_TMP/$TARGET/SKILL.md" ]; then
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
    echo "  （本地尚无 khazix skill，将全部从上游首次 vendor）"
  fi

  echo ""
  echo "--- 检测上游新增 skill ---"
  local_added=0
  while IFS= read -r sub; do
    [ -d "$UPSTREAM_TMP/$sub" ] || continue
    [ -f "$UPSTREAM_TMP/$sub/SKILL.md" ] || continue
    if [ ! -d "$SKILLS_DIR/$sub" ]; then
      echo "  🆕 上游新增 ${sub}（本地未 vendor）"
      if [ "$DRY_RUN" = "1" ]; then
        echo "     dry-run，跳过；如需纳入请去掉 --check 重跑"
      else
        mkdir -p "$SKILLS_DIR/$sub"
        rsync -a "${RSYNC_EXCLUDES[@]}" "$UPSTREAM_TMP/$sub/" "$SKILLS_DIR/$sub/"
        echo "$UPSTREAM_COMMIT" > "$SKILLS_DIR/$sub/.upstream-commit"
        echo "  ✅ 已 vendor 新 skill: $sub"
        check_self_contained "$SKILLS_DIR/$sub" "$sub"
        echo "  ⚠️  请手动编辑 skills/khazix/.claude-plugin/plugin.json 和 marketplace.json 的 skills 数组加入 \"$sub\""
        UPDATED_SKILLS+=("$sub")
        local_added=1
      fi
    fi
  done < <(ls "$UPSTREAM_TMP")
  [ "$local_added" = "0" ] && echo "  （无新增）"
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff skills/khazix/  人工 review 后 commit"
fi

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
