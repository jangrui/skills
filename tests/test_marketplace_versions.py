#!/usr/bin/env python3
"""Regression tests for marketplace group version maintenance."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = REPO_ROOT / "scripts" / "bump-marketplace-versions.py"
SPEC = importlib.util.spec_from_file_location("marketplace_versions", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
VERSIONS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERSIONS)


class MarketplaceVersionsTest(unittest.TestCase):
    def make_fixture(self) -> tuple[tempfile.TemporaryDirectory[str], Path, Path]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        marketplace = root / ".claude-plugin" / "marketplace.json"
        alpha = root / "skills" / "acme" / "alpha"
        beta = root / "skills" / "acme" / "beta"
        alpha.mkdir(parents=True)
        beta.mkdir(parents=True)
        (alpha / "SKILL.md").write_text("# alpha\n", encoding="utf-8")
        (beta / "SKILL.md").write_text("# beta\n", encoding="utf-8")
        marketplace.parent.mkdir(parents=True)
        marketplace.write_text(
            json.dumps(
                {
                    "name": "fixture",
                    "plugins": [
                        {
                            "name": "jangrui-alpha",
                            "version": "0.0.0",
                            "skills": ["./skills/acme/alpha"],
                        },
                        {
                            "name": "jangrui-beta",
                            "version": "0.0.0",
                            "skills": ["./skills/acme/beta"],
                        },
                    ],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        return temporary, root, marketplace

    def test_decimal_carry_and_invalid_overflow(self) -> None:
        self.assertEqual(VERSIONS.next_version("0.0.0"), "0.0.1")
        self.assertEqual(VERSIONS.next_version("0.0.9"), "0.1.0")
        self.assertEqual(VERSIONS.next_version("0.9.9"), "1.0.0")
        self.assertEqual(VERSIONS.next_version("9.9.9"), "10.0.0")
        with self.assertRaises(VERSIONS.VersionError):
            VERSIONS.next_version("0.0.10")
        with self.assertRaises(VERSIONS.VersionError):
            VERSIONS.next_version("0.10.10")

    def test_only_changed_published_skill_bumps_its_group(self) -> None:
        temporary, root, marketplace = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        snapshot_path = root / "before.json"
        VERSIONS.write_json(
            snapshot_path,
            VERSIONS.make_snapshot(marketplace, root / "skills" / "acme"),
        )

        (root / "skills" / "acme" / "alpha" / "SKILL.md").write_text(
            "# alpha revised\n", encoding="utf-8"
        )
        changed, unlisted = VERSIONS.changed_groups_from_snapshot(
            marketplace,
            root / "skills" / "acme",
            snapshot_path,
            ["alpha"],
        )

        self.assertEqual(changed, ["jangrui-alpha"])
        self.assertEqual(unlisted, [])
        self.assertEqual(
            VERSIONS.bump_groups(marketplace, changed),
            [("jangrui-alpha", "0.0.0", "0.0.1")],
        )
        versions = VERSIONS.version_by_name(VERSIONS.load_json(marketplace))
        self.assertEqual(versions["jangrui-alpha"]["version"], "0.0.1")
        self.assertEqual(versions["jangrui-beta"]["version"], "0.0.0")

    def test_upstream_marker_only_does_not_bump_a_group(self) -> None:
        temporary, root, marketplace = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        snapshot_path = root / "before.json"
        VERSIONS.write_json(
            snapshot_path,
            VERSIONS.make_snapshot(marketplace, root / "skills" / "acme"),
        )

        (root / "skills" / "acme" / "alpha" / ".upstream-commit").write_text(
            "new-upstream-head\n", encoding="utf-8"
        )
        changed, unlisted = VERSIONS.changed_groups_from_snapshot(
            marketplace,
            root / "skills" / "acme",
            snapshot_path,
            ["alpha"],
        )

        self.assertEqual(changed, [])
        self.assertEqual(unlisted, [])

    def test_deferred_duplicates_bump_a_group_once(self) -> None:
        temporary, _, marketplace = self.make_fixture()
        self.addCleanup(temporary.cleanup)

        changes = VERSIONS.bump_groups(
            marketplace,
            ["jangrui-alpha", "jangrui-alpha"],
        )

        self.assertEqual(changes, [("jangrui-alpha", "0.0.0", "0.0.1")])

    def test_auto_review_accepts_only_the_expected_group_bump(self) -> None:
        temporary, root, marketplace = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(
            ["git", "config", "user.name", "test"],
            cwd=root,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "test@example.invalid"],
            cwd=root,
            check=True,
        )
        subprocess.run(["git", "add", "."], cwd=root, check=True)
        subprocess.run(["git", "commit", "-qm", "baseline"], cwd=root, check=True)

        VERSIONS.bump_groups(marketplace, ["jangrui-alpha"])
        subprocess.run(["git", "add", "."], cwd=root, check=True)
        subprocess.run(["git", "commit", "-qm", "version bump"], cwd=root, check=True)

        args = SimpleNamespace(
            marketplace=marketplace,
            base="HEAD^",
            target="HEAD",
            allowed_group=["jangrui-alpha"],
        )
        self.assertEqual(VERSIONS.command_validate_diff(args), 0)

    def test_shell_helper_defers_and_bumps_once(self) -> None:
        temporary, root, marketplace = self.make_fixture()
        self.addCleanup(temporary.cleanup)
        helper_dir = root / "scripts" / "lib"
        helper_dir.mkdir(parents=True)
        shutil.copy2(
            REPO_ROOT / "scripts" / "bump-marketplace-versions.py",
            root / "scripts" / "bump-marketplace-versions.py",
        )
        shutil.copy2(
            REPO_ROOT / "scripts" / "lib" / "marketplace-version.sh",
            helper_dir / "marketplace-version.sh",
        )

        script = r'''
          set -euo pipefail
          task_root="$1"
          UPDATED_SKILLS=(alpha)
          source "$task_root/scripts/lib/marketplace-version.sh"
          marketplace_version_snapshot "$task_root" "$task_root/skills/acme" 0
          printf '\n# revised\n' >> "$task_root/skills/acme/alpha/SKILL.md"
          MARKETPLACE_VERSION_DEFER=1 \
            MARKETPLACE_VERSION_GROUPS_FILE="$task_root/groups.txt" \
            marketplace_version_apply 0
          python3 "$task_root/scripts/bump-marketplace-versions.py" bump-groups \
            --marketplace "$task_root/.claude-plugin/marketplace.json" \
            --groups-file "$task_root/groups.txt"
        '''
        subprocess.run(["bash", "-c", script, "_", str(root)], check=True)

        versions = VERSIONS.version_by_name(VERSIONS.load_json(marketplace))
        self.assertEqual(versions["jangrui-alpha"]["version"], "0.0.1")
        self.assertEqual(versions["jangrui-beta"]["version"], "0.0.0")

    def test_workflow_covers_each_sync_script_once(self) -> None:
        workflow = (REPO_ROOT / ".github" / "workflows" / "sync-skills.yml").read_text(
            encoding="utf-8"
        )
        match = re.search(r"ALL='(?P<matrix>\[.*?\])'", workflow, re.DOTALL)
        self.assertIsNotNone(match)
        assert match is not None
        matrix = json.loads(match.group("matrix"))

        configured = [
            component
            for group in matrix
            for component in group["components"]
        ]
        scripts = sorted(
            path.name.removeprefix("sync-").removesuffix("-skills.sh")
            for path in (REPO_ROOT / "scripts").glob("sync-*-skills.sh")
        )
        self.assertEqual(sorted(configured), scripts)
        self.assertEqual(len(configured), len(set(configured)))
        self.assertEqual(
            {group["marketplace_group"] for group in matrix},
            set(VERSIONS.version_by_name(VERSIONS.load_json(
                REPO_ROOT / ".claude-plugin" / "marketplace.json"
            ))),
        )


if __name__ == "__main__":
    unittest.main()
