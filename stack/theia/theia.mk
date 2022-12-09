ENV_VARS                                  += THEIA_SERVICE_3000_TAGS
THEIA_SERVICE_URIS                        ?= $(patsubst %,theai.%,$(APP_URIS))
THEIA_SERVICE_3000_TAGS                   ?= $(call urlprefix,,$(THEIA_SERVICE_3000_URIS))
THEIA_SERVICE_3000_URIS                   ?= $(THEIA_SERVICE_URIS)
