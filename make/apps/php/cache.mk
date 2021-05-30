##
# CACHE

## Clear symfony cache
.PHONY: cache-clear
cache-clear: cache-clear-$(SYMFONY_ENV)

.PHONY: cache-clear-%
cache-clear-%: bootstrap ## Clear symfony cache
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console cache:clear --env=$*)

.PHONY: cache-warmup
cache-warmup: cache-warmup-$(SYMFONY_ENV)

.PHONY: cache-warmup-%
cache-warmup-%: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console cache:warmup --env=$*)
