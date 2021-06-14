# target base: Fire docker-network-create stack-base-up base-ssh-add
.PHONY: base
base: docker-network-create $(if $(DOCKER_RUN),stack-base-up) ssh-add
