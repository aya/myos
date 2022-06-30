include make/include.mk

##
# APP

app-bootstrap: bootstrap-docker bootstrap-host bootstrap-user

app-build: user install-build-config
	$(call make,docker-compose-build docker-compose-up)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call make,app-build-$(service)))
	$(call make,docker-commit)

app-install: ansible-run app-update-default

app-update: ansible-pull app-update-default

app-update-default: ENV_DIST := .env
app-update-default: ENV_FILE := /etc/default/myos
app-update-default: .env-update;

app-tests: ansible-tests

##
# BOOTSTRAP

# target bootstrap-docker: Install and configure docker
# on local host
.PHONY: bootstrap-docker
bootstrap-docker: install-bin-docker setup-docker-group setup-binfmt setup-nfsd setup-sysctl

# target bootstrap-host: Create DOCKER_NETWORK_PUBLIC
# on local host
.PHONY: bootstrap-host
bootstrap-host: docker-network-create-$(DOCKER_NETWORK_PUBLIC) node-ssl-certs

# target bootstrap-user: Create DOCKER_NETWORK_PRIVATE
# on local host
.PHONY: bootstrap-user
bootstrap-user: docker-network-create
