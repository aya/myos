##
# DEV

.PHONY: dev-phpcs
dev-phpcs: bootstrap install-phpcs
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpcs --standard=PSR2 --colors -p ./src)

.PHONY: dev-phpcbf
dev-phpcbf: bootstrap install-phpcbf
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpcbf ./src/ --ignore=*.js)
