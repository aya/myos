include make/include.mk

##
# APP

.PHONY: app-bootstrap
app-bootstrap: setup-sysctl
ifeq ($(SETUP_NFSD),true)
ifeq ($(HOST_SYSTEM),DARWIN)
	$(call setup-nfsd-osx)
endif
endif

.PHONY: app-build
app-build: myos-base install-build-parameters
	$(call make,docker-compose-build up)
	$(call make,docker-compose-exec ARGS='rm -Rf /root/.npm /log-buffer/*' SERVICE=logagent)
	$(call make,docker-commit)

.PHONY: app-install
app-install: base node up

.PHONY: app-start
app-start: base-ssh-add

.PHONY: app-tests
app-tests:
	echo ENV: $(env)
	echo DOCKER_ENV: $(DOCKER_ENV)
