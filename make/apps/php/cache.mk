##
# CACHE

## Clear symfony cache
.PHONY: cache-clear
cache-clear: cache-clear-dev cache-clear-prod

.PHONY: cache-clear-%
cache-clear-%: bootstrap ## Clear symfony cache
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console cache:clear --env=$*)

.PHONY: cache-rm
cache-rm: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -Rf app/cache/* app/logs/*)
	$(if $(filter $(ENV),$(ENV_DEPLOY)),$(call docker-compose-exec,$(DOCKER_SERVICE),chown www-data app/cache/ app/logs/))

.PHONY: cache-warmup
cache-warmup: cache-warmup-$(SYMFONY_ENV)
	$(if $(filter $(ENV),$(ENV_DEPLOY)),$(call docker-compose-exec,$(DOCKER_SERVICE),chown -R www-data app/cache/ app/logs/))

.PHONY: cache-warmup-%
cache-warmup-%: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console cache:warmup --env=$*)
