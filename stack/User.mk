# target user: Fire ssh-add
.PHONY: User user
User user: bootstrap-docker docker-network-create $(if $(DOCKER_RUN),stack-User-up) ssh-add
