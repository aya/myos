##
# TEST

.PHONY: test-assets
test-assets: bootstrap
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn test)

## Run functional tests (make test-func TEST="S01-U1-find-product")
.PHONY: test-func-js
test-func-js: bootstrap ## Run functional tests (js)
ifdef TEST
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn test:func -- --test tests/Functional/specs/$(TEST).js --env $(TESTENV))
else ifdef TESTSUITE
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn test:func -- --tag $(TESTSUITE) --env $(TESTENV))
else
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn test:func -- --env $(TESTENV))
endif
