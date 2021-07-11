include make/include.mk

##
# APP

app-bootstrap: setup-docker-group setup-nfsd setup-sysctl

app-build: base install-build-config
	$(call make,docker-compose-build docker-compose-up)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call make,app-build-$(service)))
	$(call make,docker-commit)

app-install: ansible-run base node

app-tests: ansible-tests

app-start: ssh-add
