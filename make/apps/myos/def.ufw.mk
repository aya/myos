CMDARGS                         += ufw ufw-docker

ifeq ($(SETUP_UFW),true)
define ufw
	$(call INFO,ufw,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(call app-exec,,ufw $(1))
endef
define ufw-docker
	$(call INFO,ufw-docker,$(1)$(comma))
	$(call app-bootstrap,ufw-docker)
	$(call app-exec,,ufw-docker $(1))
endef
endif
