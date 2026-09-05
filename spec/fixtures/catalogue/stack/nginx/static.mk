ENV_VARS                                  += STATIC_SERVICE_80_TAGS
STATIC_SERVICE_80_NAME                    ?= static
STATIC_SERVICE_80_TAGS                    ?= $(call tagprefix,STATIC,80)
