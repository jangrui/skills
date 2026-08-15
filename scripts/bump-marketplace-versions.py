#!/usr/bin/env python3
"""Bump marketplace group versions from actual published skill content changes."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
from typing import Any, Iterable


VERSION_RE = re.compile(r"^(0|[1-9][0-9]*)\.([0-9])\.([0-9])$")
SNAPSHOT_SCHEMA_VERSION = 1
UPSTREAM_COMMIT_FILE = ".upstream-commit"


class VersionError(Exception):
    """A clear, user-actionable marketplace version error."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise VersionError(f"找不到 JSON 文件：{path}") from exc
    except json.JSONDecodeError as exc:
        raise VersionError(f"JSON 解析失败：{path}: {exc}") from exc
    if not isinstance(value, dict):
        raise VersionError(f"JSON 根节点必须是对象：{path}")
    return value


def render_json(value: dict[str, Any]) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(render_json(value), encoding="utf-8")


def normalize_skill_path(value: str) -> str:
    path = value.replace("\\", "/")
    while path.startswith("./"):
        path = path[2:]
    path = path.strip("/")
    candidate = PurePosixPath(path)
    if not path or candidate.is_absolute() or ".." in candidate.parts:
        raise VersionError(f"非法 skill 路径：{value!r}")
    return candidate.as_posix()


def marketplace_root(marketplace: Path) -> Path:
    if marketplace.name != "marketplace.json" or marketplace.parent.name != ".claude-plugin":
        raise VersionError(
            "marketplace 路径必须是仓库的 .claude-plugin/marketplace.json"
        )
    return marketplace.parent.parent.resolve()


def scope_relative_to_root(scope: Path, root: Path) -> str:
    try:
        return scope.resolve().relative_to(root).as_posix()
    except ValueError as exc:
        raise VersionError(f"scope 不在仓库内：{scope}") from exc


def is_in_scope(skill_path: str, scope: str) -> bool:
    return skill_path == scope or skill_path.startswith(f"{scope}/")


def published_groups(
    marketplace: dict[str, Any], root: Path, scope: str
) -> list[dict[str, Any]]:
    plugins = marketplace.get("plugins")
    if not isinstance(plugins, list):
        raise VersionError("marketplace.plugins 必须是数组")

    groups: list[dict[str, Any]] = []
    names: set[str] = set()
    for plugin in plugins:
        if not isinstance(plugin, dict):
            raise VersionError("marketplace.plugins 中存在非对象条目")
        name = plugin.get("name")
        skills = plugin.get("skills")
        if not isinstance(name, str) or not name:
            raise VersionError("marketplace 插件缺少 name")
        if name in names:
            raise VersionError(f"marketplace 插件名重复：{name}")
        names.add(name)
        if not isinstance(skills, list):
            raise VersionError(f"{name}.skills 必须是数组")

        scoped_paths: list[str] = []
        for raw_path in skills:
            if not isinstance(raw_path, str):
                raise VersionError(f"{name}.skills 包含非字符串路径")
            skill_path = normalize_skill_path(raw_path)
            if is_in_scope(skill_path, scope):
                scoped_paths.append(skill_path)

        if scoped_paths:
            groups.append({"name": name, "paths": sorted(set(scoped_paths))})
    return groups


def digest_skill_tree(root: Path, skill_path: str) -> str:
    target = root / skill_path
    digest = hashlib.sha256()
    digest.update(b"skill\0")
    digest.update(os.fsencode(skill_path))

    if not target.exists() and not target.is_symlink():
        digest.update(b"missing\0")
        return digest.hexdigest()
    if target.is_symlink():
        digest.update(b"symlink\0")
        digest.update(os.fsencode(os.readlink(target)))
        return digest.hexdigest()
    if not target.is_dir():
        raise VersionError(f"marketplace skill 路径不是目录：{target}")

    files = sorted(target.rglob("*"), key=lambda path: path.relative_to(target).as_posix())
    for item in files:
        relative_path = item.relative_to(target).as_posix()
        if item.name == UPSTREAM_COMMIT_FILE:
            continue
        if item.is_dir():
            continue
        digest.update(os.fsencode(relative_path))
        digest.update(b"\0")
        if item.is_symlink():
            digest.update(b"symlink\0")
            digest.update(os.fsencode(os.readlink(item)))
            continue
        if not item.is_file():
            raise VersionError(f"无法计算非常规文件的指纹：{item}")
        digest.update(b"file\0")
        with item.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def digest_group(root: Path, paths: Iterable[str]) -> str:
    digest = hashlib.sha256()
    for skill_path in sorted(paths):
        digest.update(os.fsencode(skill_path))
        digest.update(b"\0")
        digest.update(digest_skill_tree(root, skill_path).encode("ascii"))
        digest.update(b"\0")
    return digest.hexdigest()


def make_snapshot(marketplace_path: Path, scope_path: Path) -> dict[str, Any]:
    root = marketplace_root(marketplace_path)
    scope = scope_relative_to_root(scope_path, root)
    marketplace = load_json(marketplace_path)
    groups = published_groups(marketplace, root, scope)
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "scope": scope,
        "groups": [
            {
                "name": group["name"],
                "paths": group["paths"],
                "digest": digest_group(root, group["paths"]),
            }
            for group in groups
        ],
    }


def validate_snapshot(snapshot: dict[str, Any], source: str) -> dict[str, Any]:
    if snapshot.get("schema_version") != SNAPSHOT_SCHEMA_VERSION:
        raise VersionError(f"不支持的快照版本：{source}")
    if not isinstance(snapshot.get("scope"), str):
        raise VersionError(f"快照缺少 scope：{source}")
    if not isinstance(snapshot.get("groups"), list):
        raise VersionError(f"快照缺少 groups：{source}")
    return snapshot


def load_snapshot(path: Path) -> dict[str, Any]:
    return validate_snapshot(load_json(path), str(path))


def load_snapshot_stdin() -> dict[str, Any]:
    try:
        value = json.loads(sys.stdin.read())
    except json.JSONDecodeError as exc:
        raise VersionError("标准输入中的同步前快照不是合法 JSON") from exc
    if not isinstance(value, dict):
        raise VersionError("标准输入中的同步前快照根节点必须是对象")
    return validate_snapshot(value, "标准输入")


def version_parts(version: str) -> tuple[int, int, int]:
    match = VERSION_RE.fullmatch(version)
    if not match:
        raise VersionError(
            f"版本必须为 major.minor.patch，且 minor/patch 是单个十进制位：{version!r}"
        )
    return tuple(int(part) for part in match.groups())


def next_version(version: str) -> str:
    major, minor, patch = version_parts(version)
    patch += 1
    if patch == 10:
        patch = 0
        minor += 1
    if minor == 10:
        minor = 0
        major += 1
    return f"{major}.{minor}.{patch}"


def version_by_name(marketplace: dict[str, Any]) -> dict[str, dict[str, Any]]:
    plugins = marketplace.get("plugins")
    if not isinstance(plugins, list):
        raise VersionError("marketplace.plugins 必须是数组")
    result: dict[str, dict[str, Any]] = {}
    for plugin in plugins:
        if not isinstance(plugin, dict) or not isinstance(plugin.get("name"), str):
            raise VersionError("marketplace.plugins 中存在无 name 条目")
        name = plugin["name"]
        if name in result:
            raise VersionError(f"marketplace 插件名重复：{name}")
        version = plugin.get("version")
        if not isinstance(version, str):
            raise VersionError(f"{name} 缺少 string 类型 version")
        version_parts(version)
        result[name] = plugin
    return result


def update_matches_skill(updated: str, skill_path: str) -> bool:
    normalized = normalize_skill_path(updated)
    if normalized == skill_path or skill_path.endswith(f"/{normalized}"):
        return True
    return "/" not in normalized and skill_path.rsplit("/", 1)[-1] == normalized


def affected_group_names(
    groups: list[dict[str, Any]], updates: Iterable[str]
) -> tuple[list[str], list[str]]:
    affected: list[str] = []
    unlisted: list[str] = []
    for updated in updates:
        matching_paths = {
            path
            for group in groups
            for path in group["paths"]
            if update_matches_skill(updated, path)
        }
        if not matching_paths:
            unlisted.append(updated)
            continue
        if len(matching_paths) > 1:
            paths = ", ".join(sorted(matching_paths))
            raise VersionError(
                f"更新项 {updated!r} 匹配多个已收录 skill：{paths}；"
                "请让同步脚本传递更具体的路径"
            )
        matches = [
            group["name"]
            for group in groups
            if matching_paths.intersection(group["paths"])
        ]
        for name in matches:
            if name not in affected:
                affected.append(name)
    return affected, unlisted


def changed_groups_from_snapshot(
    marketplace_path: Path,
    scope_path: Path,
    snapshot_path: Path | None,
    updates: Iterable[str],
    snapshot: dict[str, Any] | None = None,
) -> tuple[list[str], list[str]]:
    root = marketplace_root(marketplace_path)
    scope = scope_relative_to_root(scope_path, root)
    if snapshot is None:
        if snapshot_path is None:
            raise VersionError("缺少同步前快照")
        snapshot = load_snapshot(snapshot_path)
    else:
        snapshot = validate_snapshot(snapshot, "内存")
    if snapshot["scope"] != scope:
        raise VersionError(
            f"快照 scope 不匹配：期望 {scope!r}，实际 {snapshot['scope']!r}"
        )

    marketplace = load_json(marketplace_path)
    groups = published_groups(marketplace, root, scope)
    before = {group["name"]: group for group in snapshot["groups"]}
    for group in groups:
        old_group = before.get(group["name"])
        if old_group is None or old_group.get("paths") != group["paths"]:
            raise VersionError("同步过程中 marketplace 的 skill 映射发生变化，拒绝自动升版")

    candidate_names, unlisted = affected_group_names(groups, updates)
    changed: list[str] = []
    groups_by_name = {group["name"]: group for group in groups}
    for name in candidate_names:
        if before[name].get("digest") != digest_group(root, groups_by_name[name]["paths"]):
            changed.append(name)
    return changed, unlisted


def bump_groups(marketplace_path: Path, group_names: Iterable[str]) -> list[tuple[str, str, str]]:
    marketplace = load_json(marketplace_path)
    plugins = version_by_name(marketplace)
    requested = set(group_names)
    unknown = sorted(requested - set(plugins))
    if unknown:
        raise VersionError(f"marketplace 不存在这些场景组：{', '.join(unknown)}")

    changes: list[tuple[str, str, str]] = []
    for plugin in marketplace["plugins"]:
        name = plugin["name"]
        if name not in requested:
            continue
        old_version = plugin["version"]
        new_version = next_version(old_version)
        plugin["version"] = new_version
        changes.append((name, old_version, new_version))

    if changes:
        write_json(marketplace_path, marketplace)
    return changes


def print_version_changes(changes: Iterable[tuple[str, str, str]]) -> None:
    for name, old_version, new_version in changes:
        print(f"[marketplace-version] {name}: {old_version} -> {new_version}")


def command_snapshot(args: argparse.Namespace) -> int:
    snapshot = make_snapshot(args.marketplace, args.scope)
    if args.output == "-":
        sys.stdout.write(render_json(snapshot))
    else:
        write_json(Path(args.output), snapshot)
    return 0


def command_apply(args: argparse.Namespace) -> int:
    snapshot = load_snapshot(args.before) if args.before is not None else load_snapshot_stdin()
    changed, unlisted = changed_groups_from_snapshot(
        args.marketplace,
        args.scope,
        args.before,
        args.updated,
        snapshot,
    )
    if unlisted:
        print(
            "[marketplace-version] 未收录 skill 不影响市场组版本："
            + ", ".join(unlisted)
        )
    if not changed:
        print("[marketplace-version] 已收录 skill 内容未变化，不升版")
        return 0

    if args.defer_file is not None:
        with args.defer_file.open("a", encoding="utf-8") as output:
            for name in changed:
                output.write(f"{name}\n")
        print(
            "[marketplace-version] 已记录待升版场景组："
            + ", ".join(changed)
        )
        return 0

    print_version_changes(bump_groups(args.marketplace, changed))
    return 0


def command_bump_groups(args: argparse.Namespace) -> int:
    try:
        requested = [
            line.strip()
            for line in args.groups_file.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
    except FileNotFoundError:
        requested = []
    if not requested:
        print("[marketplace-version] 没有待升版场景组")
        return 0
    print_version_changes(bump_groups(args.marketplace, requested))
    return 0


def read_git_json(root: Path, revision: str, path: str) -> dict[str, Any]:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=root,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise VersionError(
            f"无法从 Git 读取 {revision}:{path}：{result.stderr.strip()}"
        )
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise VersionError(f"Git 中的 {revision}:{path} 不是合法 JSON") from exc
    if not isinstance(value, dict):
        raise VersionError(f"Git 中的 {revision}:{path} 根节点必须是对象")
    return value


def without_plugin_versions(marketplace: dict[str, Any]) -> dict[str, Any]:
    value = copy.deepcopy(marketplace)
    plugins = value.get("plugins")
    if not isinstance(plugins, list):
        raise VersionError("marketplace.plugins 必须是数组")
    for plugin in plugins:
        if not isinstance(plugin, dict):
            raise VersionError("marketplace.plugins 中存在非对象条目")
        plugin.pop("version", None)
    return value


def command_validate_diff(args: argparse.Namespace) -> int:
    root = marketplace_root(args.marketplace)
    relative_marketplace = args.marketplace.resolve().relative_to(root).as_posix()
    old_marketplace = read_git_json(root, args.base, relative_marketplace)
    new_marketplace = read_git_json(root, args.target, relative_marketplace)
    if without_plugin_versions(old_marketplace) != without_plugin_versions(new_marketplace):
        raise VersionError("自动同步 PR 只能修改 marketplace 的插件 version 字段")

    old_plugins = version_by_name(old_marketplace)
    new_plugins = version_by_name(new_marketplace)
    if set(old_plugins) != set(new_plugins):
        raise VersionError("自动同步 PR 不可新增、删除或重命名市场组")

    allowed = set(args.allowed_group)
    if not allowed:
        raise VersionError("校验 marketplace 版本变更时必须给出 allowed group")
    unknown = allowed - set(old_plugins)
    if unknown:
        raise VersionError(f"unknown allowed group: {', '.join(sorted(unknown))}")

    for name in old_plugins:
        old_version = old_plugins[name]["version"]
        new_version = new_plugins[name]["version"]
        if name in allowed:
            expected = next_version(old_version)
            if new_version != expected:
                raise VersionError(
                    f"{name} 版本应从 {old_version} 递增到 {expected}，实际为 {new_version}"
                )
        elif old_version != new_version:
            raise VersionError(f"未获准修改 {name} 的版本")
    print("[marketplace-version] marketplace 版本差异校验通过")
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description="按已收录 skill 的实际内容变化维护 marketplace 场景组版本。"
    )
    commands = result.add_subparsers(dest="command", required=True)

    snapshot = commands.add_parser("snapshot")
    snapshot.add_argument("--marketplace", type=Path, required=True)
    snapshot.add_argument("--scope", type=Path, required=True)
    snapshot.add_argument("--output", required=True)
    snapshot.set_defaults(handler=command_snapshot)

    apply = commands.add_parser("apply")
    apply.add_argument("--marketplace", type=Path, required=True)
    apply.add_argument("--scope", type=Path, required=True)
    before = apply.add_mutually_exclusive_group(required=True)
    before.add_argument("--before", type=Path)
    before.add_argument("--before-stdin", action="store_true")
    apply.add_argument("--defer-file", type=Path)
    apply.add_argument("--updated", nargs="+", required=True)
    apply.set_defaults(handler=command_apply)

    bump = commands.add_parser("bump-groups")
    bump.add_argument("--marketplace", type=Path, required=True)
    bump.add_argument("--groups-file", type=Path, required=True)
    bump.set_defaults(handler=command_bump_groups)

    validate = commands.add_parser("validate-diff")
    validate.add_argument("--marketplace", type=Path, required=True)
    validate.add_argument("--base", required=True)
    validate.add_argument("--target", required=True)
    validate.add_argument("--allowed-group", action="append", default=[])
    validate.set_defaults(handler=command_validate_diff)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        return args.handler(args)
    except (OSError, VersionError) as exc:
        print(f"❌ marketplace version: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
