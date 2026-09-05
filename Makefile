# Development targets. The engine itself is ./myos (lib/main.sh); this file
# only runs the test suites and the linters.
SHELLSPEC ?= shellspec
SHELLCHECK ?= shellcheck
MYOS_ENGINE ?= just
export MYOS_ENGINE

.PHONY: test test-unit test-golden test-verbs test-integration test-portability lint golden-record bench
test: ## Run every suite
	$(SHELLSPEC)
test-unit: ## Unit tests of the functions
	$(SHELLSPEC) spec/unit
test-golden: ## Golden tests: the recorded behaviour of every verb
	$(SHELLSPEC) spec/golden
test-verbs: ## Black-box tests of the lifecycle verbs against the docker mock
	$(SHELLSPEC) spec/verbs
test-integration: ## Tests needing a real docker daemon
	MYOS_INTEGRATION=1 $(SHELLSPEC) spec/integration
golden-record: ## Re-record the expectations (CASES="name ..." for a subset)
	spec/golden/record.sh $(CASES)
test-portability: ## Run the golden suite under the /bin/sh of Alpine (busybox) and Debian (dash)
	@for img in alpine:3.20 debian:13-slim; do \
	  printf '%s: ' "$$img"; \
	  tar cf - --exclude .git . | docker run -i --rm -e MYOS_ENGINE -e DEBIAN_FRONTEND=noninteractive "$$img" /bin/sh -c \
	    '{ apk add -q openssl 2>/dev/null || { apt-get -qq update >/dev/null && apt-get -qq install -y openssl >/dev/null 2>&1; }; } && \
	     mkdir -p /opt/engine && tar xf - -C /opt/engine && cd /opt/engine && sh spec/support/portability.sh'; \
	done
bench: ## Measure the engine (spec/bench)
	spec/bench/run.sh
lint: ## shellcheck every shell source
	$(SHELLCHECK) -s sh -S warning myos lib/*.sh lib/verb/*.sh spec/support/run.sh spec/support/try.sh spec/support/portability.sh spec/support/bin/* spec/golden/record.sh install.sh
