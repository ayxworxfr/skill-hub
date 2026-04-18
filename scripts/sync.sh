#!/usr/bin/env bash

set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "用法: ./scripts/sync.sh \"提交信息\""
  exit 1
fi

commit_message="$1"

git add -A

if git diff --cached --quiet; then
  echo "没有可提交的变更。"
  exit 0
fi

git commit -m "$commit_message"
git push

echo "已完成提交并推送。"
