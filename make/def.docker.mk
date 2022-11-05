DOCKER_ENV_ARGS                 ?= $(docker_env_args)
DOCKER_EXEC_OPTIONS             ?=
DOCKER_GID                      ?= $(call gid,docker)
DOCKER_IMAGE                    ?= $(USER_DOCKER_IMAGE)
DOCKER_NAME                     ?= $(USER_DOCKER_NAME)
DOCKER_NETWORK                  ?= $(DOCKER_NETWORK_PRIVATE)
DOCKER_NETWORK_PRIVATE          ?= $(USER_COMPOSE_PROJECT_NAME)
DOCKER_NETWORK_PUBLIC           ?= $(NODE_COMPOSE_PROJECT_NAME)
# DOCKER_RUN: if empty, run system command, else run it in a docker
DOCKER_RUN                      ?= $(if $(filter-out false False FALSE,$(DOCKER)),$(DOCKER))
DOCKER_RUN_LABELS               ?= $(patsubst %,-l %,$(DOCKER_LABELS))
# DOCKER_RUN_OPTIONS: default options of `docker run` command
DOCKER_RUN_OPTIONS              += --rm --network $(DOCKER_NETWORK)
# DOCKER_RUN_VOLUME: options -v of `docker run` command to mount additionnal volumes
DOCKER_RUN_VOLUME               += -v /var/run/docker.sock:/var/run/docker.sock
DOCKER_RUN_WORKDIR              ?= -w $(PWD)
ENV_VARS                        += DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC NODE_COMPOSE_PROJECT_NAME NODE_COMPOSE_SERVICE_NAME NODE_DOCKER_REPOSITORY NODE_DOCKER_VOLUME USER_COMPOSE_PROJECT_NAME USER_COMPOSE_SERVICE_NAME USER_DOCKER_IMAGE USER_DOCKER_NAME USER_DOCKER_REPOSITORY USER_DOCKER_VOLUME
NODE_COMPOSE_PROJECT_NAME       ?= node
NODE_COMPOSE_SERVICE_NAME       ?= $(subst _,-,$(NODE_COMPOSE_PROJECT_NAME))
NODE_DOCKER_REPOSITORY          ?= $(subst -,/,$(subst _,/,$(NODE_COMPOSE_PROJECT_NAME)))
NODE_DOCKER_VOLUME              ?= $(NODE_COMPOSE_PROJECT_NAME)_myos
USER_COMPOSE_PROJECT_NAME       ?= $(USER)-$(ENV)
USER_COMPOSE_SERVICE_NAME       ?= $(subst _,-,$(USER_COMPOSE_PROJECT_NAME))
USER_DOCKER_IMAGE               ?= $(USER_DOCKER_REPOSITORY)/myos:${DOCKER_IMAGE_TAG}
USER_DOCKER_NAME                ?= $(USER_COMPOSE_PROJECT_NAME)-myos
USER_DOCKER_REPOSITORY          ?= $(subst -,/,$(subst _,/,$(USER_COMPOSE_PROJECT_NAME)))
USER_DOCKER_VOLUME              ?= $(USER_COMPOSE_PROJECT_NAME)_myos

# https://github.com/docker/libnetwork/pull/2348
ifeq ($(SYSTEM),Darwin)
DOCKER_HOST_IFACE               ?= $(shell docker run --rm -it --net=host alpine /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$5}' |awk '!seen[$$0]++' |head -1)
DOCKER_HOST_INET4               ?= $(shell docker run --rm -it --net=host alpine /sbin/ip -4 addr show $(DOCKER_HOST_IFACE) 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}' |head -1)
DOCKER_INTERNAL_DOCKER_GATEWAY  ?= $(shell docker run --rm -it alpine getent hosts gateway.docker.internal 2>/dev/null |awk '{print $$1}' |head -1)
DOCKER_INTERNAL_DOCKER_HOST     ?= $(shell docker run --rm -it alpine getent hosts host.docker.internal 2>/dev/null |awk '{print $$1}' |head -1)
else
DOCKER_HOST_IFACE               ?= $(shell /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$5}' |awk '!seen[$$0]++' |head -1)
DOCKER_HOST_INET4               ?= $(shell /sbin/ip -4 addr show $(DOCKER_HOST_IFACE) 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}' |head -1)
DOCKER_INTERNAL_DOCKER_GATEWAY  ?= $(shell /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$3}' |awk '!seen[$$0]++' |head -1)
DOCKER_INTERNAL_DOCKER_HOST     ?= $(shell /sbin/ip addr show docker0 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}' |head -1)
endif

ifeq ($(DRONE), true)
# When running docker command in drone, we are already in a docker (dind).
# Whe need to find the volume mounted in the current docker (runned by drone) to mount it in our docker command.
# If we do not mount the volume in our docker, we wont be able to access the files in this volume as the /drone/src directory would be empty.
DOCKER_RUN_VOLUME               += -v $$(docker inspect $$(basename $$(cat /proc/1/cpuset)) 2>/dev/null |awk 'BEGIN {FS=":"} $$0 ~ /"drone-[a-zA-Z0-9]*:\/drone"$$/ {gsub(/^[ \t\r\n]*"/,"",$$1); print $$1; exit}'):/drone $(if $(wildcard /root/.netrc),-v /root/.netrc:/root/.netrc)
else
DOCKER_RUN_VOLUME               += -v $(or $(APP_PARENT_DIR),$(APP_DIR),$(PWD)):$(or $(WORKSPACE_DIR),$(APP_PARENT_DIR),$(APP_DIR),$(PWD))
endif

ifneq ($(DOCKER_RUN),)

DOCKER_SSH_AUTH                 := -e SSH_AUTH_SOCK=/tmp/ssh-agent/socket -v $(USER_DOCKER_VOLUME):/tmp/ssh-agent

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
	$(RUN) docker exec $(DOCKER_ENV_ARGS) $(DOCKER_EXEC_OPTIONS) $(DOCKER_RUN_WORKDIR) $(DOCKER_NAME) $(or $(1),$(SHELL))
endef
endif
# function run: Run docker run with arg 1 and docker repository 2
## attention: arg 2 should end with slash or space
define run
	$(call INFO,run,$(1)$(comma) $(2))
	$(RUN) docker run $(DOCKER_ENV_ARGS) $(DOCKER_RUN_LABELS) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(DOCKER_SSH_AUTH) $(DOCKER_RUN_NAME) $(2)$(1)
endef

else

SHELL                           := /bin/bash
# function docker-run DOCKER=false: Run docker image 2 with arg 1
define docker-run
	$(call INFO,docker-run,$(1)$(comma) $(2))
	$(RUN) docker run $(DOCKER_ENV_ARGS) $(DOCKER_RUN_LABELS) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(DOCKER_RUN_NAME) $(or $(2),$(DOCKER_IMAGE)) $(1)
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
