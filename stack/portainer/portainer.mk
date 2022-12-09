ENV_VARS                                  += PORTAINER_SERVICE_9000_TAGS
PORTAINER_SERVICE_URIS                    ?= $(patsubst %,portainer.%,$(APP_URIS))
PORTAINER_SERVICE_9000_TAGS               ?= $(call urlprefix,,$(PORTAINER_SERVICE_9000_URIS))
PORTAINER_SERVICE_9000_URIS               ?= $(PORTAINER_SERVICE_URIS)
