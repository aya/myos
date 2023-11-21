DOCKER_ENV_ARGS                 ?= $(docker_env_args)
DOCKER_EXEC_OPTIONS             ?=
DOCKER_GID                      ?= $(call gid,docker)
DOCKER_IMAGE                    ?= $(USER_DOCKER_IMAGE)
DOCKER_MACHINE                  ?= $(shell docker run --rm alpine uname -m 2>/dev/null)
DOCKER_NAME                     ?= $(USER_DOCKER_NAME)
DOCKER_NETWORK                  ?= $(if $(USER_STACK),$(USER),$(DOCKER_NETWORK_PRIVATE))
DOCKER_NETWORK_PRIVATE          ?= $(USER)-$(ENV)
DOCKER_NETWORK_PUBLIC           ?= $(HOSTNAME)
# DOCKER_RUN: if empty, run system command, else run it in a docker
DOCKER_RUN                      ?= $(if $(filter-out false False FALSE,$(DOCKER)),$(DOCKER))
DOCKER_RUN_ENTRYPOINT           ?= $(patsubst %,--entrypoint=%,$(DOCKER_ENTRYPOINT))
DOCKER_RUN_LABELS               ?= $(patsubst %,-l %,$(DOCKER_LABELS))
DOCKER_RUN_NETWORK              += --network $(DOCKER_NETWORK)
DOCKER_RUN_OPTIONS              += --rm
DOCKER_RUN_VOLUME               ?= $(patsubst %,-v %,$(DOCKER_VOLUME))
DOCKER_RUN_WORKDIR              ?= $(if $(DOCKER_WORKDIR),-w $(DOCKER_WORKDIR))
DOCKER_SYSTEM                   ?= $(shell docker run --rm alpine uname -s 2>/dev/null)
DOCKER_VOLUME                   ?= /var/run/docker.sock:/var/run/docker.sock
DOCKER_WORKDIR                  ?= $(PWD)
ENV_VARS                        += DOCKER_MACHINE DOCKER_NETWORK DOCKER_NETWORK_PRIVATE DOCKER_NETWORK_PUBLIC DOCKER_SYSTEM HOST_COMPOSE_PROJECT_NAME HOST_COMPOSE_SERVICE_NAME HOST_DOCKER_REPOSITORY HOST_DOCKER_VOLUME HOST_GID HOST_UID USER_COMPOSE_PROJECT_NAME USER_COMPOSE_SERVICE_NAME USER_DOCKER_IMAGE USER_DOCKER_NAME USER_DOCKER_REPOSITORY USER_DOCKER_VOLUME
HOST_COMPOSE_PROJECT_NAME       ?= $(HOSTNAME)
HOST_COMPOSE_SERVICE_NAME       ?= $(subst _,-,$(HOST_COMPOSE_PROJECT_NAME))
HOST_DOCKER_REPOSITORY          ?= $(subst -,/,$(subst _,/,$(HOST_COMPOSE_PROJECT_NAME)))
HOST_DOCKER_VOLUME              ?= $(HOST_COMPOSE_PROJECT_NAME)
HOST_GID                        ?= 100
HOST_UID                        ?= 123
HOST_STACK                      ?= $(filter host,$(firstword $(subst /, ,$(STACK))))
MYOS_STACK                      ?= $(MYOS)/stack/myos
MYOS_STACK_FILE                 ?= $(wildcard $(MYOS_STACK)/networks.yml $(MYOS_STACK)/*.$(ENV).yml)
RESU_DOCKER_REPOSITORY          ?= $(subst -,/,$(USER_COMPOSE_PROJECT_NAME))
USER_COMPOSE_PROJECT_NAME       ?= $(subst .,-,$(RESU))
USER_COMPOSE_SERVICE_NAME       ?= $(USER_COMPOSE_PROJECT_NAME)
USER_DOCKER_IMAGE               ?= $(USER_DOCKER_REPOSITORY):${DOCKER_IMAGE_TAG}
USER_DOCKER_NAME                ?= $(USER_COMPOSE_PROJECT_NAME)
USER_DOCKER_REPOSITORY          ?= $(subst -,/,$(subst _,/,$(USER)))
USER_DOCKER_VOLUME              ?= $(USER_COMPOSE_PROJECT_NAME)
USER_STACK                      ?= $(filter User,$(firstword $(subst /, ,$(STACK))))

# https://github.com/docker/libnetwork/pull/2348
ifeq ($(SYSTEM),Darwin)
DOCKER_HOST_IFACE               ?= $(shell docker run --rm --net=host alpine /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$5}' |awk '!seen[$$0]++' |head -1)
DOCKER_HOST_INET4               ?= $(shell docker run --rm --net=host alpine /sbin/ip -4 addr show $(DOCKER_HOST_IFACE) 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}' |head -1)
DOCKER_INTERNAL_DOCKER_GATEWAY  ?= $(shell docker run --rm alpine nslookup -type=A -timeout=1 gateway.docker.internal 2>/dev/null |awk 'found && /^Address:/ {print $$2; found=0}; /^Name:\tgateway.docker.internal/ {found=1};' |head -1)
DOCKER_INTERNAL_DOCKER_HOST     ?= $(or $(shell docker run --rm alpine nslookup -type=A -timeout=1 host.docker.internal 2>/dev/null |awk 'found && /^Address:/ {print $$2; found=0}; /^Name:\thost.docker.internal/ {found=1};' |head -1),$(shell docker run --rm alpine /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$3}' |awk '!seen[$$0]++' |head -1))
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

# function docker-run: Run docker image 1 with arg 2
define docker-run
	$(call INFO,docker-run,$(1)$(comma) $(2))
	$(call run,$(or $(1),$(DOCKER_IMAGE)) $(2))
endef
ifeq ($(DRONE), true)
# function exec DRONE=true: Run DOCKER_IMAGE with arg 1
define exec
	$(call INFO,exec,$(1))
	$(call run,$(DOCKER_IMAGE) $(or $(1),$(SHELL)))
endef
else
# function exec: call docker-exec
define exec
	$(call INFO,exec,$(1))
	$(call docker-exec,$(1))
endef
endif
# function run: Run docker run with arg 1 and docker repository 2
## attention: arg 2 should end with slash or space
define run
	$(call INFO,run,$(1)$(comma) $(2))
	$(if $(DOCKER_RUN_NAME),
	  $(if $(call docker-running,^$(DOCKER_RUN_NAME)$$),
	    $(call ERROR,Found already running docker,$(DOCKER_RUN_NAME))
	  )
	)
	$(RUN) docker run $(DOCKER_ENV_ARGS) $(DOCKER_RUN_ENTRYPOINT) $(DOCKER_RUN_LABELS) $(DOCKER_RUN_NAME) $(DOCKER_RUN_NETWORK) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(DOCKER_SSH_AUTH) $(2)$(1)
endef

else

SHELL                           := /bin/bash
# function docker-run DOCKER=false: Run docker image 1 with arg 2
define docker-run
	$(call INFO,docker-run,$(1)$(comma) $(2))
	$(if $(DOCKER_RUN_NAME),
	  $(if $(call docker-running,^$(DOCKER_RUN_NAME)$$),
	    $(call ERROR,Found already running docker,$(DOCKER_RUN_NAME))
	  )
	)
	$(RUN) docker run $(DOCKER_ENV_ARGS) $(DOCKER_RUN_ENTRYPOINT) $(DOCKER_RUN_LABELS) $(DOCKER_RUN_NAME) $(DOCKER_RUN_NETWORK) $(DOCKER_RUN_OPTIONS) $(DOCKER_RUN_VOLUME) $(DOCKER_RUN_WORKDIR) $(or $(1),$(DOCKER_IMAGE)) $(2)
endef
# function exec DOCKER=false: Call env-exec with arg 1 or SHELL
define exec
	$(call INFO,exec,$(1))
	$(call env-exec,$(RUN) $(or $(1),$(SHELL)))
endef
# function run DOCKER=false: Call exec with arg 1
define run
	$(call INFO,run,$(1))
	$(call exec,$(1))
endef

endif

# function docker-attach: Attach docker 1 or DOCKER_NAME
define docker-attach
	$(call INFO,docker-attach,$(1)$(comma))
	$(eval attach          := $(or $(1),$(DOCKER_NAME)))
	$(if $(call docker-running,^$(attach)$),
	  $(RUN) docker attach $(attach)
	, $(call ERROR,Unable to find docker,$(attach))
	)
endef

# function docker-connect: Call docker-exec
define docker-connect
	$(call INFO,docker-connect,$(1)$(comma))
	$(call docker-exec,$(DOCKER_SHELL))
endef

# function docker-exec: Exec arg 1 in docker DOCKER_NAME
define docker-exec
	$(call INFO,docker-exec,$(1))
	$(if $(call docker-running,^$(DOCKER_NAME)$),
	  $(RUN) docker exec $(DOCKER_ENV_ARGS) $(DOCKER_EXEC_OPTIONS) $(DOCKER_RUN_WORKDIR) $(DOCKER_NAME) $(or $(1),$(SHELL))
	, $(call ERROR,Unable to find docker,$(DOCKER_NAME))
	)
endef

# function docker-logs: Print logs of docker 1 or DOCKER_NAME
define docker-logs
	$(call INFO,docker-logs,$(1))
	$(eval logs            := $(or $(1),$(DOCKER_NAME)))
	$(if $(call docker-running,^$(logs)$),
	  $(RUN) docker logs --follow --tail=100 $(logs)
	, $(call ERROR,Unable to find docker,$(logs))
	)
endef

# function docker-file: eval DOCKER_FILE in dir 1 or APP_DIR
define docker-file
	$(call INFO,docker-file,$(1)$(comma))
	$(eval dir                    := $(or $(1),$(APP_DIR)))
	$(eval DOCKER_FILE            := $(wildcard $(dir)/docker/*/Dockerfile $(dir)/*/Dockerfile $(dir)/Dockerfile))
	$(if $(DOCKER_FILE),
	, $(call ERROR,Unable to find a,Dockerfile,in dir,$(dir))
	)
endef

# function docker-running: Print running dockers matching DOCKER_NAME
define docker-running
$(shell docker ps -q $(patsubst %,-f name=%,$(or $(1), ^$(DOCKER_NAME)$$, ^$)) 2>/dev/null)
endef

# function docker-rm: Remove docker 1
define docker-rm
	$(call INFO,docker-rm,$(1)$(comma))
	$(eval rm              := $(or $(1),$(DOCKER_NAME)))
	$(if $(call docker-running,^$(rm)$),
		$(call WARNING,Removing running docker,$(rm))
	)
	$(RUN) docker rm -f $(rm)
endef

# function docker-volume-copy: Copy files from a docker volume to another
define docker-volume-copy
	$(call INFO,docker-volume-copy,$(1)$(comma) $(2))
	$(eval from            := $(1))
	$(eval to              := $(2))
	$(RUN) docker volume inspect $(from) >/dev/null
	$(RUN) docker volume inspect $(to) >/dev/null 2>&1 || $(RUN) docker volume create $(to) >/dev/null
	$(RUN) docker run --rm -v $(from):/from -v $(to):/to alpine ash -c "cd /from; cp -a . /to"
endef
