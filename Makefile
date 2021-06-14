include make/include.mk

##
# APP

app-bootstrap: setup-sysctl setup-nfsd

app-build: base install-build-config
	$(call make,docker-compose-build docker-compose-up)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call make,app-build-$(service)))
	$(call make,docker-commit)

app-install: base node

app-start: ssh-add
