COMPOSE_PROJECT_NAME_MYOS       ?= $(USER_ENV)_myos
COMPOSE_PROJECT_NAME_NODE       ?= node
COMPOSE_VERSION                 ?= 1.29.2
DOCKER_ENV                      ?= $(env.docker)
DOCKER_EXEC_OPTIONS             ?=
DOCKER_IMAGE                    ?= $(DOCKER_IMAGE_CLI)
DOCKER_IMAGE_CLI                ?= $(DOCKER_REPOSITORY_MYOS)/cli
DOCKER_IMAGE_SSH                ?= $(DOCKER_REPOSITORY_MYOS)/ssh
DOCKER_NAME                     ?= $(DOCKER_NAME_CLI)
DOCKER_NAME_CLI                 ?= $(COMPOSE_PROJECT_NAME_MYOS)_cli
DOCKER_NAME_SSH                 ?= $(COMPOSE_PROJECT_NAME_MYOS)_ssh
DOCKER_NETWORK                  ?= $(DOCKER_NETWORK_PRIVATE)
DOCKER_NETWORK_PRIVATE          ?= $(USER_ENV)
DOCKER_NETWORK_PUBLIC           ?= node
DOCKER_REPOSITORY_MYOS          ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_MYOS))
DOCKER_REPOSITORY_NODE          ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_NODE))
DOCKER_RUN                      ?= $(filter true,$(DOCKER))
# DOCKER_RUN_OPTIONS: default options of `docker run` command
DOCKER_RUN_OPTIONS              += --rm -it
# DOCKER_RUN_VOLUME: options -v of `docker run` command to mount additionnal volumes
DOCKER_RUN_VOLUME               += -v /var/run/docker.sock:/var/run/docker.sock
DOCKER_RUN_WORKDIR              ?= -w $(PWD)
DOCKER_VOLUME_SSH               ?= $(COMPOSE_PROJECT_NAME_MYOS)_ssh
ENV_VARS                        += DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC DOCKER_REPOSITORY_MYOS DOCKER_REPOSITORY_NODE DOCKER_VOLUME_SSH

ifeq ($(DRONE), true)
DOCKER_RUN_OPTIONS              := --rm --network $(DOCKER_NETWORK)
# When running docker command in drone, we are already in a docker (dind).
# Whe need to find the volume mounted in the current docker (runned by drone) to mount it in our docker command.
# If we do not mount the volume in our docker, we wont be able to access the files in this volume as the /drone/src directory would be empty.
DOCKER_RUN_VOLUME               += -v $$(docker inspect $$(basename $$(cat /proc/1/cpuset)) 2>/dev/null |awk 'BEGIN {FS=":"} $$0 ~ /"drone-[a-zA-Z0-9]*:\/drone"$$/ {gsub(/^[ \t\r\n]*"/,"",$$1); print $$1; exit}'):/drone $(if $(wildcard /root/.netrc),-v /root/.netrc:/root/.netrc)
else
DOCKER_RUN_VOLUME               += -v $(or $(APP_PARENT_DIR),$(APP_DIR),$(PWD)):$(or $(WORKSPACE_DIR),$(APP_PARENT_DIR),$(APP_DIR),$(PWD))
endif

ifeq ($(DOCKER), true)

DOCKER_SSH_AUTH                 := -e SSH_AUTH_SOCK=/tmp/ssh-agent/socket -v $(DOCKER_VOLUME_SSH):/tmp/ssh-agent

# function docker-run: Run docker image 2 with arg 1
define docker-run
	$(call INFO,docker-run,$(1)$(comma) $(2))
	$(call run,$(or $(2),$(DOCKER_IMAGE)) $(1))
endef
ifeq ($(DRONE), true)
# function exec DRONE=true: Run DOCKER_IMAGE with arg 1
define exec
	$(call INFO,exec,$(1))
	$(call run,$(DOCKER_IMAGE) $(or $(1),$(SHELL)))
endef
else
# function exec: Exec arg 1 in docker DOCKER_NAME
define exec
	$(call INFO,exec,$(1))
	$(RUN) docker exec $(DOCKER_ENV) $(DOCKER_EXEC_OPTIONS) $(DOCKER_RUN_WORKDIR) $(DOCKER_NAME) $(or $(1),$(SHELL))
endef
endif
# function run: Run docker run with arg 1 and docker repository 2
## attention: arg 2 should end with slash or space
define run
	$(call INFO,run,$(1)$(comma) $(2))
	$(RUN) docker run $(DOCKER_ENV) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(DOCKER_SSH_AUTH) $(2)$(1)
endef

else

SHELL                           := /bin/bash
# function docker-run DOCKER=false: Run docker image 2 with arg 1
define docker-run
	$(call INFO,docker-run,$(1)$(comma) $(2))
	$(RUN) docker run $(DOCKER_ENV) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(or $(2),$(DOCKER_IMAGE)) $(1)
endef
# function exec DOCKER=false: Call env-exec with arg 1 or SHELL
define exec
	$(call INFO,exec,$(1))
	$(call env-exec,$(or $(1),$(SHELL)))
endef
# function run DOCKER=false: Call env-run with arg 1
define run
	$(call INFO,run,$(1))
	$(call env-run,$(1))
endef

endif

# function docker-volume-copy: Copy files from a docker volume to another
define docker-volume-copy
	$(call INFO,docker-volume-copy,$(1)$(comma) $(2))
	$(eval from            := $(1))
	$(eval to              := $(2))
	$(RUN) docker volume inspect $(from) >/dev/null
	$(RUN) docker volume inspect $(to) >/dev/null 2>&1 || $(RUN) docker volume create $(to) >/dev/null
	$(RUN) docker run --rm -v $(from):/from -v $(to):/to alpine ash -c "cd /from; cp -a . /to"
endef

# function env-run: Call env-exec with arg 1
define env-run
	$(call INFO,env-run,$(1))
	$(call env-exec,$(or $(1),$(SHELL)))
endef

# function env-exec: Exec arg 1 with custom env
define env-exec
	$(call INFO,env-exec,$(1))
	IFS=$$'\n'; env $(env_reset) $(env) $(1)
endef
