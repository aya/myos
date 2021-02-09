##
# INSTALL

.PHONY: install-assets
install-assets: install-assets-$(SYMFONY_ENV)

.PHONY: install-assets-%
install-assets-%: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console assetic:dump --env=$*)
	$(call docker-compose-exec,$(DOCKER_SERVICE),app/console assets:install --env=$*)
	$(if $(filter $(ENV),$(ENV_DEPLOY)),$(call docker-compose-exec,$(DOCKER_SERVICE),chown -R www-data web/bundles/ web/css/ web/js/))

.PHONY: install-codecept
install-codecept: bootstrap install-phpunit vendor/codeception/codeception/codecept

vendor/codeception/codeception/codecept:
	$(call composer-require-vendor-binary,codeception/codeception,codecept)

.PHONY: install-composer
install-composer: bootstrap
	$(call composer,install)

.PHONY: install-doctrine-schema-update
install-doctrine-schema-update: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),php app/console doctrine:schema:update --force)

.PHONY: install-phpcbf
install-phpcbf: bootstrap vendor/squizlabs/php_codesniffer/bin/phpcbf

vendor/squizlabs/php_codesniffer/bin/phpcbf:
	$(call composer-require-vendor-binary,squizlabs/php_codesniffer,bin/phpcbf)

.PHONY: install-phpcs
install-phpcs: bootstrap vendor/squizlabs/php_codesniffer/bin/phpcs

vendor/squizlabs/php_codesniffer/bin/phpcs:
	$(call composer-require-vendor-binary,squizlabs/php_codesniffer,bin/phpcs)

.PHONY: install-phpunit
install-phpunit: bootstrap vendor/phpunit/phpunit/phpunit

vendor/phpunit/phpunit/phpunit:
	$(call composer-require-vendor-binary,phpunit/phpunit)
