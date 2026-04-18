SHELL := /bin/bash

.PHONY: sync sync-commit sync-commit-default repo-to-local repo-to-local-dry-run repo-to-local-all repo-to-local-all-dry-run status

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

repo-to-local:
	@if [ -z "$(PLATFORM)" ] || [ -z "$(SKILLS)" ]; then \
		echo "用法: make repo-to-local PLATFORM=cursor SKILLS='skill-a,skill-b'"; \
		exit 1; \
	fi
	@./scripts/sync_repo_to_local.sh --platform "$(PLATFORM)" --skills "$(SKILLS)"

repo-to-local-dry-run:
	@if [ -z "$(PLATFORM)" ] || [ -z "$(SKILLS)" ]; then \
		echo "用法: make repo-to-local-dry-run PLATFORM=cursor SKILLS='skill-a,skill-b'"; \
		exit 1; \
	fi
	@./scripts/sync_repo_to_local.sh --platform "$(PLATFORM)" --skills "$(SKILLS)" --dry-run

repo-to-local-all:
	@if [ -z "$(PLATFORM)" ]; then \
		echo "用法: make repo-to-local-all PLATFORM=cursor"; \
		exit 1; \
	fi
	@./scripts/sync_repo_to_local.sh --platform "$(PLATFORM)" --all

repo-to-local-all-dry-run:
	@if [ -z "$(PLATFORM)" ]; then \
		echo "用法: make repo-to-local-all-dry-run PLATFORM=cursor"; \
		exit 1; \
	fi
	@./scripts/sync_repo_to_local.sh --platform "$(PLATFORM)" --all --dry-run

status:
	@git status --short
