#!/usr/bin/env bash
# ============================================================================
# sync-tencent-adm-skills.sh — 同步腾讯会议官方 skill（skillhub.cn）到 skills/tencent-adm/
#
# 上游特点（skillhub.cn API 分发，非 git 仓库）：
#   - 下载口为无版本 latest URL（302 跳转 CDN），新版本由上游静默替换
#   - 无 sha pin 可言：改为下载后校验来源（SKILL.md 存在、config.json 的
#     baseUrl 必须指向 mcp.meeting.tencent.com 官方域名、_meta.json slug 匹配）
#   - zip 内容平铺在根目录（SKILL.md / _meta.json / config.json / references/ / scripts/）
#   - scripts/ 为纯 Python 标准库 MCP 桥接脚本，运行时依赖 python3 + TENCENT_MEETING_TOKEN
#
# 机制：
#   - 下载 latest zip → python3 安全解包（zip-slip 防护 + 软链拒绝 + mtime 规范化）
#   - rsync --checksum 与 vendored 树做内容级比对（无版本号可比，全凭内容判漂移）
#   - rsync 到 skills/tencent-adm/<skill>/，.upstream-commit 记录 zip URL + sha256
#   - pin 未变时仍做内容比对，检出并覆盖对 vendored 树的手改
#   - 同步后跑自包含性自检 + 市场组版本联动
#
# 用法：
#   ./scripts/sync-tencent-adm-skills.sh --check     # 仅检查不修改（dry-run）
#   ./scripts/sync-tencent-adm-skills.sh             # 同步
#
# 同步后请人工 review：
#   git diff -- skills/tencent-adm/ .claude-plugin/marketplace.json
#   git commit -m "chore(tencent-adm): sync tencent-meeting-mcp upstream v<旧>→v<新>"
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/skills/tencent-adm"
SKILLHUB_API="https://api.skillhub.cn/api/v1/download"
SLUG="@tencent-adm/tencent-meeting-mcp"
SKILL_NAME="tencent-meeting-mcp"
DOWNLOAD_URL="$SKILLHUB_API?slug=$SLUG"
# 官方 MCP 端点域名：config.json baseUrl 若偏离此域名则拒绝同步
EXPECTED_MCP_HOST="mcp.meeting.tencent.com"

# ---------- 参数解析 ----------
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,29p' "$0" | sed 's/^# \?//'
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

echo "=== 腾讯会议 skillhub 同步工具 ==="
echo "上游: $DOWNLOAD_URL"
echo "插件目录: $PLUGIN_DIR"
echo "模式: $([ "$DRY_RUN" = "1" ] && echo 'dry-run (仅检查)' || echo '同步')"
echo ""

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------- 下载 ----------
echo "下载 $SKILL_NAME (latest) ..."
curl -fsSL -G "$SKILLHUB_API" --data-urlencode "slug=$SLUG" -o "$TMP/skill.zip"

actual_sha=""
if command -v sha256sum >/dev/null 2>&1; then
  actual_sha=$(sha256sum "$TMP/skill.zip" | awk '{print $1}')
else
  actual_sha=$(shasum -a 256 "$TMP/skill.zip" | awk '{print $1}')
fi
PIN="$DOWNLOAD_URL sha256=$actual_sha"
echo "zip sha256=$actual_sha"

# ---------- 解包（反斜杠规范化 + zip-slip 防护 + 软链拒绝） ----------
# mtime 统一取 zip 条目的 date_time 并按 UTC 折算（timegm），保证解包结果可重现：
# 否则 makedirs/写文件的墙钟时间会让「pin 未变的 drift 检查」每次都误报目录差异。
python3 - "$TMP/skill.zip" "$TMP/extract" <<'PYEOF'
import calendar
import os
import sys
import zipfile

zip_path, out_root = sys.argv[1], sys.argv[2]
found_symlink = False
dir_mtime = {}

# zip 条目 date_time 非法（如 1980-00-00）时的确定性回退：
# 回退墙钟时间会让每次解包 mtime 漂移、drift 检查永久假阳性
FIXED_FALLBACK_MTIME = 946684800  # 2000-01-01T00:00:00Z


def entry_mtime(info):
    try:
        return calendar.timegm(info.date_time)
    except (ValueError, OverflowError):
        return FIXED_FALLBACK_MTIME


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

# zip 内容平铺在根目录
SRC_DIR="$TMP/extract"
if [ ! -f "$SRC_DIR/SKILL.md" ]; then
  echo "❌ 解包后无根级 SKILL.md，上游结构可能已变化"
  exit 1
fi

# ---------- 来源校验 ----------
# 无版本上游无法 pin sha，改校验包内声明：baseUrl 域名必须是腾讯官方 MCP 端点，
# _meta.json slug 必须匹配，防止下载口被劫持后 vendored 进未知端点
python3 - "$SRC_DIR" "$SKILL_NAME" "$EXPECTED_MCP_HOST" <<'PYEOF'
import json
import sys
from urllib.parse import urlparse

src_dir, skill_name, expected_host = sys.argv[1], sys.argv[2], sys.argv[3]

with open(f"{src_dir}/config.json", encoding="utf-8") as f:
    config = json.load(f)
base_url = config.get("baseUrl", "")
host = urlparse(base_url).hostname or ""
if host != expected_host:
    sys.exit(f"来源校验失败: config.json baseUrl 域名 {host!r} 不是官方端点 {expected_host!r}")

with open(f"{src_dir}/_meta.json", encoding="utf-8") as f:
    meta = json.load(f)
slug = meta.get("slug", "")
if slug != skill_name:
    sys.exit(f"来源校验失败: _meta.json slug {slug!r} 与预期 {skill_name!r} 不符")

print(f"来源校验通过 ✓ (slug={slug}, baseUrl host={host})")
PYEOF

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
# 无版本号可 pin：一律 rsync --checksum 做内容级比对（同时检出本地手改与上游更新）
# --omit-dir-times：目录 mtime 不进 git 也无同步语义，且 OneDrive 后台会回写目录
# mtime、写 .upstream-commit 会弄脏目标根目录，比较目录时间只会产生假阳性
drift=$(rsync -a -n --checksum --delete --omit-dir-times --out-format='%n' \
  "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/" || true)
if [ -z "$drift" ]; then
  echo "✓ $SKILL_NAME 已是最新 (sha256=$actual_sha)"
else
  if [ -n "$OLD_PIN" ]; then
    echo "⚡ $SKILL_NAME 有更新"
    echo "    旧: $OLD_PIN"
    echo "    新: $PIN"
  else
    echo "⚡ $SKILL_NAME 首次同步（无 .upstream-commit）"
    echo "    新: $PIN"
  fi
  echo "    差异文件："
  printf '%s\n' "$drift" | head -10 | sed 's/^/      /'

  if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$VENDOR_DIR"
    # 首次无旧 pin 时不带 --delete，降低误清风险；后续带上清理上游已删文件
    if [ -n "$OLD_PIN" ]; then
      rsync -a --delete --omit-dir-times "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/"
    else
      rsync -a --omit-dir-times "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$VENDOR_DIR/"
    fi
    printf '%s\n' "$PIN" > "$COMMIT_FILE"
    echo "✅ 已更新 $SKILL_NAME"
    UPDATED_SKILLS+=("$SKILL_NAME")
    check_self_contained "$VENDOR_DIR"
  else
    echo "  ℹ️  dry-run，不修改"
  fi
fi

echo ""
echo "=== 完成 ==="
if [ "$DRY_RUN" != "1" ]; then
  echo "下一步：git diff -- skills/tencent-adm/ .claude-plugin/marketplace.json  人工 review 后 commit"
fi

marketplace_version_apply "$DRY_RUN"

if [ -n "$CI_CHANGES_FILE" ] && [ "${#UPDATED_SKILLS[@]}" -gt 0 ]; then
  printf '%s\n' "${UPDATED_SKILLS[@]}" > "$CI_CHANGES_FILE"
  echo ""
  echo "[CI] 本次更新 ${#UPDATED_SKILLS[@]} 个 skill，已写入 $CI_CHANGES_FILE"
fi
