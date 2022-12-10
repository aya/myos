ENV_VARS                                  += RABBITMQ_SERVICE_15672_TAGS
RABBITMQ_SERVICE_15672_NAME               ?= rabbitmq
RABBITMQ_SERVICE_15672_TAGS               ?= $(call tagprefix,rabbitmq,15672)
