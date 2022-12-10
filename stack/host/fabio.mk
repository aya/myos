ENV_VARS                                  += HOST_FABIO_SERVICE_9998_TAGS
HOST_FABIO_SERVICE_9998_NAME              ?= fabio
HOST_FABIO_SERVICE_9998_AUTH              ?= default
HOST_FABIO_SERVICE_9998_TAGS              ?= $(call tagprefix,HOST_FABIO,9998)
HOST_FABIO_UFW_UPDATE                     ?= 80/tcp 443/tcp
