# target base: Fire ssh-add
.PHONY: base
base: $(if $(DOCKER_RUN),bootstrap-docker docker-network-create stack-base-up) ssh-add
