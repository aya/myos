ENV_VARS                                  += ALERTMANAGER_SLACK_WEBHOOK_ID ALERTMANAGER_SERVICE_9093_TAGS
ALERTMANAGER_SERVICE_9093_NAME            ?= alertmanager
ALERTMANAGER_SERVICE_9093_TAGS            ?= $(call tagprefix,alertmanager,9093)
