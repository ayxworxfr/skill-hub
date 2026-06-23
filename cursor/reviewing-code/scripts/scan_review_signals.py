#!/usr/bin/env python3
"""Scan a diff for review signal candidates.

Reads a unified diff (from file or stdin) and outputs a structured list of
candidate findings for human review. Each candidate includes the matched
pattern, location, and severity hint.

Linked to:
  - building/SKILL.md §3.1 R1-R7 (AI anti-patterns)
  - git-safety/SKILL.md §安全规则 (sensitive files)

Usage:
    # From staged changes
    git diff --cached > /tmp/staged.diff
    python3 scan_review_signals.py --diff /tmp/staged.diff

    # From a commit range
    git diff main...HEAD > /tmp/pr.diff
    python3 scan_review_signals.py --diff /tmp/pr.diff --output candidates.json

    # From stdin
    git diff HEAD~1 | python3 scan_review_signals.py

Exit codes:
    0  scan completed (candidates may or may not exist)
    1  input error (file not found, invalid diff)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path


# ---------------------------------------------------------------------------
# Pattern registries
# ---------------------------------------------------------------------------

# R2 silent fake success —吞异常、静默返回掩盖错误
SILENT_FAILURE_PATTERNS: list[tuple[str, str, str]] = [
    # (regex, severity_hint, description)
    (r'except\s*:\s*(pass|\.\.\.)', 'Critical', 'R2: bare except swallowed — no error handling'),
    (r'except\s+Exception\s*:\s*(pass|\.\.\.)', 'Critical', 'R2: Exception caught and swallowed'),
    (r'except\s+\w+\s+as\s+\w+\s*:\s*(pass|\.\.\.)', 'Major', 'R2: named exception caught and swallowed'),
    (r'catch\s*\([^)]*\)\s*\{\s*\}', 'Critical', 'R2: empty catch block (JS/TS/Java/Go)'),
    (r'catch\s*\([^)]*\)\s*\{\s*//', 'Major', 'R2: catch block with only comments'),
    (r'return\s+None\b(?!\s*#\s*ok)', 'Minor', 'R2: implicit None return — verify callers handle it'),
    (r'return\s+\[\]\s*$', 'Minor', 'R2: empty list returned — may silently hide failure'),
    (r'return\s+\{\}\s*$', 'Minor', 'R2: empty dict returned — may silently hide failure'),
]

# R1 hallucination — import 不存在的库（靠文件级检查）
SUSPICIOUS_IMPORT_PATTERNS: list[tuple[str, str, str]] = [
    (r'^\+\s*(import|from)\s+([\w.]+)', 'Minor', 'R1: new import — verify package exists in lockfile'),
    (r'^\+\s*require\([\'"]([^\'"]+)[\'"]\)', 'Minor', 'R1: new require — verify in package.json'),
]

# R7 修测试让代码通过 — 断言弱化
TEST_WEAKENING_PATTERNS: list[tuple[str, str, str]] = [
    (r'assert\w*IsNotNone\b', 'Major', 'R7: assertIsNotNone may replace stricter assertion'),
    (r'assert\w*True\b', 'Major', 'R7: assertTrue may replace stricter assertEqual'),
    (r'toBeNull\(\)', 'Minor', 'R7: toBeNull may have replaced stricter matcher'),
    (r'toBeDefined\(\)', 'Minor', 'R7: toBeDefined may have replaced stricter matcher'),
    (r'\.skip\b|xit\(|xdescribe\(|@pytest\.mark\.skip', 'Major', 'R7: test skipped — intentional or workaround?'),
]

# Debug残留 (R2 adjacent)
DEBUG_RESIDUAL_PATTERNS: list[tuple[str, str, str]] = [
    (r'\bprint\s*\(', 'Minor', 'debug: print() left in production code'),
    (r'\bconsole\.log\s*\(', 'Minor', 'debug: console.log() left in production code'),
    (r'\bdebugger\b', 'Major', 'debug: debugger statement left in code'),
    (r'\bpdb\.set_trace\b|\bbreakpoint\s*\(\)', 'Critical', 'debug: breakpoint left in production code'),
    (r'\bTODO\b|\bFIXME\b|\bXXX\b|\bHACK\b', 'Minor', 'debt: TODO/FIXME marker in new code'),
]

# Sensitive file patterns (联动 git-safety §安全规则)
SENSITIVE_FILE_PATTERNS: list[tuple[str, str]] = [
    # (glob-style suffix or name, description)
    (r'\.env$', 'sensitive: .env file modified'),
    (r'\.env\.\w+$', 'sensitive: environment config file modified'),
    (r'(private|id_rsa|id_ed25519|\.pem|\.key|\.pfx|\.p12)$', 'sensitive: private key or cert file'),
    (r'credentials?\.(json|yaml|yml|toml)$', 'sensitive: credentials file'),
    (r'secrets?\.(json|yaml|yml|toml)$', 'sensitive: secrets file'),
    (r'(password|passwd|secret|token|api[_-]?key)[s]?\.(txt|json|yaml|yml)$', 'sensitive: secret value file'),
]

# Hardcoded secrets in added lines
SECRET_IN_CODE_PATTERNS: list[tuple[str, str, str]] = [
    (r'(password|passwd|secret|api[_-]?key|token|private[_-]?key)\s*=\s*["\'][^"\']{8,}["\']',
     'Critical', 'security: hardcoded secret value detected'),
    (r'(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY)\s*=\s*["\'][A-Z0-9+/]{16,}["\']',
     'Critical', 'security: hardcoded AWS credential'),
    (r'(sk-|xox[baprs]-|ghp_|gho_|github_pat_)[A-Za-z0-9_-]{10,}',
     'Critical', 'security: hardcoded API token pattern (OpenAI/Slack/GitHub)'),
    (r'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY',
     'Critical', 'security: private key content in diff'),
]

# Large file detection (checked per file header in diff)
LARGE_FILE_THRESHOLD_LINES = 500

# Binary file marker
BINARY_FILE_PATTERN = re.compile(r'^Binary files .* differ$', re.MULTILINE)

# Test file heuristic
TEST_FILE_PATTERN = re.compile(
    r'(test_|_test\.|\.test\.|\.spec\.|/tests?/|/spec/)',
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class Candidate:
    severity: str          # Critical / Major / Minor
    category: str          # r1/r2/r7/debug/sensitive/security/size
    file: str
    line: int              # 1-based line number in diff (0 = file-level)
    code_line: str         # the actual line content
    description: str
    action: str = 'manual review'

    def display(self) -> str:
        loc = f'{self.file}:{self.line}' if self.line else self.file
        return f'[{self.severity}] {loc} — {self.description}'


@dataclass
class ScanResult:
    total: int = 0
    critical: int = 0
    major: int = 0
    minor: int = 0
    candidates: list[Candidate] = field(default_factory=list)

    def add(self, c: Candidate) -> None:
        self.candidates.append(c)
        self.total += 1
        if c.severity == 'Critical':
            self.critical += 1
        elif c.severity == 'Major':
            self.major += 1
        else:
            self.minor += 1


# ---------------------------------------------------------------------------
# Diff parser
# ---------------------------------------------------------------------------

@dataclass
class DiffFile:
    path: str
    is_test: bool
    is_binary: bool
    added_lines: list[tuple[int, str]]  # (line_no_in_diff, content)
    total_added: int


def parse_diff(diff_text: str) -> list[DiffFile]:
    """Parse unified diff into per-file structures."""
    files: list[DiffFile] = []
    current_file: str = ''
    current_lines: list[tuple[int, str]] = []
    current_added: int = 0
    is_binary = False
    diff_line_no = 0

    for raw_line in diff_text.splitlines():
        diff_line_no += 1

        # New file header
        if raw_line.startswith('diff --git '):
            if current_file:
                files.append(DiffFile(
                    path=current_file,
                    is_test=bool(TEST_FILE_PATTERN.search(current_file)),
                    is_binary=is_binary,
                    added_lines=current_lines,
                    total_added=current_added,
                ))
            # Extract b/ path
            m = re.search(r' b/(.+)$', raw_line)
            current_file = m.group(1) if m else raw_line
            current_lines = []
            current_added = 0
            is_binary = False
            continue

        if BINARY_FILE_PATTERN.match(raw_line):
            is_binary = True
            continue

        # Added line
        if raw_line.startswith('+') and not raw_line.startswith('+++'):
            current_lines.append((diff_line_no, raw_line[1:]))
            current_added += 1

    if current_file:
        files.append(DiffFile(
            path=current_file,
            is_test=bool(TEST_FILE_PATTERN.search(current_file)),
            is_binary=is_binary,
            added_lines=current_lines,
            total_added=current_added,
        ))

    return files


# ---------------------------------------------------------------------------
# Scanners
# ---------------------------------------------------------------------------

def _scan_patterns(
    diff_file: DiffFile,
    patterns: list[tuple[str, str, str]],
    category: str,
    result: ScanResult,
    skip_test_files: bool = False,
) -> None:
    if skip_test_files and diff_file.is_test:
        return
    for regex, severity, description in patterns:
        compiled = re.compile(regex)
        for line_no, content in diff_file.added_lines:
            if compiled.search(content):
                result.add(Candidate(
                    severity=severity,
                    category=category,
                    file=diff_file.path,
                    line=line_no,
                    code_line=content.rstrip(),
                    description=description,
                ))


def scan_silent_failures(diff_file: DiffFile, result: ScanResult) -> None:
    _scan_patterns(diff_file, SILENT_FAILURE_PATTERNS, 'r2-silent-failure', result,
                   skip_test_files=True)


def scan_new_imports(diff_file: DiffFile, result: ScanResult) -> None:
    _scan_patterns(diff_file, SUSPICIOUS_IMPORT_PATTERNS, 'r1-import', result)


def scan_test_weakening(diff_file: DiffFile, result: ScanResult) -> None:
    if not diff_file.is_test:
        return
    _scan_patterns(diff_file, TEST_WEAKENING_PATTERNS, 'r7-test-weakening', result)


def scan_debug_residuals(diff_file: DiffFile, result: ScanResult) -> None:
    _scan_patterns(diff_file, DEBUG_RESIDUAL_PATTERNS, 'debug-residual', result,
                   skip_test_files=True)


def scan_hardcoded_secrets(diff_file: DiffFile, result: ScanResult) -> None:
    _scan_patterns(diff_file, SECRET_IN_CODE_PATTERNS, 'security-secret', result)


def scan_sensitive_file(diff_file: DiffFile, result: ScanResult) -> None:
    for pattern, description in SENSITIVE_FILE_PATTERNS:
        if re.search(pattern, diff_file.path, re.IGNORECASE):
            result.add(Candidate(
                severity='Critical',
                category='sensitive-file',
                file=diff_file.path,
                line=0,
                code_line='',
                description=description,
                action='check file contents for secrets before committing',
            ))
            break


def scan_binary_or_large(diff_file: DiffFile, result: ScanResult) -> None:
    if diff_file.is_binary:
        result.add(Candidate(
            severity='Minor',
            category='binary-file',
            file=diff_file.path,
            line=0,
            code_line='',
            description='binary file added/modified — verify intentional',
        ))
    elif diff_file.total_added > LARGE_FILE_THRESHOLD_LINES:
        result.add(Candidate(
            severity='Minor',
            category='large-diff',
            file=diff_file.path,
            line=0,
            code_line='',
            description=f'large diff: {diff_file.total_added} added lines — consider splitting',
        ))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def scan(diff_text: str) -> ScanResult:
    result = ScanResult()
    files = parse_diff(diff_text)

    for diff_file in files:
        scan_sensitive_file(diff_file, result)
        scan_binary_or_large(diff_file, result)
        scan_hardcoded_secrets(diff_file, result)
        scan_silent_failures(diff_file, result)
        scan_new_imports(diff_file, result)
        scan_test_weakening(diff_file, result)
        scan_debug_residuals(diff_file, result)

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--diff', metavar='FILE',
                        help='path to unified diff file (default: stdin)')
    parser.add_argument('--output', metavar='FILE',
                        help='write JSON output to file (default: stdout)')
    parser.add_argument('--min-severity', choices=['Critical', 'Major', 'Minor'],
                        default='Minor', help='minimum severity to report')
    args = parser.parse_args()

    # Read diff
    try:
        if args.diff:
            diff_text = Path(args.diff).read_text(encoding='utf-8', errors='replace')
        else:
            diff_text = sys.stdin.read()
    except (OSError, IOError) as e:
        print(f'error: {e}', file=sys.stderr)
        return 1

    result = scan(diff_text)

    # Filter by severity
    severity_order = {'Critical': 0, 'Major': 1, 'Minor': 2}
    min_level = severity_order[args.min_severity]
    filtered = [c for c in result.candidates
                if severity_order.get(c.severity, 99) <= min_level]

    # Build output
    output = {
        'summary': {
            'total': len(filtered),
            'critical': sum(1 for c in filtered if c.severity == 'Critical'),
            'major': sum(1 for c in filtered if c.severity == 'Major'),
            'minor': sum(1 for c in filtered if c.severity == 'Minor'),
        },
        'candidates': [asdict(c) for c in filtered],
    }

    # Print human-readable summary to stderr
    print(f'\nscan_review_signals: {len(filtered)} candidates '
          f'(Critical={output["summary"]["critical"]}, '
          f'Major={output["summary"]["major"]}, '
          f'Minor={output["summary"]["minor"]})\n', file=sys.stderr)

    for c in filtered:
        print(f'  {c.display()}', file=sys.stderr)

    if filtered:
        print('', file=sys.stderr)

    # Write JSON
    json_output = json.dumps(output, ensure_ascii=False, indent=2)
    if args.output:
        Path(args.output).write_text(json_output, encoding='utf-8')
    else:
        print(json_output)

    return 0


if __name__ == '__main__':
    sys.exit(main())
