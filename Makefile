SHELL := /bin/bash

.PHONY: sync sync-commit sync-commit-default status

sync:
	@./scripts/sync_local_skills.sh

sync-commit:
	@if [ -z "$(MSG)" ]; then \
		echo "用法: make sync-commit MSG='chore: 同步本地 skills'"; \
		exit 1; \
	fi
	@./scripts/sync_local_skills.sh
	@./scripts/sync.sh "$(MSG)"

sync-commit-default:
	@./scripts/sync_local_skills.sh
	@./scripts/sync.sh "chore: sync local skills"

status:
	@git status --short
