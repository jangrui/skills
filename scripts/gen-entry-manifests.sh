#!/usr/bin/env bash
# Generate per-entry plugin manifests from marketplace.json curation.
#
# 分组模型：marketplace.json 的每个条目 = 一个独立可安装组（与 Claude 分组一致）。
# - 单条目独占的根（vendor 或子分组）：在 <root>/.claude-plugin/plugin.json 生成
#   manifest，skills 数组 = 该条目精选（相对根路径，./ 前缀数组——ZCode/Claude
#   均实证支持），仓库零复制。
# - 多条目共根（目前仅 opc-design/opc-research 共用 plugins/opc）：在
#   marketplace-entries/<entry>/ 生成包装目录（manifest + skills 副本）。
# vendor 根 manifest 的语义因此从「全量清单」变为「市场精选清单」；全量合集
# 仍以 plugins/ 目录为准（Codex 目录拷贝自取）。
# 精选变更后必须重新运行本脚本，并确认 marketplace.json 各条目 source 指向
# 脚本报告的 expected source。
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PYEOF'
import json
import os
import shutil
from collections import defaultdict

market = json.load(open(".claude-plugin/marketplace.json"))
entries = market["plugins"]

roots = {}
by_root = defaultdict(list)
for entry in entries:
    skills = entry.get("skills", [])
    if not skills:
        raise SystemExit(f"entry {entry['name']} has no skills list")
    for s in skills:
        if not s.startswith("./plugins/") or ".." in s:
            raise SystemExit(f"entry {entry['name']}: illegal skill path {s}")
        if not os.path.isfile(s[2:] + "/SKILL.md"):
            raise SystemExit(f"entry {entry['name']}: missing SKILL.md at {s}")
    root = os.path.commonpath([s[2:] for s in skills])
    # 单 skill 条目：commonpath 即 skill 目录本身，上提到父目录（vendor/分组根），
    # 避免把 manifest 写进 vendored skill 目录（会被 sync --delete 清掉）。
    if root in [s[2:] for s in skills]:
        root = os.path.dirname(root)
    roots[entry["name"]] = root
    by_root[root].append(entry["name"])


def write_manifest(mdir, entry, rel_skills):
    os.makedirs(mdir, exist_ok=True)
    manifest = {
        "name": entry["name"],
        "version": "0.1.0",
        "description": entry.get("description", ""),
        "skills": rel_skills,
    }
    for key in ("author", "license", "homepage", "keywords"):
        if key in entry:
            manifest[key] = entry[key]
    with open(os.path.join(mdir, "plugin.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")


warnings = []
for entry in entries:
    name = entry["name"]
    root = roots[name]
    if len(by_root[root]) == 1:
        rel = ["./" + s[2:][len(root) + 1:] for s in entry["skills"]]
        for s in entry["skills"]:
            if not (s[2:] == root or s[2:].startswith(root + "/")):
                raise SystemExit(f"entry {name}: skill {s} escapes root {root}")
        write_manifest(os.path.join(root, ".claude-plugin"), entry, rel)
        expected = "./" + root
    else:
        wrapper = os.path.join("marketplace-entries", name)
        rel = []
        for s in entry["skills"]:
            skill_name = s[2:].split("/")[-1]
            dst = os.path.join(wrapper, "skills", skill_name)
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(s[2:], dst)
            rel.append("./skills/" + skill_name)
        write_manifest(os.path.join(wrapper, ".claude-plugin"), entry, rel)
        expected = "./" + wrapper
    actual = entry.get("source")
    if actual != expected:
        warnings.append(f"{name}: source={actual!r} -> expected {expected!r}")

print(f"entries={len(entries)} roots={len(by_root)} "
      f"wrapped={[n for r in by_root.values() if len(r) > 1 for n in r]}")
if warnings:
    print("SOURCE MISMATCH (update marketplace.json):")
    for w in warnings:
        print("  " + w)
PYEOF
