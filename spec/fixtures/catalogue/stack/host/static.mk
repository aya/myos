ENV_VARS                                  += HOST_STATIC_SERVICE_80_TAGS
HOST_STATIC_SERVICE_80_NAME               ?= static
HOST_STATIC_SERVICE_80_TAGS               ?= $(call tagprefix,HOST_STATIC,80)
