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
ufw-update:
	$(foreach update,$(UFW_UPDATE), \
	  $(foreach port,$(UFW_DOCKER_$(DOCKER_COMPOSE_PROJECT_NAME)-$(update)), \
	    $(call ufw-docker,$(if $(UFW_DELETE),delete) allow $(DOCKER_COMPOSE_PROJECT_NAME)-$(update) $(port)) \
	  ) \
	  $(foreach port,$(UFW_UPDATE_$(DOCKER_COMPOSE_PROJECT_NAME)-$(update)), \
	    $(call ufw,$(if $(UFW_DELETE),delete) allow $(port)) \
	  ) \
	)

## ex: ufw-node-up will update ufw rules for stack node
.PHONY: stack-%
ufw-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
	  $(if $(filter ufw-$(command),$(MAKE_TARGETS)), \
	    $(call make,ufw-$(command) STACK="$(stack)") \
	  ) \
	)
