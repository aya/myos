ENV_VARS                                  += GRAFANA_SERVICE_3000_TAGS
GRAFANA_SERVICE_3000_NAME                 ?= grafana
GRAFANA_SERVICE_3000_TAGS                 ?= $(call tagprefix,grafana,3000)
