#!/usr/bin/env python3
"""Format staged files before commit.

Reads staged file list via git diff --cached --name-only, runs the appropriate
formatter per file extension, then re-stages the formatted files.

Usage:
    python3 format_staged.py [--dry-run]

Exit codes:
    0  all formatters ran without error (or nothing to format)
    1  one or more formatters failed
    2  no supported formatter found for staged files (exits 0 by default, warnings only)
"""

import argparse
import subprocess
import sys
from pathlib import Path

# Formatter registry: extension → (command_template, check_available)
# Use {files} as placeholder for space-separated file list.
FORMATTERS = {
    '.py':   ('ruff format {files}', 'ruff'),
    '.js':   ('prettier --write {files}', 'prettier'),
    '.ts':   ('prettier --write {files}', 'prettier'),
    '.jsx':  ('prettier --write {files}', 'prettier'),
    '.tsx':  ('prettier --write {files}', 'prettier'),
    '.json': ('prettier --write {files}', 'prettier'),
    '.css':  ('prettier --write {files}', 'prettier'),
    '.scss': ('prettier --write {files}', 'prettier'),
    '.html': ('prettier --write {files}', 'prettier'),
    '.md':   ('prettier --write {files}', 'prettier'),
    '.yaml': ('prettier --write {files}', 'prettier'),
    '.yml':  ('prettier --write {files}', 'prettier'),
    '.go':   ('gofmt -w {files}', 'gofmt'),
    '.rs':   ('rustfmt {files}', 'rustfmt'),
    '.rb':   ('rubocop --auto-correct {files}', 'rubocop'),
}


def get_staged_files() -> list[Path]:
    result = subprocess.run(
        ['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMR'],
        capture_output=True, text=True, check=True,
    )
    return [Path(f) for f in result.stdout.splitlines() if f]


def is_available(binary: str) -> bool:
    result = subprocess.run(['which', binary], capture_output=True)
    if result.returncode != 0:
        # Windows fallback
        result = subprocess.run(['where', binary], capture_output=True)
    return result.returncode == 0


def run_formatter(cmd_template: str, files: list[Path]) -> bool:
    file_args = ' '.join(str(f) for f in files)
    cmd = cmd_template.format(files=file_args)
    result = subprocess.run(cmd, shell=True)
    return result.returncode == 0


def restage(files: list[Path]) -> None:
    subprocess.run(['git', 'add'] + [str(f) for f in files], check=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true', help='Print commands without running')
    args = parser.parse_args()

    staged = get_staged_files()
    if not staged:
        return 0

    # Group files by formatter
    groups: dict[str, list[Path]] = {}
    for f in staged:
        ext = f.suffix.lower()
        if ext in FORMATTERS:
            cmd_template, binary = FORMATTERS[ext]
            if not is_available(binary):
                print(f'[format_staged] skipping {ext}: {binary} not found', file=sys.stderr)
                continue
            groups.setdefault(cmd_template, []).append(f)

    if not groups:
        return 0

    failed = False
    formatted: list[Path] = []
    for cmd_template, files in groups.items():
        if args.dry_run:
            print(f'[dry-run] {cmd_template.format(files=" ".join(str(f) for f in files))}')
            continue
        ok = run_formatter(cmd_template, files)
        if ok:
            formatted.extend(files)
        else:
            print(f'[format_staged] formatter failed: {cmd_template}', file=sys.stderr)
            failed = True

    if formatted and not args.dry_run:
        restage(formatted)
        print(f'[format_staged] formatted and re-staged: {[str(f) for f in formatted]}')

    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
