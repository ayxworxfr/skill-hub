#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CURSOR_SKILLS_DST="${CURSOR_SKILLS_DST:-$HOME/.cursor/skills}"
OPENCLAW_SKILLS_DST="${OPENCLAW_SKILLS_DST:-$HOME/.openclaw/workspace/skills}"
AGENTS_SKILLS_DST="${AGENTS_SKILLS_DST:-$HOME/.agents/skills}"

platform=""
skills_csv=""
sync_all="false"
dry_run="false"

usage() {
  echo "用法:"
  echo "  ./scripts/sync_repo_to_local.sh --platform <cursor|openclaw|agents> --skills <skill1,skill2>"
  echo "  ./scripts/sync_repo_to_local.sh --platform <cursor|openclaw|agents> --all"
  echo "可选参数:"
  echo "  --dry-run    仅预览，不实际覆盖本地"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      platform="${2:-}"
      shift 2
      ;;
    --skills)
      skills_csv="${2:-}"
      shift 2
      ;;
    --all)
      sync_all="true"
      shift
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "错误: 未知参数 $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$platform" ]; then
  echo "错误: 必须指定 --platform"
  usage
  exit 1
fi

if [ "$sync_all" = "true" ] && [ -n "$skills_csv" ]; then
  echo "错误: --all 与 --skills 不能同时使用"
  exit 1
fi

if [ "$sync_all" = "false" ] && [ -z "$skills_csv" ]; then
  echo "错误: 必须指定 --skills 或 --all"
  usage
  exit 1
fi

case "$platform" in
  cursor)
    local_dst="$CURSOR_SKILLS_DST"
    ;;
  openclaw)
    local_dst="$OPENCLAW_SKILLS_DST"
    ;;
  agents)
    local_dst="$AGENTS_SKILLS_DST"
    ;;
  *)
    echo "错误: --platform 仅支持 cursor/openclaw/agents"
    exit 1
    ;;
esac

repo_platform_dir="$REPO_ROOT/$platform"

if [ ! -d "$repo_platform_dir" ]; then
  echo "错误: 仓库平台目录不存在: $repo_platform_dir"
  exit 1
fi

if [ ! -d "$local_dst" ]; then
  echo "错误: 本地目标目录不存在: $local_dst"
  exit 1
fi

skills=()
if [ "$sync_all" = "true" ]; then
  for dir in "$repo_platform_dir"/*; do
    [ -d "$dir" ] || continue
    base="$(basename "$dir")"
    [ "$base" = "_template" ] && continue
    skills+=("$base")
  done
else
  IFS=',' read -r -a skills <<< "$skills_csv"
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "错误: 没有可同步的 skill"
  exit 1
fi

echo "仓库目录: $REPO_ROOT"
echo "平台: $platform"
echo "本地目标目录: $local_dst"
echo "执行模式: $([ "$dry_run" = "true" ] && echo "dry-run" || echo "apply")"

for skill in "${skills[@]}"; do
  skill="$(echo "$skill" | xargs)"
  [ -z "$skill" ] && continue
  [ "$skill" = "_template" ] && continue
  [ "$skill" = "README.md" ] && continue

  src="$repo_platform_dir/$skill"
  dst="$local_dst/$skill"

  if [ ! -d "$src" ]; then
    echo "错误: 仓库中不存在 skill: $platform/$skill"
    exit 1
  fi

  echo "同步 $platform/$skill -> $dst"
  mkdir -p "$dst"

  if [ "$dry_run" = "true" ]; then
    rsync -avn --delete \
      --exclude ".DS_Store" \
      --exclude ".git/" \
      "$src"/ "$dst"/
  else
    rsync -av --delete \
      --exclude ".DS_Store" \
      --exclude ".git/" \
      "$src"/ "$dst"/
  fi
done

echo "完成：已将仓库 skill 同步覆盖到本地。"
