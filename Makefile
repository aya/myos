DEV_TARGETS := test test-unit test-golden test-integration test-portability lint golden-record
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
test-portability: ## Run the CLI under the /bin/sh of Alpine and Debian
	@for img in alpine:3.20 debian:13-slim; do \
	  printf '%s: ' "$$img"; \
	  tar cf - --exclude .git . | docker run -i --rm "$$img" /bin/sh -c \
	    'mkdir -p /myos && tar xf - -C /myos && cd /tmp && \
	     export PATH=/myos/spec/support/bin:$$PATH && \
	     /myos/bin/myos version >/dev/null && \
	     /myos/bin/myos -C /myos/spec/fixtures/host-project -n up host >/dev/null && \
	     echo ok'; \
	done

lint: ## shellcheck all shell sources
	$(SHELLCHECK) -s bash myos spec/golden/record.sh spec/support/run.sh spec/support/bin/* $(wildcard bin/* lib/*.sh lib/cmd/*.sh install.sh)

else
include make/include.mk
endif
