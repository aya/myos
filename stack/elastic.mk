elastic                         ?= elastic/curator elastic/elasticsearch elastic/kibana alpine/sysctl

.PHONY: elasticsearch-delete-%
elasticsearch-delete-%:
	docker ps |awk '$$NF ~ /myos_elasticsearch/' |sed 's/^.*:\([0-9]*\)->9200\/tcp.*$$/\1/' |while read port; do echo -e "DELETE /$* HTTP/1.0\n\n" |nc localhost $$port; done

