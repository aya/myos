include make/include.mk

##
# APP

app-bootstrap: bootstrap-docker bootstrap-host bootstrap-user

app-build: user install-build-config
	$(call make,docker-compose-build docker-compose-up)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call make,app-build-$(service)))
	$(call make,docker-commit)

app-install: ansible-run

app-tests: ansible-tests

app-start: ssh-add

##
# BOOTSTRAP

# target bootstrap-docker: Install and configure docker
# on local host
.PHONY: bootstrap-docker
bootstrap-docker: install-bin-docker setup-docker-group setup-binfmt setup-nfsd setup-sysctl

# target bootstrap-host: Fire node target
# on local host
.PHONY: bootstrap-host
bootstrap-host: node

# target bootstrap-user: Fire User target
# on local host
.PHONY: bootstrap-user
bootstrap-user: User
