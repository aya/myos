ENV_VARS                                  += HOST_PORTAINER_SERVICE_9000_TAGS
HOST_PORTAINER_SERVICE_9000_NAME          ?= portainer
HOST_PORTAINER_SERVICE_9000_TAGS          ?= $(call tagprefix,HOST_PORTAINER,9000)
