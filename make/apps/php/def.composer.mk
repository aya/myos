COMPOSER_ARGS                   ?= --optimize-autoloader
COMPOSER_MEMORY_LIMIT           ?= -1
CONTEXT                         += COMPOSER_ARGS

ifeq ($(SYMFONY_ENV), prod)
COMPOSER_ARGS                   += --classmap-authoritative --prefer-dist --no-dev --no-interaction
endif
ifeq ($(DRONE), true)
COMPOSER_ARGS                   += --no-progress
endif

define composer
	$(call docker-compose-exec,$(DOCKER_SERVICE),COMPOSER_MEMORY_LIMIT=$(COMPOSER_MEMORY_LIMIT) SYMFONY_ENV=$(SYMFONY_ENV) composer $(1) $(COMPOSER_ARGS))
endef

define composer-require-vendor-binary
	$(eval vendor:=$(1))
	$(eval binary:=$(or $(2),$(lastword $(subst /, ,$(vendor)))))
	$(eval version:=$(or $(addprefix :,$(3)),$(shell awk '/'$(subst /,\\/,$(vendor))'/ {gsub("[\",]","",$$2); print ":"$$2}' composer.json 2>/dev/null)))
	$(eval DRYRUN_IGNORE := true)
	$(eval COMPOSER_REQUIRE := $(shell $(call docker-compose-exec,$(DOCKER_SERVICE),[ -f vendor/$(vendor)/$(binary) ] || echo true)))
	$(eval DRYRUN_IGNORE := false)
	$(if $(COMPOSER_REQUIRE),$(call docker-compose-exec,$(DOCKER_SERVICE),mkdir -p vendor/$(vendor) && cd /tmp && COMPOSER_MEMORY_LIMIT=$(COMPOSER_MEMORY_LIMIT) SYMFONY_ENV=$(SYMFONY_ENV) composer require "$(vendor)$(version)" --prefer-source --no-interaction --dev && cd - && ln -s /tmp/vendor/$(vendor)/$(binary) vendor/$(vendor)/$(binary)))
endef
