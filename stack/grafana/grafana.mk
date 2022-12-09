ENV_VARS                                  += GRAFANA_SERVICE_3000_TAGS
GRAFANA_SERVICE_URIS                      ?= $(patsubst %,grafana.%,$(APP_URIS))
GRAFANA_SERVICE_3000_TAGS                 ?= $(call urlprefix,,$(GRAFANA_SERVICE_3000_URIS))
GRAFANA_SERVICE_3000_URIS                 ?= $(GRAFANA_SERVICE_URIS)
