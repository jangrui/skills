#!/usr/bin/env bash
# ============================================================================
# sync-wps-skills.sh — 同步 WPS 官方 Skillhub（wpsai.wpscdn.cn）skill 到 skills/wps/
#
# 上游特点（CDN zip 分发，非 git 仓库）：
#   - 金山文档官方 skill 以版本化 zip 发布：pro/v<版本>/<skill>.zip
#   - 无 latest 别名、无 manifest：新版本号需人工获知后更新下方 VERSION/SHA256
#   - zip 为 Windows 打包（路径分隔符为反斜杠），用 python3 解包并规范化路径
#   - 运行时依赖 kdocs-cli：官方 CDN 预编译二进制，由 skill 内 scripts/setup.sh 安装
#   - zip 内容为纯 markdown 参考文档 + setup 脚本，无软链、无二进制
#
# 机制：
#   - 下载 pin 版本 zip 并校验 sha256（防 CDN 同版本号内容漂移）
#   - python3 安全解包（反斜杠路径规范化 + zip-slip 防护 + 软链拒绝）
#   - rsync 到 skills/wps/<skill>/，.upstream-commit 记录 zip URL + sha256
#   - pin 未变时仍做内容比对，检出并覆盖对 vendored 树的手改
#   - 同步后跑自包含性自检 + 市场组版本联动
#
# 用法：
#   ./scripts/sync-wps-skills.sh --check     # 仅检查不修改（dry-run）
#   ./scripts/sync-wps-skills.sh             # 同步
#
# 升级上游版本：改 VERSION 与 SHA256 两个变量后运行本脚本。
# 同步后请人工 review：
#   git diff -- skills/wps/ .claude-plugin/marketplace.json
#   git commit -m "chore(wps): sync kdocs upstream v<旧>→v<新>"
# ============================================================================

set -euo pipefail

# ---------- 配置（升级版本时只改这里） ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/wps"
CDN_BASE="https://wpsai.wpscdn.cn/skillhub/pro"
SKILL_NAME="kdocs"
VERSION="2.7.3"
SHA256="39dedeba9bd0bc22cb7a6e9b3bc691a9b1491e5aaa384c6d20755dd0ef52973d"
ZIP_URL="$CDN_BASE/v$VERSION/$SKILL_NAME.zip"
PIN="$ZIP_URL sha256=$SHA256"

# ---------- 参数解析 ----------
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,33p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *)
      echo "❌ 未知参数：${arg}"
      exit 1 ;;
  esac
done

CI_CHANGES_FILE="${CI_CHANGES_FILE:-}"
UPDATED_SKILLS=()

# 市场组版本只跟随已收录 skill 的实际内容变化；--check 保持只读。
source "$REPO_ROOT/scripts/lib/marketplace-version.sh"
marketplace_version_snapshot "$REPO_ROOT" "$PLUGIN_DIR" "$DRY_RUN"

# ---------- 依赖检查 ----------
for cmd in curl python3 rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖：$cmd"; exit 1; }
done

VENDOR_DIR="$PLUGIN_DIR/$SKILL_NAME"
COMMIT_FILE="$VENDOR_DIR/.upstream-commit"
OLD_PIN=""
[ -f "$COMMIT_FILE" ] && OLD_PIN=$(tr -d '\r\n' < "$COMMIT_FILE")

echo "=== WPS Skillhub 同步工具 ==="
echo "上游: $ZIP_URL"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------- 下载并校验 ----------
echo "下载 $SKILL_NAME v$VERSION ..."
curl -fsSL "$ZIP_URL" -o "$TMP/skill.zip"

actual_sha=""
if command -v sha256sum >/dev/null 2>&1; then
  actual_sha=$(sha256sum "$TMP/skill.zip" | awk '{print $1}')
else
  actual_sha=$(shasum -a 256 "$TMP/skill.zip" | awk '{print $1}')
fi
if [ "$actual_sha" != "$SHA256" ]; then
  echo "❌ sha256 不匹配：期望 $SHA256，实际 $actual_sha"
  echo "   若上游以同版本号重发 zip，请核对后更新脚本内 SHA256"
  exit 1
fi
echo "sha256 校验通过 ✓"

# ---------- 解包（反斜杠规范化 + zip-slip 防护 + 软链拒绝） ----------
# mtime 统一取 zip 条目的 date_time 并按 UTC 折算（timegm），保证解包结果可重现：
# 否则 makedirs/写文件的墙钟时间会让「pin 未变的 drift 检查」每次都误报目录差异。
python3 - "$TMP/skill.zip" "$TMP/extract" <<'PYEOF'
import calendar
import os
import sys
import time
import zipfile

zip_path, out_root = sys.argv[1], sys.argv[2]
found_symlink = False
dir_mtime = {}


def entry_mtime(info):
    try:
        return calendar.timegm(info.date_time)
    except (ValueError, OverflowError):
        return int(time.time())


with zipfile.ZipFile(zip_path) as archive:
    for info in archive.infolist():
        name = info.filename.replace("\\", "/").lstrip("/")
        if not name or name.endswith("/"):
            continue
        target = os.path.normpath(os.path.join(out_root, name))
        if not target.startswith(out_root + os.sep):
            sys.exit("zip-slip 嫌疑条目: " + name)
        if (info.external_attr >> 16) & 0o170000 == 0o120000:
            found_symlink = True
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with archive.open(info) as src, open(target, "wb") as dst:
            dst.write(src.read())
        mtime = entry_mtime(info)
        os.utime(target, (mtime, mtime))
        parent = os.path.dirname(target)
        while parent.startswith(out_root):
            dir_mtime[parent] = max(dir_mtime.get(parent, 0), mtime)
            parent = os.path.dirname(parent)
if found_symlink:
    sys.exit("上游 zip 含符号链接，按仓库约定拒绝同步（须先物化或排查）")
for directory, mtime in dir_mtime.items():
    os.utime(directory, (mtime, mtime))
PYEOF

SRC_DIR="$TMP/extract/$SKILL_NAME"
if [ ! -f "$SRC_DIR/SKILL.md" ]; then
  echo "❌ 解包后无 $SKILL_NAME/SKILL.md，上游结构可能已变化"
  exit 1
fi

# ---------- 自包含性自检 ----------
check_self_contained() {
  local dir="$1"
  if find "$dir" -type l 2>/dev/null | grep -q .; then
    echo "  ⚠️  自检：vendored 树存在符号链接（ZCode 市场缓存会失效）"
    return 1
  fi
  echo "  ✅ 自检通过"
}

# rsync 排除项：上游 zip 目前无这些内容，留作防御
RSYNC_EXCLUDES=(
  --exclude='.upstream-commit'
  --exclude='.github/'
  --exclude='.claude-plugin/'
  --exclude='agents/'
  --exclude='LICENSE'
  --exclude='README'
  --exclude='README.md'
)

# ---------- 比对与同步 ----------
SYNC_NEEDED=1
if [ "$OLD_PIN" = "$PIN" ]; then
  drift=$(rsync -a -n --checksum --delete --out-format='%n' \
    "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/" || true)
  if [ -z "$drift" ]; then
    echo "✓ $SKILL_NAME 已是最新 ($VERSION)"
    SYNC_NEEDED=0
  else
    echo "⚡ $SKILL_NAME pin 未变但 vendored 内容有本地差异，将重新覆盖："
    printf '%s\n' "$drift" | head -10 | sed 's/^/      /'
  fi
else
  if [ -n "$OLD_PIN" ]; then
    echo "⚡ $SKILL_NAME 有更新"
    echo "    旧: $OLD_PIN"
    echo "    新: $PIN"
  else
    echo "⚡ $SKILL_NAME 首次同步（无 .upstream-commit）"
    echo "    新: $PIN"
  fi
fi

if [ "$SYNC_NEEDED" = "1" ] && [ "$DRY_RUN" != "1" ]; then
  mkdir -p "$VENDOR_DIR"
  # 首次无旧 pin 时不带 --delete，降低误清风险；后续带上清理上游已删文件
  if [ -n "$OLD_PIN" ]; then
    rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/"
  else
    rsync -a "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/"
  fi
  printf '%s\n' "$PIN" > "$COMMIT_FILE"
  echo "✅ 已更新 $SKILL_NAME → v$VERSION"
  UPDATED_SKILLS+=("$SKILL_NAME")
  check_self_contained "$VENDOR_DIR"
elif [ "$SYNC_NEEDED" = "1" ]; then
  echo "  ℹ️  dry-run，不修改"
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff -- skills/wps/ .claude-plugin/marketplace.json  人工 review 后 commit"
fi

marketplace_version_apply "$DRY_RUN"

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
