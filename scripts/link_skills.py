#!/usr/bin/env python3
"""Link skill-hub skills into local agent skill directories.

This script is intentionally stdlib-only so the Makefile works on macOS,
Linux, and Windows with a normal Python installation.
"""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BACKUP_ROOT = Path.home() / ".skill-hub-backups"


@dataclass(frozen=True)
class PlatformConfig:
    name: str
    repo_dir: Path
    local_dir: Path


def _env_path(name: str, default: Path) -> Path:
    value = os.environ.get(name)
    return Path(value).expanduser() if value else default


def platform_configs() -> dict[str, PlatformConfig]:
    return {
        "cursor": PlatformConfig(
            name="cursor",
            repo_dir=REPO_ROOT / "cursor",
            local_dir=_env_path("CURSOR_SKILLS_HOME", Path.home() / ".cursor" / "skills"),
        ),
        "claude": PlatformConfig(
            name="claude",
            repo_dir=REPO_ROOT / "cursor",
            local_dir=_env_path("CLAUDE_SKILLS_HOME", Path.home() / ".claude" / "skills"),
        ),
        "openclaw": PlatformConfig(
            name="openclaw",
            repo_dir=REPO_ROOT / "openclaw",
            local_dir=_env_path(
                "OPENCLAW_SKILLS_HOME",
                Path.home() / ".openclaw" / "workspace" / "skills",
            ),
        ),
        "agents": PlatformConfig(
            name="agents",
            repo_dir=REPO_ROOT / "agents",
            local_dir=_env_path("AGENTS_SKILLS_HOME", Path.home() / ".agents" / "skills"),
        ),
    }


def skill_dirs(repo_dir: Path) -> list[Path]:
    if not repo_dir.is_dir():
        raise SystemExit(f"Repository platform directory does not exist: {repo_dir}")

    skills: list[Path] = []
    for path in sorted(repo_dir.iterdir(), key=lambda item: item.name):
        if path.name.startswith(".") or path.name == "_template":
            continue
        if path.is_dir() and (path / "SKILL.md").is_file():
            skills.append(path)
    return skills


def is_inside(path: Path, parent: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(parent.resolve(strict=False))
        return True
    except ValueError:
        return False


def backup_existing(path: Path, platform_name: str, timestamp: str) -> Path:
    backup_path = BACKUP_ROOT / timestamp / platform_name / path.name
    backup_path.parent.mkdir(parents=True, exist_ok=True)

    if path.is_symlink() or path.is_file():
        if backup_path.exists() or backup_path.is_symlink():
            backup_path.unlink()
        shutil.copy2(path, backup_path, follow_symlinks=False)
    elif path.is_dir():
        if backup_path.exists():
            shutil.rmtree(backup_path)
        shutil.copytree(path, backup_path, symlinks=True)
    else:
        raise SystemExit(f"Unsupported existing path type: {path}")

    return backup_path


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def create_directory_link(src: Path, dst: Path) -> None:
    try:
        dst.symlink_to(src, target_is_directory=True)
        return
    except OSError as error:
        if platform.system() != "Windows":
            raise
        # Windows directory symlinks often require Developer Mode or admin rights.
        # Junctions do not need that privilege and are enough for skill discovery.
        completed = subprocess.run(
            ["cmd", "/c", "mklink", "/J", str(dst), str(src)],
            check=False,
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            details = (completed.stderr or completed.stdout or str(error)).strip()
            raise SystemExit(f"Failed to create link {dst} -> {src}: {details}") from error


def target_points_to_repo(path: Path, repo_dir: Path) -> bool:
    if not path.exists() and not path.is_symlink():
        return False
    if path.is_symlink():
        return is_inside(path.resolve(strict=False), repo_dir)
    if platform.system() == "Windows" and path.is_dir():
        # Directory junctions are resolved by Path.resolve(), but are not always
        # reported as symlinks by Python.
        return is_inside(path.resolve(strict=False), repo_dir)
    return False


def link_platform(config: PlatformConfig, dry_run: bool, timestamp: str) -> None:
    skills = skill_dirs(config.repo_dir)

    print(f"[{config.name}] repo:  {config.repo_dir}")
    print(f"[{config.name}] home:  {config.local_dir}")
    print(f"[{config.name}] skills: {len(skills)}")

    expected_names = {skill.name for skill in skills}

    if config.local_dir.exists():
        for current in sorted(config.local_dir.iterdir(), key=lambda item: item.name):
            if current.name in expected_names:
                continue
            if target_points_to_repo(current, config.repo_dir):
                print(f"[{config.name}] remove stale link: {current.name}")
                if not dry_run:
                    remove_path(current)
    elif dry_run:
        print(f"[{config.name}] would create home directory")
    else:
        config.local_dir.mkdir(parents=True, exist_ok=True)

    for src in skills:
        dst = config.local_dir / src.name
        if dst.is_symlink() and dst.resolve(strict=False) == src.resolve(strict=False):
            print(f"[{config.name}] ok: {dst.name}")
            continue

        if dst.exists() or dst.is_symlink():
            print(f"[{config.name}] replace: {dst.name}")
            if not dry_run:
                backup_existing(dst, config.name, timestamp)
                remove_path(dst)
        else:
            print(f"[{config.name}] link: {dst.name}")

        if not dry_run:
            create_directory_link(src.resolve(), dst)


def unlink_platform(config: PlatformConfig, dry_run: bool) -> None:
    if not config.local_dir.exists():
        print(f"[{config.name}] skip missing home: {config.local_dir}")
        return

    removed = 0
    for current in sorted(config.local_dir.iterdir(), key=lambda item: item.name):
        if target_points_to_repo(current, config.repo_dir):
            print(f"[{config.name}] unlink: {current.name}")
            removed += 1
            if not dry_run:
                remove_path(current)
    print(f"[{config.name}] removed links: {removed}")


def parse_platforms(values: list[str]) -> list[PlatformConfig]:
    configs = platform_configs()
    names: list[str] = []
    for value in values:
        names.extend(part.strip() for part in value.split(",") if part.strip())

    if not names or names == ["all"]:
        names = ["cursor", "claude", "openclaw", "agents"]

    unknown = sorted(set(names) - set(configs))
    if unknown:
        raise SystemExit(f"Unknown platform(s): {', '.join(unknown)}")

    return [configs[name] for name in names]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Link skill-hub repository skills into local skill home directories.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    for command in ("link", "unlink"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument(
            "--platforms",
            nargs="+",
            default=["all"],
            help="Platforms to process: cursor, claude, openclaw, agents, or all.",
        )
        subparser.add_argument(
            "--dry-run",
            action="store_true",
            help="Print planned changes without touching the filesystem.",
        )

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    selected = parse_platforms(args.platforms)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    for config in selected:
        if args.command == "link":
            link_platform(config, dry_run=args.dry_run, timestamp=timestamp)
        elif args.command == "unlink":
            unlink_platform(config, dry_run=args.dry_run)
        else:
            raise SystemExit(f"Unsupported command: {args.command}")

    if args.command == "link" and not args.dry_run:
        print(f"Backups for replaced entries: {BACKUP_ROOT / timestamp}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
