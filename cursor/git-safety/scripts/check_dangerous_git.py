#!/usr/bin/env python3
"""PreToolUse hook for git-safety skill: blocks dangerous git commands.

Reads the Bash tool payload from stdin, exits 2 with a stderr message when
the command matches a dangerous pattern, otherwise exits 0.
"""

import json
import re
import sys

DANGEROUS_PATTERNS = [
    r'git\s+add\s+(\.|-A|--all)(\s|$)',
    r'git\s+commit\s+-\w*a\w*m',
    r'git\s+push\s+(-f|--force)(\s|$)',
    r'git\s+reset\s+--hard',
    r'git\s+clean\s+-f',
    r'--no-verify',
]


def main() -> int:
    payload = json.load(sys.stdin)
    command = payload.get('tool_input', {}).get('command', '')
    if any(re.search(pat, command) for pat in DANGEROUS_PATTERNS):
        sys.stderr.write('blocked by git-safety hook: dangerous git command\n')
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
