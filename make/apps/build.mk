##
# BUILD

# target build-env: Build .env file in docker SERVICE to deploy
# on local host
.PHONY: build-env
build-env: SERVICE ?= $(DOCKER_SERVICE)
build-env: bootstrap
	$(call docker-compose-exec,$(SERVICE), \
		rm -f .env \
		&& make .env ENV=$(ENV) \
		&& echo BUILD=true >> .env \
		&& echo BUILD_DATE='"\'"'$(shell date "+%d/%m/%Y %H:%M:%S %z" 2>/dev/null)'"\'"' >> .env \
		&& echo BUILD_STATUS='"\'"'$(shell git status -uno --porcelain 2>/dev/null)'"\'"' >> .env \
		&& echo DOCKER=false >> .env \
		&& $(foreach var,$(BUILD_ENV_VARS), \
			$(if $($(var)),sed -i '/^$(var)=/d' .env && echo $(var)='$($(var))' >> .env &&) \
		) true \
	)

# target build-init: Empty build directory
# on local host
.PHONY: build-init
build-init:
	$(ECHO) rm -rf build && $(ECHO) mkdir -p build

# target build-shared: Create SHARED folder in docker SERVICE to deploy
# on local host
.PHONY: build-shared
build-shared: SERVICE ?= $(DOCKER_SERVICE)
build-shared: bootstrap
	$(call docker-compose-exec,$(SERVICE), \
		mkdir -p /$(notdir $(SHARED)) \
		&& $(foreach folder,$(SHARED_FOLDERS), \
			rm -rf $(folder) \
			&& mkdir -p $(dir $(folder)) \
			&& ln -s /$(notdir $(SHARED))/$(notdir $(folder)) $(folder) \
			&& \
		) true \
	)
