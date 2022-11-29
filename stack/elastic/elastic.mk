APM_SERVER_SERVICE_8200_TAGS              ?= $(patsubst %,urlprefix-%,$(APM_SERVER_SERVICE_8200_URIS))
APM_SERVER_SERVICE_8200_URIS              ?= $(patsubst %,apm-server.%,$(APP_URIS))
ELASTICSEARCH_SERVICE_9200_TAGS           ?= $(patsubst %,urlprefix-%,$(ELASTICSEARCH_SERVICE_9200_URIS))
ELASTICSEARCH_SERVICE_9200_URIS           ?= $(patsubst %,elasticsearch.%,$(APP_URIS))
ENV_VARS                                  += APM_SERVER_SERVICE_8200_TAGS ELASTICSEARCH_SERVICE_9200_TAGS KIBANA_SERVICE_5601_TAGS
KIBANA_SERVICE_5601_TAGS                  ?= $(patsubst %,urlprefix-%,$(KIBANA_SERVICE_5601_URIS))
KIBANA_SERVICE_5601_URIS                  ?= $(patsubst %,kibana.%,$(APP_URIS))

elastic                                   ?= elastic/curator elastic/elasticsearch elastic/kibana

# target elasticsearch-delete-%: delete elasticsearch index %
.PHONY: elasticsearch-delete-%
elasticsearch-delete-%:
	docker ps |awk '$$NF ~ /$(COMPOSE_PROJECT_NAME)-elasticsearch/' |sed 's/^.*:\([0-9]*\)->9200\/tcp.*$$/\1/' |while read port; do echo -e "DELETE /$* HTTP/1.0\n\n" |nc localhost $$port; done
