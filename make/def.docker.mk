COMPOSE_VERSION                 ?= 1.24.1
COMPOSE_PROJECT_NAME_INFRA      ?= $(USER)_$(ENV)_infra
COMPOSE_PROJECT_NAME_INFRA_NODE ?= node_infra
DOCKER_EXEC_OPTIONS             ?=
DOCKER_IMAGE                    ?= $(DOCKER_IMAGE_CLI)
DOCKER_IMAGE_CLI                ?= $(DOCKER_REPOSITORY_INFRA)/cli
DOCKER_IMAGE_SSH                ?= $(DOCKER_REPOSITORY_INFRA)/ssh
DOCKER_NAME                     ?= $(DOCKER_NAME_CLI)
DOCKER_NAME_CLI                 ?= $(COMPOSE_PROJECT_NAME_INFRA)_cli
DOCKER_NAME_SSH                 ?= $(COMPOSE_PROJECT_NAME_INFRA)_ssh
DOCKER_NETWORK                  ?= $(DOCKER_NETWORK_PRIVATE)
DOCKER_NETWORK_PRIVATE          ?= $(ENV)
DOCKER_NETWORK_PUBLIC           ?= node
DOCKER_REPOSITORY_INFRA         ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_INFRA))
DOCKER_REPOSITORY_INFRA_NODE    ?= $(subst _,/,$(COMPOSE_PROJECT_NAME_INFRA_NODE))
# DOCKER_RUN_OPTIONS: default options to `docker run` command
DOCKER_RUN_OPTIONS              ?= --rm -it
# DOCKER_RUN_VOLUME: options to `docker run` command to mount additionnal volumes
DOCKER_RUN_VOLUME               ?= -v $$PWD:$$PWD
DOCKER_RUN_WORKDIR              ?= -w $$PWD
DOCKER_VOLUME_SSH               ?= $(COMPOSE_PROJECT_NAME_INFRA)_ssh
ENV_VARS                        += DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC DOCKER_REPOSITORY_INFRA DOCKER_REPOSITORY_INFRA_NODE DOCKER_VOLUME_SSH

ifeq ($(DRONE), true)
DOCKER_RUN_OPTIONS              := --rm --network $(DOCKER_NETWORK)
# When running docker command in drone, we are already in a docker (dind).
# Whe need to find the volume mounted in the current docker (runned by drone) to mount it in our docker command.
# If we do not mount the volume in our docker, we wont be able to access the files in this volume as the /drone/src directory would be empty.
DOCKER_RUN_VOLUME               := -v /var/run/docker.sock:/var/run/docker.sock -v $$(docker inspect $$(basename $$(cat /proc/1/cpuset)) 2>/dev/null |awk 'BEGIN {FS=":"} $$0 ~ /"drone-[a-zA-Z0-9]*:\/drone"$$/ {gsub(/^[ \t\r\n]*"/,"",$$1); print $$1; exit}'):/drone $(if $(wildcard /root/.netrc),-v /root/.netrc:/root/.netrc)
else
DOCKER_RUN_VOLUME               := -v /var/run/docker.sock:/var/run/docker.sock -v $(or $(MONOREPO_DIR),$(APP_DIR)):$(or $(WORKSPACE_DIR),$(MONOREPO_DIR),$(APP_DIR))
endif

ifeq ($(DOCKER), true)

DOCKER_SSH_AUTH                 := -e SSH_AUTH_SOCK=/tmp/ssh-agent/socket -v $(DOCKER_VOLUME_SSH):/tmp/ssh-agent

define docker-run
	$(call run,$(or $(1),$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)) $(2))
endef
ifeq ($(DRONE), true)
define exec
	$(call run,$(DOCKER_SSH_AUTH) $(DOCKER_IMAGE) sh -c '$(or $(1),$(SHELL))')
endef
else
define exec
	$(ECHO) docker exec $(ENV_ARGS) $(DOCKER_EXEC_OPTIONS) $(DOCKER_RUN_WORKDIR) $(DOCKER_NAME) sh -c '$(or $(1),$(SHELL))'
endef
endif
define run
	$(ECHO) docker run $(DOCKER_RUN_OPTIONS) $(patsubst %,--env-file %,$(ENV_FILE)) $(ENV_ARGS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(1)
endef

else

SHELL                           := /bin/bash
define docker-run
	$(ECHO) docker run $(DOCKER_RUN_OPTIONS) $(patsubst %,--env-file %,$(ENV_FILE)) $(foreach var,$(ENV_VARS),$(if $($(var)),-e $(var)='$($(var))')) $(shell printenv |awk -F '=' 'NR == FNR { if($$1 !~ /^(\#|$$)/) { A[$$1]; next } } ($$1 in A) {print "-e "$$0}' .env.dist - 2>/dev/null) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(or $(1),$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)) $(2)
endef
define exec
	$(call run,sh -c '$(or $(1),$(SHELL))')
endef
define run
	IFS=$$'\n'; $(ECHO) env $(ENV_ARGS) $$(cat $(ENV_FILE) 2>/dev/null |awk -F "=" '$$1 ~! /^\(#|$$\)/') $(1)
endef

endif

define docker-volume-copy
	$(eval from            := $(1))
	$(eval to              := $(2))
	$(ECHO) docker volume inspect $(from) >/dev/null
	$(ECHO) docker volume inspect $(to) >/dev/null 2>&1 || $(ECHO) docker volume create $(to) >/dev/null
	$(ECHO) docker run --rm -v $(from):/from -v $(to):/to alpine ash -c "cd /from; cp -a . /to"
endef
