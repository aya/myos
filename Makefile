MYOS                                      ?= ../myos
MYOS_REPOSITORY                           ?= $(patsubst %/$(APP),%/myos,$(APP_REPOSITORY))
APP                                       ?= $(lastword $(subst /, ,$(APP_REPOSITORY)))
APP_REPOSITORY                            ?= $(shell git config --get remote.origin.url 2>/dev/null)
$(MYOS):
	-@git clone $(MYOS_REPOSITORY) $(MYOS)
-include $(MYOS)/make/include.mk

##
# APP

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
