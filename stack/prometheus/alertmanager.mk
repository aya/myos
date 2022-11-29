ENV_VARS                                  += ALERTMANAGER_SLACK_WEBHOOK_ID ALERTMANAGER_SERVICE_9093_TAGS
ALERTMANAGER_SERVICE_9093_TAGS            ?= $(patsubst %,urlprefix-%,$(ALERTMANAGER_SERVICE_9093_URIS))
ALERTMANAGER_SERVICE_9093_URIS            ?= $(patsubst %,alertmanager.%,$(APP_URIS))

