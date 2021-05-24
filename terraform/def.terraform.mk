CMDS                            += terraform

ifeq ($(DOCKER), true)

define terraform
    $(call run,hashicorp/terraform:light $(1))
endef

else

define terraform
	$(call run,terraform $(1))
endef

endif


