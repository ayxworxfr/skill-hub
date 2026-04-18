#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CURSOR_SKILLS_SRC="${CURSOR_SKILLS_SRC:-$HOME/.cursor/skills}"
OPENCLAW_SKILLS_SRC="${OPENCLAW_SKILLS_SRC:-$HOME/.openclaw/workspace/skills}"
AGENTS_SKILLS_SRC="${AGENTS_SKILLS_SRC:-$HOME/.agents/skills}"

echo "仓库路径: $REPO_ROOT"
echo "Cursor 源目录: $CURSOR_SKILLS_SRC"
echo "OpenClaw 源目录: $OPENCLAW_SKILLS_SRC"
echo "Agents 源目录: $AGENTS_SKILLS_SRC"

if [ ! -d "$CURSOR_SKILLS_SRC" ]; then
  echo "错误: Cursor 源目录不存在: $CURSOR_SKILLS_SRC"
  exit 1
fi

if [ ! -d "$OPENCLAW_SKILLS_SRC" ]; then
  echo "错误: OpenClaw 源目录不存在: $OPENCLAW_SKILLS_SRC"
  exit 1
fi

if [ ! -d "$AGENTS_SKILLS_SRC" ]; then
  echo "错误: Agents 源目录不存在: $AGENTS_SKILLS_SRC"
  exit 1
fi

rsync -av --delete \
  --exclude ".DS_Store" \
  --exclude ".git/" \
  --exclude "README.md" \
  --exclude "_template/" \
  "$CURSOR_SKILLS_SRC"/ "$REPO_ROOT/cursor"/

rsync -av --delete \
  --exclude ".DS_Store" \
  --exclude ".git/" \
  --exclude "README.md" \
  --exclude "_template/" \
  "$OPENCLAW_SKILLS_SRC"/ "$REPO_ROOT/openclaw"/

rsync -av --delete \
  --exclude ".DS_Store" \
  --exclude ".git/" \
  --exclude "README.md" \
  --exclude "_template/" \
  "$AGENTS_SKILLS_SRC"/ "$REPO_ROOT/agents"/

echo "本地 skills 已同步到仓库目录。"
