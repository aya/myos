ENV_VARS                                  += BLACKBOX_SERVICE_9115_TAGS
BLACKBOX_PRIMARY_TARGETS                  ?= $(PROMETHEUS_BLACKBOX_PRIMARY_TARGETS)
BLACKBOX_SECONDARY_TARGETS                ?= $(PROMETHEUS_BLACKBOX_SECONDARY_TARGETS)
BLACKBOX_SERVICE_9115_TAGS                ?= $(patsubst %,urlprefix-%,$(BLACKBOX_SERVICE_9115_URIS))
BLACKBOX_SERVICE_9115_URIS                ?= $(patsubst %,blackbox.%,$(APP_URIS))
