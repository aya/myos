##
# TEST

## Run unit tests
.PHONY: test
test: test-unit ## Run unit tests

## Run codeception tests
.PHONY: test-codeception-%
test-codeception-%: bootstrap install-codecept ## Run codeception tests
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/codecept run $*)

## Run old unit tests with code coverage
.PHONY: test-coverage
test-coverage: bootstrap install-phpunit ## Run code coverage
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpunit --testsuite unit --coverage-text)

## Run codeception tests with coverage
.PHONY: test-coverage-codeception-%
test-coverage-codeception-%: bootstrap install-codecept ## Run codeception tests with coverage
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/codecept run $* --coverage --coverage-html)

## Run phpunit functional tests
.PHONY: test-func
test-func: bootstrap install-phpunit ## Run functional tests
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpunit --testsuite functional)

## Loop unit tests
.PHONY: test-loop
test-loop: bootstrap install-phpunit ## Loop unit tests
	while true; \
		do $(MAKE) test; \
		read continue; \
	done;

## Run search tests
.PHONY: test-search
test-search: bootstrap install-phpunit ## Run search tests
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpunit --testsuite search)

.PHONY: test-templates
test-templates: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),php app/console lint:twig @UIBundle)

## Run old unit tests
.PHONY: test-unit
test-unit: bootstrap install-phpunit ## Run unit tests
ifdef FILTER
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpunit --testsuite unit --filter $(FILTER))
else
	$(call docker-compose-exec,$(DOCKER_SERVICE),bin/phpunit --testsuite unit)
endif
