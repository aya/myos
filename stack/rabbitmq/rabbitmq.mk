ENV_VARS                                  += RABBITMQ_SERVICE_15672_TAGS
RABBITMQ_SERVICE_15672_TAGS               ?= $(patsubst %,urlprefix-%,$(RABBITMQ_SERVICE_15672_URIS))
RABBITMQ_SERVICE_15672_URIS               ?= $(patsubst %,rabbitmq.%,$(APP_URIS))
