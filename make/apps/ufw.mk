# target ufw: Call ufw ARGS

.PHONY: ufw
ufw:
	$(call ufw,$(ARGS))

ifeq ($(SETUP_UFW),true)

# target ufw-bootstrap: Eval ufw-docker app variables
ufw-bootstrap:
	$(eval APP_COMPOSE_FILE :=)
	$(eval DOCKER_COMPOSE_PROJECT_NAME := $(HOST_COMPOSE_PROJECT_NAME))
	$(eval DOCKER_SERVICE   := ufw-docker)
	$(eval DOCKER_STACK     :=)
	$(eval MYOS_STACK       :=)
	$(eval MYOS_STACK_FILE  :=)
	$(call app-bootstrap,$(lastword $(subst /, ,$(SETUP_UFW_REPOSITORY))))

# target ufw-build: Build ufw-docker docker
ufw-build:
	$(call app-build)

# target ufw-delete: Fire ufw-update UFW_DELETE=true
.PHONY: ufw-delete
ufw-delete: UFW_DELETE := true
ufw-delete: ufw-update

# target ufw-docker: Call ufw-docker ARGS
.PHONY: ufw-docker
ufw-docker:
	$(call ufw-docker,$(ARGS))

# target ufw-install: Download ufw-docker application
ufw-install:
	$(call app-install,$(SETUP_UFW_REPOSITORY))

# target ufw-up: Start ufw-docker docker
ufw-up: DOCKER_RUN_NETWORK   :=
ufw-up: DOCKER_RUN_OPTIONS   := --restart always -d --cap-add NET_ADMIN -v /etc/ufw:/etc/ufw $(if $(wildcard /etc/default/ufw),-v /etc/default/ufw:/etc/default/ufw) --network host
ufw-up:
	$(call app-up)

# target ufw-update: Call ufw and ufw-docker foreach service UFW_UPDATE
.PHONY: ufw-update
ufw-update: stack $(if $(HOST_STACK),setup-ufw) debug-UFW_UPDATE
	$(eval APP_COMPOSE_FILE :=)
	$(eval DOCKER_SERVICE   := ufw-docker)
	$(eval project_name     := $(COMPOSE_PROJECT_NAME))
	$(foreach UPDATE,$(call UPPERCASE,$(UFW_UPDATE)), \
	  $(eval ufw_update := $($(if $(HOST_STACK),HOST_)$(UPDATE)_UFW_UPDATE)) \
	  $(eval ufw_docker := $($(if $(HOST_STACK),HOST_)$(UPDATE)_UFW_DOCKER)) \
	  $(foreach port,$(ufw_docker), \
	    $(call ufw-docker,$(if $(UFW_DELETE),delete) allow $(project_name)-$(call LOWERCASE,$(UPDATE))$(if $(HOST_STACK),,-1) $(port) ||:) \
	  ) \
	  $(foreach port,$(ufw_update), \
	    $(call ufw,$(if $(UFW_DELETE),delete) allow $(port)) \
	  ) \
	)

# target ufw-%: Call ufw target for specific stack
## ex: ufw-host-update will update ufw rules for stack host
.PHONY: ufw-%
ufw-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
	  $(if $(filter ufw-$(command),$(MAKE_TARGETS)), \
	    $(call make,ufw-$(command) STACK="$(stack)") \
	  ) \
	)

endif
