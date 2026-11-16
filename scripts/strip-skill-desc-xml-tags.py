#!/usr/bin/env python3
"""移除 SKILL.md frontmatter description 值内的 XML 尖括号标签。

claude.ai 拒绝含 XML 标签的 skill description（插件同步时告警，存储时去尖括号）。
vendored skill 的 SKILL.md 由 sync 脚本从上游 rsync 覆盖，不能手改，故各 sync
脚本在 rsync 后统一调用本工具：把 description 值内的 <foo> / </foo> 就地改为
foo，与 claude.ai 的存储行为一致。只处理 frontmatter 的 description 字段，
正文中的尖括号不受影响。

用法：
  strip-skill-desc-xml-tags.py <SKILL.md 或 skill 目录>...
  strip-skill-desc-xml-tags.py --check <路径>...   # 只报告，不改写

退出码：0 正常；--check 下存在命中时返回 1（供 CI 检测）。
"""

import argparse
import re
import sys
from pathlib import Path

# 仅匹配成对尖括号标签形态（字母开头，无空白），避免误伤 "< 15 秒" 这类比较符
TAG_RE = re.compile(r"</?([A-Za-z][A-Za-z0-9_-]*)>")
# frontmatter 内 description 字段的取值区段：单行/引号值/块标量（| 与 >）
DESC_RE = re.compile(r"^description:(.*?)(?=^[A-Za-z][\w-]*:|\Z)", re.S | re.M)


def process_file(path: Path, dry_run: bool) -> list[str]:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"\A---\n(.*?)\n---", text, re.S)
    if not m:
        return []
    fm = m.group(1)
    dm = DESC_RE.search(fm)
    if not dm:
        return []
    stripped = TAG_RE.sub(r"\1", dm.group(1))
    if stripped == dm.group(1):
        return []
    if not dry_run:
        new_fm = fm[: dm.start(1)] + stripped + fm[dm.end(1):]
        path.write_text(text[: m.start(1)] + new_fm + text[m.end(1):], encoding="utf-8")
    return TAG_RE.findall(dm.group(1))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="+", help="SKILL.md 文件或 skill 目录")
    parser.add_argument("--check", action="store_true", help="只报告命中，不改写")
    args = parser.parse_args()

    files: list[Path] = []
    for p in args.paths:
        path = Path(p)
        if path.is_dir():
            files.extend(sorted(path.rglob("SKILL.md")))
        else:
            files.append(path)

    hits = 0
    for f in files:
        if not f.is_file():
            print(f"⚠️  跳过（不存在）：{f}", file=sys.stderr)
            continue
        found = process_file(f, args.check)
        if found:
            hits += 1
            labels = ", ".join(sorted(set(found)))
            print(f"{'⚠️  待清理' if args.check else '✅ 已清理'} {f}: {labels}")

    if args.check and hits:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
