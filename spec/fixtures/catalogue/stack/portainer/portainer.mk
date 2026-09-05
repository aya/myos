ENV_VARS                                  += PORTAINER_SERVICE_9000_TAGS
PORTAINER_SERVICE_9000_NAME               ?= portainer
PORTAINER_SERVICE_9000_TAGS               ?= $(call tagprefix,portainer,9000)
