##
# CLEAN

.PHONY: clean-php-app
clean-php-app: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf app/bootstrap.php.cache)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf app/cache/* app/cach~)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf app/logs/*)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf var/cache/* var/cach~)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf var/logs/*)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf vendor/*)
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -rf node_modules/*)
