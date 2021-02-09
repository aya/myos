##
# CLEAN

.PHONY: clean-js-app
clean-js-app: clean-js-assets-deps

.PHONY: clean-js-assets-deps
clean-js-assets-deps: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),rm -Rf node_modules/*)
