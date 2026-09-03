DEV_TARGETS := test test-unit test-golden test-integration lint golden-record
ifneq ($(filter $(DEV_TARGETS),$(MAKECMDGOALS)),)

SHELLSPEC ?= shellspec
SHELLCHECK ?= shellcheck

.PHONY: $(DEV_TARGETS)
test: ## Run unit + golden tests against both engines
	$(SHELLSPEC)
	MYOS_ENGINE=cli $(SHELLSPEC) spec/golden
test-unit: ## Run unit tests only
	$(SHELLSPEC) spec/unit
test-golden: ## Run golden tests only (MYOS_ENGINE=legacy|cli)
	$(SHELLSPEC) spec/golden
test-integration: ## Run tests needing a real docker daemon
	MYOS_INTEGRATION=1 $(SHELLSPEC) spec/integration
golden-record: ## Re-record golden expectations from the legacy engine
	spec/golden/record.sh $(CASES)
lint: ## shellcheck all shell sources
	$(SHELLCHECK) -s bash myos spec/golden/record.sh spec/support/run.sh spec/support/bin/* $(wildcard bin/* lib/*.sh lib/cmd/*.sh install.sh)

else
include make/include.mk
endif
