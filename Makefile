PYTHON ?= python3
PLATFORMS ?= cursor claude openclaw agents
LINK_SCRIPT := scripts/link_skills.py

.PHONY: help link link-dry-run unlink unlink-dry-run status

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

status:
	@git status --short
