CMDARGS                         += ufw ufw-docker
UFW_UPDATE                      ?= $(or $(SERVICE),$(DOCKER_SERVICES))

ifeq ($(SETUP_UFW),true)

# function ufw: Exec command ufw with args 1
define ufw
	$(call INFO,ufw,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(call app-exec,,$(if $(DOCKER_RUN),,$(SUDO)) ufw $(1))
endef

# function ufw-docker: Exec command ufw-docker with args 1
define ufw-docker
	$(call INFO,ufw-docker,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(call app-exec,,$(if $(DOCKER_RUN),,$(SUDO)) ufw-docker $(1))
endef

endif
