CMDS                            += user-exec user-exec:% user-exec@% user-run user-run:% user-run@%
User                            ?= User/User

# target bootstrap-stack-User: Fire docker-network-create
.PHONY: bootstrap-stack-User
bootstrap-stack-User: docker-network-create-$(DOCKER_NETWORK_PRIVATE)

# target start-stack-User: Fire ssh-add
.PHONY: start-stack-User
start-stack-User: ssh-add

# target user: Fire start-stack-User if DOCKER_RUN or fire start-stack-User
.PHONY: User user
User user: $(if $(DOCKER_RUN),stack-User-up,start-stack-User)

# target User-% user-%; Fire target stack-User-%
.PHONY: User-% user-%
User-% user-%: stack-User-%;
