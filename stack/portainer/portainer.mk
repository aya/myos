ENV_VARS                                  += PORTAINER_SERVICE_9000_TAGS
PORTAINER_SERVICE_9000_TAGS               ?= $(patsubst %,urlprefix-%,$(PORTAINER_SERVICE_9000_URIS))
PORTAINER_SERVICE_9000_URIS               ?= $(patsubst %,portainer.%,$(APP_URIS))
