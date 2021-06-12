# function install-config: copy CONFIG files to application config folder
define install-config
	$(call INFO,install-config,$(1)$(comma) $(2)$(comma) $(3)$(comma) $(4))
	$(eval path:=$(or $(1),$(APP)))
	$(eval file:=$(or $(2),$(DOCKER_SERVICE)))
	$(eval dest:=$(or $(3),config))
	$(eval env:=$(or $(4),$(ENV)))
	$(if $(wildcard $(dest)/$(file)),,$(if $(wildcard $(CONFIG)/$(env)/$(path)/$(file)),$(RUN) cp -a $(CONFIG)/$(env)/$(path)/$(file) $(dest)))
endef
