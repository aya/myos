MAKECMDARGS                     += ufw ufw-docker
UFW_UPDATE                      ?= $(or $(SERVICE),$(DOCKER_SERVICES))

# function ufw-cmd: Exec command ufw with args 1
## named -cmd: a macro named ufw-docker would be expanded as a stack group by
## docker-stack and reference itself
define ufw-cmd
	$(call INFO,ufw,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(eval DOCKER_COMPOSE_PROJECT_NAME := $(HOST_COMPOSE_PROJECT_NAME))
	$(call app-exec,,$(if $(DOCKER_RUN),,$(SUDO)) ufw $(1))
endef

# function ufw-docker-cmd: Exec command ufw-docker with args 1
define ufw-docker-cmd
	$(call INFO,ufw-docker,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(eval DOCKER_COMPOSE_PROJECT_NAME := $(HOST_COMPOSE_PROJECT_NAME))
	$(call app-exec,,$(if $(DOCKER_RUN),,$(SUDO)) ufw-docker $(1))
endef
