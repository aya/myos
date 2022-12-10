APM_SERVER_SERVICE_8200_NAME              ?= apm-server
APM_SERVER_SERVICE_8200_TAGS              ?= $(call tagprefix,apm-server,8200)
ELASTICSEARCH_SERVICE_9200_NAME           ?= elasticsearch
ELASTICSEARCH_SERVICE_9200_TAGS           ?= $(call tagprefix,elasticsearch,9200)
ENV_VARS                                  += APM_SERVER_SERVICE_8200_TAGS ELASTICSEARCH_SERVICE_9200_TAGS KIBANA_SERVICE_5601_TAGS
KIBANA_SERVICE_NAME                       ?= kibana
KIBANA_SERVICE_5601_TAGS                  ?= $(call tagprefix,kibana,5601)

elastic                                   ?= elastic/curator elastic/elasticsearch elastic/kibana

# target elasticsearch-delete-%: delete elasticsearch index %
.PHONY: elasticsearch-delete-%
elasticsearch-delete-%:
	docker ps |awk '$$NF ~ /$(COMPOSE_PROJECT_NAME)-elasticsearch/' |sed 's/^.*:\([0-9]*\)->9200\/tcp.*$$/\1/' |while read port; do echo -e "DELETE /$* HTTP/1.0\n\n" |nc localhost $$port; done
