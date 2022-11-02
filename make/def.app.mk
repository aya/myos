# function app-build: Call docker-build or docker-compose-build in app 1
define app-build
	$(call INFO,app-build,$(1)$(comma) $(2))
	$(eval dir := $(or $(1), $(APP_DIR)))
	$(eval DOCKER_BUILD_DIR := $(dir))
	$(if $(wildcard $(dir)/Dockerfile), \
	  $(call docker-build,$(dir),,''), \
	  $(call ERROR,Unable to find docker file $(dir)/Dockerfile) \
	)
endef

# function app-install: Run 'git clone url 1 dir 2' or Call app-update with url 1 dir 2
define app-install
	$(call INFO,app-install,$(1)$(comma) $(2))
	$(eval url := $(or $(1), $(APP_REPOSITORY_URL)))
	$(eval dir := $(or $(2), $(RELATIVE)$(lastword $(subst /, ,$(url)))))
	$(if $(wildcard $(dir)/.git), \
	  $(call app-update,$(url),$(dir)), \
	  $(RUN) git clone $(QUIET) $(url) $(dir) \
	)
endef

# function app-rebuild: Call app-build with DOCKER_BUILD_CACHE=false
define app-rebuild
	$(call INFO,app-rebuild,$(1)$(comma) $(2))
	$(eval DOCKER_BUILD_CACHE := false)
	$(call app-build,$(1),$(2))
endef

# function app-run: Call docker-run or docker-compose-run in app 1
define app-run
	$(call INFO,app-run,$(1)$(comma) $(2))
	$(eval image := $(or $(1), $(DOCKER_IMAGE)))
	$(eval args := $(or $(2), $(ARGS)))
	$(if $(shell docker images -q $(image) 2>/dev/null), \
	  $(call docker-run,$(args),$(image)), \
	  $(call ERROR,Unable to find docker image $(image)) \
	)
endef

# function app-up: Call docker-run in app 1
define app-up
	$(call INFO,app-up,$(1))
	$(eval image := $(or $(1), $(DOCKER_IMAGE)))
	$(if $(shell docker images -q $(image) 2>/dev/null), \
	  $(call docker-run,$(image)), \
	  $(call ERROR,Unable to find docker image $(image)) \
	)
endef

# function app-update: Run 'cd dir 1 && git pull' or Call app-install
define app-update
	$(call INFO,app-update,$(1)$(comma) $(2))
	$(eval url := $(or $(1), $(APP_REPOSITORY_URL)))
	$(eval dir := $(or $(2), $(APP_DIR)))
	$(if $(wildcard $(dir)/.git), \
	  $(RUN) sh -c 'cd $(dir) && git pull $(QUIET)', \
	  $(call app-install,$(url),$(dir)) \
	)
endef
