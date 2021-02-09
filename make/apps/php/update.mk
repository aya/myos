##
# UPDATE

.PHONY: update-database
update-database: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console --no-interaction doctrine:migration:migrate)
