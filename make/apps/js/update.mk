##
# UPDATE

.PHONY: update-npm
update-npm: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),npm upgrade)
