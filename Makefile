DEV_TARGETS := test test-unit test-golden test-verbs test-integration test-portability lint golden-record
ifneq ($(filter $(DEV_TARGETS),$(MAKECMDGOALS)),)

SHELLSPEC ?= shellspec
SHELLCHECK ?= shellcheck
# MYOS_ENGINE selects what the golden suite runs: legacy (make/) or just (lib/)
MYOS_ENGINE ?= legacy
export MYOS_ENGINE

.PHONY: $(DEV_TARGETS)
test: ## Run every suite against MYOS_ENGINE
	$(SHELLSPEC)
test-unit: ## Unit tests of the new implementation only
	$(SHELLSPEC) spec/unit
test-golden: ## Golden tests: historical behaviour (MYOS_ENGINE=legacy|just)
	$(SHELLSPEC) spec/golden
test-verbs: ## Black-box tests of the verbs without a make history
	$(SHELLSPEC) spec/verbs
test-integration: ## Tests needing a real docker daemon
	MYOS_INTEGRATION=1 $(SHELLSPEC) spec/integration
golden-record: ## Record expectations from MYOS_ENGINE (legacy -> expected/, else expected.<engine>/)
	spec/golden/record.sh $(CASES)
test-portability: ## Run the golden suite under the /bin/sh of Alpine and Debian
	@for img in alpine:3.20 debian:13-slim; do \
	  printf '%s: ' "$$img"; \
	  tar cf - --exclude .git . | docker run -i --rm -e MYOS_ENGINE "$$img" /bin/sh -c \
	    'mkdir -p /myos && tar xf - -C /myos && cd /myos && \
	     sh spec/support/portability.sh'; \
	done

lint: ## shellcheck every shell source
	$(SHELLCHECK) -s sh myos spec/golden/record.sh spec/support/run.sh spec/support/bin/* $(wildcard lib/*.sh lib/*/*.sh install.sh)

else
include make/include.mk
endif
