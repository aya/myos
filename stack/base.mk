# target base: Fire ssh-add
.PHONY: base
base: $(if $(DOCKER_RUN),install-bin-docker docker-network-create stack-base-up) ssh-add
