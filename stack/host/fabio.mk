ENV_VARS                                  += HOST_FABIO_SERVICE_9998_TAGS
HOST_FABIO_SERVICE_URIS                   ?= $(patsubst %,fabio.%,$(APP_URIS))
HOST_FABIO_SERVICE_9998_TAGS              ?= $(call urlprefix,,$(HOST_FABIO_SERVICE_9998_URIS))
HOST_FABIO_SERVICE_9998_URIS              ?= $(HOST_FABIO_SERVICE_URIS)
HOST_FABIO_UFW_UPDATE                     ?= 80/tcp 443/tcp
