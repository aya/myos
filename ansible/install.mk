##
# INSTALL

# target install-ansible; Install ansible on local host
.PHONY: install-ansible
install-ansible:
	$(if $(shell type -p ansible),,$(RUN) $(INSTALL) ansible)

