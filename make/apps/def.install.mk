# function install-config: copy CONFIG files to application config folder
define install-config
        $(eval path:=$(or $(1),$(APP)))
        $(eval file:=$(or $(2),$(DOCKER_SERVICE)))
        $(eval dest:=$(or $(3),config))
        $(eval env:=$(or $(4),$(ENV)))
        $(if $(wildcard $(dest)/$(file)),,$(if $(wildcard $(CONFIG)/$(env)/$(path)/$(file)),$(ECHO) cp -a $(CONFIG)/$(env)/$(path)/$(file) $(dest)))
endef
