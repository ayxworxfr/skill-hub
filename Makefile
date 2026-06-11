PYTHON ?= python3
NODE ?= node
PLATFORMS ?= cursor claude openclaw agents
LINK_SCRIPT := scripts/link_skills.py

.PHONY: help link link-dry-run unlink unlink-dry-run install install-cursor status

help:
	@$(PYTHON) $(LINK_SCRIPT) --help

link:
	@$(PYTHON) $(LINK_SCRIPT) link --platforms $(PLATFORMS)

link-dry-run:
	@$(PYTHON) $(LINK_SCRIPT) link --platforms $(PLATFORMS) --dry-run

unlink:
	@$(PYTHON) $(LINK_SCRIPT) unlink --platforms $(PLATFORMS)

unlink-dry-run:
	@$(PYTHON) $(LINK_SCRIPT) unlink --platforms $(PLATFORMS) --dry-run

install:
	@$(NODE) bin/install.mjs --force

install-cursor:
	@$(NODE) bin/install.mjs --cursor --force

status:
	@git status --short
