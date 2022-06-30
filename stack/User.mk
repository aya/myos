User                            ?= User/User

# target user: Fire user-agent
.PHONY: User user
User user: bootstrap-docker bootstrap-user $(if $(DOCKER_RUN),stack-User-up) user-agent

# target user-agent: Fire ssh-add
user-agent: ssh-add

# target User-% user-%; Fire target stack-User-%
User-% user-%: stack-User-%;
