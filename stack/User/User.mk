CMDARGS                         += user-exec user-exec:% user-exec@% user-run user-run:% user-run@%
ENV_VARS                        += USER_DOMAIN user_domain
USER_DOMAIN                     ?= $(USER).$(DOMAIN)
User                            ?= $(patsubst stack/%,%,$(patsubst %.yml,%,$(wildcard stack/User/*.yml)))

# target start-stack-User: Fire ssh-add
.PHONY: start-stack-User
start-stack-User: ssh-add

# target user: Fire start-stack-User if DOCKER_RUN or fire start-stack-User
.PHONY: User user
User user: STACK := User
User user: $(if $(DOCKER_RUN),stack-User-up,start-stack-User)

# target User-% user-%; Fire target stack-User-%
.PHONY: User-% user-%
User-% user-%: STACK := User
User-% user-%: stack-User-%;
