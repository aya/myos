ENV_VARS                                  += STATIC_SERVICE_80_TAGS
STATIC_SERVICE_80_TAGS                    ?= $(patsubst %,urlprefix-%,$(STATIC_SERVICE_80_URIS))
STATIC_SERVICE_80_URIS                    ?= $(patsubst %,static.%,$(APP_URIS))

