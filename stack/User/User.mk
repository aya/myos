ENV_VARS                        += USER_DOMAIN USER_HOST user_domain
MAKECMDARGS                     += user-exec user-exec:% user-exec@% user-run user-run:% user-run@%
USER_DOMAIN                     ?= $(patsubst %,$(USER).%,$(DOMAIN))
USER_HOST                       ?= $(patsubst %,$(USER).%,$(HOST))$(USER_HOST_LB)
USER_HOST_RESU                  ?= $(patsubst %,$(RESU).%,$(USER_HOST))
USER_HOST_LB                    ?= $(if $(USER_LB),$(space)$(HOST)$(if $(HOST_LB),$(space)$(DOMAIN)),$(if $(HOST_LB),$(space)$(USER_DOMAIN)))
USER_PATH                       ?= $(USER_PATH_PREFIX)
USER_PATH_RESU                  ?= $(USER_PATH)$(RESU)/
USER_URIS                       ?= $(patsubst %,%/$(USER_PATH),$(USER_HOST))

ifneq ($(RESU),)
ifeq ($(USER_RESU_HOST),true)
USER_HOST                       := $(USER_HOST_RESU)
else ifeq ($(USER_RESU_PATH),true)
USER_PATH                       := $(USER_PATH_RESU)
endif
endif

# target start-stack-User: Fire ssh-add
.PHONY: start-stack-User
start-stack-User: ssh-add

# target user: Fire start-stack-User if DOCKER_RUN or fire start-stack-User
.PHONY: User user
User user: $(if $(DOCKER_RUN),stack-User-up,start-stack-User)

# target User-% user-%; Fire target stack-User-%
.PHONY: User-% user-%
User-% user-%: stack-User-%;
