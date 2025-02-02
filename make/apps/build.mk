##
# BUILD

# target build-env: Build .env file in docker SERVICE
# on local host
.PHONY: build-env
build-env: SERVICE ?= $(DOCKER_SERVICE)
build-env: APP_NAME := $(subst _,,$(subst -,,$(subst .,,$(call LOWERCASE,$(firstword $(subst /, ,$(STACK)))))))
build-env: bootstrap stack
	$(call docker-compose-exec-sh,$(SERVICE), \
		rm -f .env \
		&& make .env ENV=$(ENV) \
		&& printf 'BUILD=true\n' >> .env \
		&& $(foreach var,$(BUILD_ENV_VARS), \
			$(if $($(var)),sed -i '/^$(var)=/d' .env && printf "$(var)='$($(var))'\n" >> .env &&) \
		) true \
	)

# target build-init: Empty build directory
# on local host
.PHONY: build-init
build-init:
	$(RUN) rm -rf build && $(RUN) mkdir -p build

# target build-shared: Create SHARED folder in docker SERVICE
# on local host
.PHONY: build-shared
build-shared: SERVICE ?= $(DOCKER_SERVICE)
build-shared: APP_NAME := $(subst _,,$(subst -,,$(subst .,,$(call LOWERCASE,$(firstword $(subst /, ,$(STACK)))))))
build-shared: bootstrap stack
	$(call docker-compose-exec-sh,$(SERVICE), \
		mkdir -p /$(notdir $(SHARED)) \
		&& $(foreach folder,$(SHARED_FOLDERS), \
			rm -rf $(folder) \
			&& mkdir -p $(dir $(folder)) \
			&& ln -s /$(notdir $(SHARED))/$(notdir $(folder)) $(folder) \
			&& \
		) true \
	)
