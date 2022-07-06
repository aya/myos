include make/include.mk

##
# APP

app-bootstrap: bootstrap-docker

app-build: user install-build-config
	$(call make,docker-compose-build docker-compose-up)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call make,app-build-$(service)))
	$(call make,docker-commit)

app-install: ansible-run app-update-default

app-start: $(foreach stack,$(STACK),start-stack-$(stack))

app-update: ansible-pull app-update-default

app-update-default: ENV_DIST := .env
app-update-default: ENV_FILE := /etc/default/myos
app-update-default: .env-update;

app-tests: ansible-tests

##
# BOOTSTRAP

# target bootstrap-docker: Install and configure docker
.PHONY: bootstrap-docker
bootstrap-docker: install-bin-docker setup-docker-group setup-binfmt setup-nfsd setup-sysctl

# target bootstrap-stack: Call bootstrap target of each stack
.PHONY: bootstrap-stack
bootstrap-stack: docker-network-create $(foreach stack,$(STACK),bootstrap-stack-$(stack))
