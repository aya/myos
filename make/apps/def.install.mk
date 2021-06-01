# function install-parameters: copy PARAMETERS files to application config folder
define install-parameters
        $(eval path:=$(or $(1),$(APP)))
        $(eval file:=$(or $(2),$(DOCKER_SERVICE)))
        $(eval dest:=$(or $(3),config))
        $(eval env:=$(or $(4),$(ENV)))
        $(if $(wildcard $(dest)/$(file)),,$(if $(wildcard $(PARAMETERS)/$(env)/$(path)/$(file)),$(ECHO) cp -a $(PARAMETERS)/$(env)/$(path)/$(file) $(dest)))
endef
