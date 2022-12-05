# target ufw: Call ufw ARGS
.PHONY: ufw
ufw:
	$(call ufw,$(ARGS))

# target ufw-delete: Fire ufw-update UFW_DELETE=true
.PHONY: ufw-delete
ufw-delete: UFW_DELETE := true
ufw-delete: ufw-update

# target ufw-docker: Call ufw-docker ARGS
.PHONY: ufw-docker
ufw-docker:
	$(call ufw-docker,$(ARGS))

# target ufw-docker: Call ufw and ufw-docker foreach service UFW_UPDATE
.PHONY: ufw-update
ufw-update: debug-UFW_UPDATE
	$(eval name := $(COMPOSE_PROJECT_NAME))
	$(foreach UPDATE,$(call UPPERCASE,$(UFW_UPDATE)), \
	  $(eval ufw_update := $($(if $(filter host,$(firstword $(subst /, ,$(STACK)))),HOST_)$(UPDATE)_UFW_UPDATE)) \
	  $(eval ufw_docker := $($(if $(filter host,$(firstword $(subst /, ,$(STACK)))),HOST_)$(UPDATE)_UFW_DOCKER)) \
	  $(foreach port,$(ufw_docker), \
	    $(call ufw-docker,$(if $(UFW_DELETE),delete) allow $(name)-$(call LOWERCASE,$(UPDATE)) $(port) ||:) \
	  ) \
	  $(foreach port,$(ufw_update), \
	    $(call ufw,$(if $(UFW_DELETE),delete) allow $(port)) \
	  ) \
	)

## ex: ufw-host-update will update ufw rules for stack host
.PHONY: stack-%
ufw-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
	  $(if $(filter ufw-$(command),$(MAKE_TARGETS)), \
	    $(call make,ufw-$(command) STACK="$(stack)") \
	  ) \
	)
