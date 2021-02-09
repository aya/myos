##
# CLEAN

.PHONY: clean-docker-%
clean-docker-%:
	docker ps -a |awk '$$NF ~ /_$*/ && $$NF !~ /_infra_/ {print $$NF}' |while read docker; do docker rm -f $$docker; done

.PHONY: clean-elasticsearch-%
clean-elasticsearch-%:
	docker ps |awk '$$NF ~ /infra_elasticsearch/' |sed 's/^.*:\([0-9]*\)->9200\/tcp.*$$/\1/' |while read port; do echo -e "DELETE /$* HTTP/1.0\n\n" |nc localhost $$port; done

.PHONY: clean-images-%
clean-images-%:
	docker images |awk '$$1 ~ /\/$*/ && $$1 !~ /\/infra\// {print $$3}' |sort -u |while read image; do docker rmi -f $$image; done

.PHONY: clean-volumes-%
clean-volumes-%:
	docker volume ls |awk '$$2 ~ /_$*/ && $$2 !~ /_infra_/ {print $$2}' |sort -u |while read volume; do docker volume rm $$volume; done
