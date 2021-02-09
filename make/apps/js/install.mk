##
# INSTALL

.PHONY: install-bower
install-bower: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),npm install bower --allow-root)
	$(call docker-compose-exec,$(DOCKER_SERVICE),./node_modules/bower/bin/bower install --allow-root)

.PHONY: install-npm
install-npm: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),npm install)

.PHONY: install-npm-run-build
install-npm-run-build: install-npm-run-build-$(SYMFONY_ENV)

.PHONY: install-npm-run-build-%
install-npm-run-build-%: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),npm run build:$*)

.PHONY: install-yarn
install-yarn: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn install)
