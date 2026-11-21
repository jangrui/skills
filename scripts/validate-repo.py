#!/usr/bin/env python3
"""仓库一致性校验：PR 与定时同步共用，任一检查失败即以非零退出。

检查项：
  1. marketplace.json 结构：必填字段、组名与 skill 路径不重复、图标文件存在
  2. 每个已收录 skill：目录存在、SKILL.md 有 frontmatter 且含 name / description，
     description 不超过 1024 字符，组内 name 不重复
  3. 同步脚本、workflow 手动触发选项、matrix components 三者一致；
     matrix 覆盖全部市场组
  4. 已收录 skill 目录内无符号链接（ZCode 等以仓库为插件根缓存，软链会失效）
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"
WORKFLOW = ROOT / ".github" / "workflows" / "sync-skills.yml"
REQUIRED_PLUGIN_KEYS = ("name", "version", "description", "icon", "source", "skills")
DESCRIPTION_LIMIT = 1024

errors: list[str] = []


def error(message: str) -> None:
    errors.append(message)


def frontmatter(text: str) -> str | None:
    match = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
    return match.group(1) if match else None


def field(block: str, key: str) -> str | None:
    """取 YAML 顶层标量字段（含 | / > 块与多行续写），足够覆盖 SKILL.md 的写法。"""
    match = re.search(rf"^{key}:[ \t]*(.*?)(?=^[A-Za-z0-9_-]+:|\Z)", block, re.M | re.S)
    if not match:
        return None
    value = match.group(1).strip()
    if value[:1] in "|>":
        value = value[1:].lstrip("-+").strip()
    return " ".join(line.strip() for line in value.splitlines()).strip().strip("\"'")


def check_marketplace() -> list[dict]:
    try:
        data = json.loads(MARKETPLACE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        error(f"marketplace.json 无法解析：{exc}")
        return []

    plugins = data.get("plugins", [])
    seen_groups: set[str] = set()
    for plugin in plugins:
        name = plugin.get("name", "<无名>")
        for key in REQUIRED_PLUGIN_KEYS:
            if key not in plugin:
                error(f"{name}: 缺少字段 {key}")
        if name in seen_groups:
            error(f"{name}: 组名重复")
        seen_groups.add(name)

        icon = plugin.get("icon", "")
        if "/main/" in icon:
            icon_path = ROOT / icon.split("/main/", 1)[1]
            if not icon_path.is_file():
                error(f"{name}: 图标不存在 {icon_path.relative_to(ROOT)}")

        seen_paths: set[str] = set()
        seen_names: dict[str, str] = {}
        for skill in plugin.get("skills", []):
            rel = skill.removeprefix("./").rstrip("/")
            if rel in seen_paths:
                error(f"{name}: skill 路径重复 {skill}")
            seen_paths.add(rel)
            check_skill(name, rel, seen_names)
    return plugins


def check_skill(group: str, rel: str, seen_names: dict[str, str]) -> None:
    skill_dir = ROOT / rel
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        error(f"{group}: {rel} 缺少 SKILL.md")
        return
    block = frontmatter(skill_md.read_text(encoding="utf-8"))
    if block is None:
        error(f"{group}: {rel}/SKILL.md 缺少 frontmatter")
        return
    name = field(block, "name")
    description = field(block, "description")
    if not name:
        error(f"{group}: {rel}/SKILL.md 缺少 name")
    elif name in seen_names:
        error(f"{group}: skill name「{name}」重复（{seen_names[name]} 与 {rel}）")
    else:
        seen_names[name] = rel
    if not description:
        error(f"{group}: {rel}/SKILL.md 缺少 description")
    elif len(description) > DESCRIPTION_LIMIT:
        error(f"{group}: {rel}/SKILL.md description 超过 {DESCRIPTION_LIMIT} 字符（{len(description)}）")
    for path in skill_dir.rglob("*"):
        if path.is_symlink():
            error(f"{group}: {path.relative_to(ROOT)} 是符号链接")


def check_workflow(plugins: list[dict]) -> None:
    scripts = {
        path.name.removeprefix("sync-").removesuffix("-skills.sh")
        for path in (ROOT / "scripts").glob("sync-*-skills.sh")
    }
    text = WORKFLOW.read_text(encoding="utf-8")
    options_block = re.search(r"options:\n((?:\s+- .*\n)+)", text)
    options = set(re.findall(r"- ([a-z0-9-]+)\s*$", options_block.group(1), re.M)) if options_block else set()
    components = set(re.findall(r'"([a-z0-9-]+)"', " ".join(re.findall(r'"components":\[([^\]]*)\]', text))))
    groups = set(re.findall(r'"marketplace_group":"([a-z0-9-]+)"', text))

    for label, found in (("手动触发选项", options), ("matrix components", components)):
        if missing := sorted(scripts - found):
            error(f"workflow {label} 缺少同步源：{', '.join(missing)}")
        if extra := sorted(found - scripts):
            error(f"workflow {label} 引用了不存在的脚本：{', '.join(extra)}")
    plugin_names = {plugin.get("name") for plugin in plugins}
    if missing := sorted(plugin_names - groups):
        error(f"workflow matrix 未覆盖市场组：{', '.join(missing)}")
    if extra := sorted(groups - plugin_names):
        error(f"workflow matrix 引用了不存在的市场组：{', '.join(extra)}")


def main() -> int:
    plugins = check_marketplace()
    check_workflow(plugins)
    skill_count = sum(len(plugin.get("skills", [])) for plugin in plugins)
    if errors:
        print(f"❌ 校验失败（{len(errors)} 项）：")
        for message in errors:
            print(f"  - {message}")
        return 1
    print(f"✅ 校验通过：{len(plugins)} 个市场组、{skill_count} 个已收录 skill")
    return 0


if __name__ == "__main__":
    sys.exit(main())
