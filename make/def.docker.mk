COMPOSE_VERSION                 ?= 1.24.1
COMPOSE_PROJECT_NAME_MYOS       ?= $(USER)_$(ENV)_myos
COMPOSE_PROJECT_NAME_NODE       ?= node
DOCKER_ENV                      ?= $(env.docker)
DOCKER_EXEC_OPTIONS             ?=
DOCKER_IMAGE                    ?= $(DOCKER_IMAGE_CLI)
DOCKER_IMAGE_CLI                ?= $(DOCKER_REPOSITORY_MYOS)/cli
DOCKER_IMAGE_SSH                ?= $(DOCKER_REPOSITORY_MYOS)/ssh
DOCKER_NAME                     ?= $(DOCKER_NAME_CLI)
DOCKER_NAME_CLI                 ?= $(COMPOSE_PROJECT_NAME_MYOS)_cli
DOCKER_NAME_SSH                 ?= $(COMPOSE_PROJECT_NAME_MYOS)_ssh
DOCKER_NETWORK                  ?= $(DOCKER_NETWORK_PRIVATE)
DOCKER_NETWORK_PRIVATE          ?= $(ENV)
DOCKER_NETWORK_PUBLIC           ?= node
DOCKER_REPOSITORY_MYOS          ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_MYOS))
DOCKER_REPOSITORY_NODE          ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_NODE))
# DOCKER_RUN_OPTIONS: default options to `docker run` command
DOCKER_RUN_OPTIONS              ?= --rm -it
# DOCKER_RUN_VOLUME: options to `docker run` command to mount additionnal volumes
DOCKER_RUN_VOLUME               ?= -v $$PWD:$$PWD
DOCKER_RUN_WORKDIR              ?= -w $$PWD
DOCKER_VOLUME_SSH               ?= $(COMPOSE_PROJECT_NAME_MYOS)_ssh
ENV_VARS                        += DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC DOCKER_REPOSITORY_MYOS DOCKER_REPOSITORY_NODE DOCKER_VOLUME_SSH

ifeq ($(DRONE), true)
DOCKER_RUN_OPTIONS              := --rm --network $(DOCKER_NETWORK)
# When running docker command in drone, we are already in a docker (dind).
# Whe need to find the volume mounted in the current docker (runned by drone) to mount it in our docker command.
# If we do not mount the volume in our docker, we wont be able to access the files in this volume as the /drone/src directory would be empty.
DOCKER_RUN_VOLUME               := -v /var/run/docker.sock:/var/run/docker.sock -v $$(docker inspect $$(basename $$(cat /proc/1/cpuset)) 2>/dev/null |awk 'BEGIN {FS=":"} $$0 ~ /"drone-[a-zA-Z0-9]*:\/drone"$$/ {gsub(/^[ \t\r\n]*"/,"",$$1); print $$1; exit}'):/drone $(if $(wildcard /root/.netrc),-v /root/.netrc:/root/.netrc)
else
DOCKER_RUN_VOLUME               := -v /var/run/docker.sock:/var/run/docker.sock -v $(or $(MONOREPO_DIR),$(APP_DIR)):$(or $(WORKSPACE_DIR),$(MONOREPO_DIR),$(APP_DIR))
endif

# function env-run: Call env-exec with arg 1 in a subshell
define env-run
	$(call env-exec,sh -c '$(or $(1),$(SHELL))')
endef
# function env-exec: Exec arg 1 in a new env
define env-exec
	IFS=$$'\n'; env $(env_reset) $(env) $(1)
endef

ifeq ($(DOCKER), true)

DOCKER_SSH_AUTH                 := -e SSH_AUTH_SOCK=/tmp/ssh-agent/socket -v $(DOCKER_VOLUME_SSH):/tmp/ssh-agent

# function docker-run: Run new DOCKER_IMAGE:DOCKER_IMAGE_TAG docker with arg 2
define docker-run
	$(call run,$(or $(1),$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)) $(2))
endef
ifeq ($(DRONE), true)
# function exec: Run new DOCKER_IMAGE docker with arg 1
define exec
	$(call run,$(DOCKER_IMAGE) sh -c '$(or $(1),$(SHELL))')
endef
else
# function exec: Exec arg 1 in docker DOCKER_NAME
define exec
	$(ECHO) docker exec $(DOCKER_ENV) $(DOCKER_EXEC_OPTIONS) $(DOCKER_RUN_WORKDIR) $(DOCKER_NAME) sh -c '$(or $(1),$(SHELL))'
endef
endif
# function run: Pass arg 1 to docker run
define run
	$(ECHO) docker run $(DOCKER_ENV) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(DOCKER_SSH_AUTH) $(1)
endef

else

SHELL                           := /bin/bash
# function docker-run: Run new DOCKER_IMAGE:DOCKER_IMAGE_TAG docker with arg 2
define docker-run
	$(ECHO) docker run $(DOCKER_RUN_OPTIONS) $(DOCKER_ENV) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(or $(1),$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)) $(2)
endef
# function exec: Call env-exec with arg 1 or SHELL
define exec
	$(call env-exec,$(or $(1),$(SHELL)))
endef
# function run: Call env-run with arg 1
define run
	$(call env-run,$(1))
endef

endif

# function docker-volume-copy: Copy files from a docker volume to another
define docker-volume-copy
	$(eval from            := $(1))
	$(eval to              := $(2))
	$(ECHO) docker volume inspect $(from) >/dev/null
	$(ECHO) docker volume inspect $(to) >/dev/null 2>&1 || $(ECHO) docker volume create $(to) >/dev/null
	$(ECHO) docker run --rm -v $(from):/from -v $(to):/to alpine ash -c "cd /from; cp -a . /to"
endef
