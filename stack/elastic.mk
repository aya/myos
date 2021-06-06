ELASTICSEARCH_HOST              ?= elasticsearch
ELASTICSEARCH_PORT              ?= 9200
ELASTICSEARCH_PROTOCOL          ?= http
ENV_VARS                        += ELASTICSEARCH_HOST ELASTICSEARCH_PASSWORD ELASTICSEARCH_PORT ELASTICSEARCH_PROTOCOL ELASTICSEARCH_USERNAME 

elastic                         ?= elastic/curator elastic/elasticsearch elastic/kibana alpine/sysctl

# target elasticsearch-delete-%: delete elasticsearch index %
.PHONY: elasticsearch-delete-%
elasticsearch-delete-%:
	docker ps |awk '$$NF ~ /myos_elasticsearch/' |sed 's/^.*:\([0-9]*\)->9200\/tcp.*$$/\1/' |while read port; do echo -e "DELETE /$* HTTP/1.0\n\n" |nc localhost $$port; done
