ENV_VARS                                  += GRAFANA_SERVICE_3000_TAGS
GRAFANA_SERVICE_3000_TAGS                 ?= $(patsubst %,urlprefix-%,$(GRAFANA_SERVICE_3000_URIS))
GRAFANA_SERVICE_3000_URIS                 ?= $(patsubst %,kibana.%,$(APP_URIS))

