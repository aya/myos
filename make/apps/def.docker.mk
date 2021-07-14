CMDS                            += docker-compose-exec docker-run docker-run-%
COMPOSE_FILE                    ?= $(wildcard docker/docker-compose.yml $(foreach file,$(patsubst docker/docker-compose.%,%,$(basename $(wildcard docker/docker-compose.*.yml))),$(if $(filter true,$(COMPOSE_FILE_$(file)) $(COMPOSE_FILE_$(call UPPERCASE,$(file)))),docker/docker-compose.$(file).yml)))
COMPOSE_FILE_$(ENV)             ?= true
COMPOSE_FILE_DEBUG              ?= $(if $(DEBUG),true)
COMPOSE_FILE_NFS                ?= $(MOUNT_NFS)
COMPOSE_FILE_SSH                ?= true
ifneq ($(SUBREPO),)
COMPOSE_FILE_SUBREPO            ?= true
else
COMPOSE_FILE_APP                ?= true
endif
COMPOSE_IGNORE_ORPHANS          ?= false
COMPOSE_PROJECT_NAME            ?= $(APP_ENV)$(subst /,,$(subst -,,$(APP_PATH)))
COMPOSE_SERVICE_NAME            ?= $(subst _,-,$(COMPOSE_PROJECT_NAME))
CONTEXT                         += COMPOSE_FILE DOCKER_REPOSITORY
CONTEXT_DEBUG                   += DOCKER_BUILD_TARGET DOCKER_IMAGE_TAG DOCKER_REGISTRY DOCKER_SERVICE DOCKER_SERVICES
DOCKER_AUTHOR                   ?= $(DOCKER_AUTHOR_NAME) <$(DOCKER_AUTHOR_EMAIL)>
DOCKER_AUTHOR_EMAIL             ?= $(subst +git,+docker,$(GIT_AUTHOR_EMAIL))
DOCKER_AUTHOR_NAME              ?= $(GIT_AUTHOR_NAME)
DOCKER_BUILD_ARGS               ?= $(if $(filter true,$(DOCKER_BUILD_NO_CACHE)),--pull --no-cache) $(foreach var,$(DOCKER_BUILD_VARS),$(if $($(var)),--build-arg $(var)='$($(var))'))
DOCKER_BUILD_CACHE              ?= true
DOCKER_BUILD_LABEL              ?= $(foreach var,$(filter $(BUILD_LABEL_VARS),$(MAKE_FILE_VARS)),$(if $($(var)),--label $(var)='$($(var))'))
DOCKER_BUILD_NO_CACHE           ?= false
DOCKER_BUILD_TARGET             ?= $(if $(filter $(ENV),$(DOCKER_BUILD_TARGETS)),$(ENV),$(DOCKER_BUILD_TARGET_DEFAULT))
DOCKER_BUILD_TARGET_DEFAULT     ?= master
DOCKER_BUILD_TARGETS            ?= $(ENV_DEPLOY)
DOCKER_BUILD_VARS               ?= APP BRANCH DOCKER_GID DOCKER_REPOSITORY GID GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PRIVATE_IP_RANGE SSH_PUBLIC_HOST_KEYS SSH_REMOTE_HOSTS UID USER VERSION
DOCKER_COMPOSE_DOWN_OPTIONS     ?=
DOCKER_COMPOSE_UP_OPTIONS       ?= -d
DOCKER_IMAGE_TAG                ?= $(if $(filter $(ENV),$(ENV_DEPLOY)),$(VERSION),$(if $(DRONE_BUILD_NUMBER),$(DRONE_BUILD_NUMBER),latest))
DOCKER_IMAGES                   ?= $(patsubst %/,%,$(patsubst docker/%,%,$(dir $(wildcard docker/*/Dockerfile))))
DOCKER_PLUGIN                   ?= rexray/s3fs:latest
DOCKER_PLUGIN_ARGS              ?= $(foreach var,$(DOCKER_PLUGIN_VARS),$(if $(DOCKER_PLUGIN_$(var)),$(var)='$(DOCKER_PLUGIN_$(var))'))
DOCKER_PLUGIN_OPTIONS           ?= --grant-all-permissions
DOCKER_PLUGIN_S3FS_ACCESSKEY    ?= $(AWS_ACCESS_KEY_ID)
DOCKER_PLUGIN_S3FS_OPTIONS      ?= allow_other,nonempty,use_path_request_style,url=https://s3-eu-west-1.amazonaws.com
DOCKER_PLUGIN_S3FS_SECRETKEY    ?= $(AWS_SECRET_ACCESS_KEY)
DOCKER_PLUGIN_S3FS_REGION       ?= eu-west-1
DOCKER_PLUGIN_VARS              ?= S3FS_ACCESSKEY S3FS_OPTIONS S3FS_SECRETKEY S3FS_REGION
DOCKER_REGISTRY                 ?= my.os
DOCKER_REGISTRY_USERNAME        ?= $(USER)
DOCKER_REGISTRY_REPOSITORY      ?= $(addsuffix /,$(DOCKER_REGISTRY))$(subst $(USER),$(DOCKER_REGISTRY_USERNAME),$(DOCKER_REPOSITORY))
DOCKER_REPOSITORY               ?= $(subst _,/,$(COMPOSE_PROJECT_NAME))
DOCKER_SERVICE                  ?= $(lastword $(DOCKER_SERVICES))
DOCKER_SERVICES                 ?= $(eval IGNORE_DRYRUN := true)$(shell $(call docker-compose,--log-level critical config --services))$(eval IGNORE_DRYRUN := false)
DOCKER_SHELL                    ?= $(SHELL)
ENV_VARS                        += COMPOSE_PROJECT_NAME COMPOSE_SERVICE_NAME DOCKER_BUILD_TARGET DOCKER_IMAGE_TAG DOCKER_REGISTRY DOCKER_REPOSITORY DOCKER_SHELL

ifneq ($(DOCKER_RUN),)
DOCKER_COMPOSE                  ?= docker/compose:$(COMPOSE_VERSION)
else
DOCKER_COMPOSE                  ?= $(or $(shell docker compose >/dev/null 2>&1 && printf 'docker compose\n'),docker-compose)
endif

ifeq ($(DRONE), true)
APP_PATH_PREFIX                 := $(DRONE_BUILD_NUMBER)
DOCKER_BUILD_CACHE              := false
DOCKER_COMPOSE_DOWN_OPTIONS     := --rmi all -v
DOCKER_COMPOSE_UP_OPTIONS       := -d --build
endif

# https://github.com/docker/libnetwork/pull/2348
ifeq ($(OPERATING_SYSTEM),Darwin)
DOCKER_HOST_IFACE               ?= $(shell docker run --rm -it --net=host alpine /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$5}' |awk '!seen[$$0]++' |head -1)
DOCKER_HOST_INET                ?= $(shell docker run --rm -it --net=host alpine /sbin/ip -4 addr show $(DOCKER_HOST_IFACE) 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}')
DOCKER_INTERNAL_DOCKER_GATEWAY  ?= $(shell docker run --rm -it alpine getent hosts gateway.docker.internal 2>/dev/null |awk '{print $$1}' |head -1)
DOCKER_INTERNAL_DOCKER_HOST     ?= $(shell docker run --rm -it alpine getent hosts host.docker.internal 2>/dev/null |awk '{print $$1}' |head -1)
else
DOCKER_HOST_IFACE               ?= $(shell /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$5}' |awk '!seen[$$0]++' |head -1)
DOCKER_HOST_INET                ?= $(shell /sbin/ip -4 addr show $(DOCKER_HOST_IFACE) 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}')
DOCKER_INTERNAL_DOCKER_GATEWAY  ?= $(shell /sbin/ip -4 route list match 0/0 2>/dev/null |awk '{print $$3}' |awk '!seen[$$0]++' |head -1)
DOCKER_INTERNAL_DOCKER_HOST     ?= $(shell /sbin/ip addr show docker0 2>/dev/null |awk '$$1 == "inet" {sub(/\/.*/,"",$$2); print $$2}')
endif

# function docker-compose: Run docker-compose with arg 1
define docker-compose
	$(call INFO,docker-compose,$(1))
	$(call run,$(DOCKER_COMPOSE) $(patsubst %,-f %,$(COMPOSE_FILE)) -p $(COMPOSE_PROJECT_NAME) $(1))
endef
# function docker-compose-exec: Run docker-compose-exec with arg 2 in service 1
define docker-compose-exec
	$(call INFO,docker-compose-exec,$(1)$(comma) $(2))
	$(call run,$(DOCKER_COMPOSE) $(patsubst %,-f %,$(COMPOSE_FILE)) -p $(COMPOSE_PROJECT_NAME) exec -T $(1) sh -c '$(2)')
endef

# function docker-build: Build docker image
define docker-build
	$(call INFO,docker-build,$(1)$(comma) $(2)$(comma) $(3))
	$(eval path            := $(patsubst %/,%,$(1)))
	$(eval tag             := $(or $(2),$(DOCKER_REPOSITORY)/$(lastword $(subst /, ,$(path))):$(DOCKER_IMAGE_TAG)))
	$(eval target          := $(subst ",,$(subst ',,$(or $(3),$(DOCKER_BUILD_TARGET)))))
	$(eval image_id        := $(shell docker images -q $(tag) 2>/dev/null))
	$(eval build_image     := $(or $(filter false,$(DOCKER_BUILD_CACHE)),$(if $(image_id),,true)))
	$(if $(build_image),$(RUN) docker build $(DOCKER_BUILD_ARGS) --build-arg DOCKER_BUILD_DIR="$(path)" $(DOCKER_BUILD_LABEL) --tag $(tag) $(if $(target),--target $(target)) -f $(path)/Dockerfile .,$(call INFO,docker image $(tag) has id $(image_id)))
endef
# function docker-commit: Commit docker image
define docker-commit
	$(call INFO,docker-commit,$(1)$(comma) $(2)$(comma) $(3)$(comma) $(4))
	$(eval service         := $(or $(1),$(DOCKER_SERVICE)))
	$(eval container       := $(or $(2),$(firstword $(shell $(call docker-compose,--log-level critical ps -q $(service))))))
	$(eval repository      := $(or $(3),$(DOCKER_REPOSITORY)/$(service)))
	$(eval tag             := $(or $(4),$(DOCKER_IMAGE_TAG)))
	$(RUN) docker commit $(container) $(repository):$(tag)
endef
# function docker-push: Push docker image
define docker-push
	$(call INFO,docker-push,$(1)$(comma) $(2)$(comma) $(3))
	$(eval service         := $(or $(1),$(DOCKER_SERVICE)))
	$(eval name            := $(or $(2),$(DOCKER_REGISTRY_REPOSITORY)/$(service)))
	$(eval tag             := $(or $(3),$(DOCKER_IMAGE_TAG)))
	$(RUN) docker push $(name):$(tag)
endef
# function docker-stack: Call itself recursively for each stack to expand stacks
# docker-stack: if 1st arg is a variable and can be expand to values, it calls
# itself again, once whith each value, else calls docker-stack-update function
	# 1st arg: stacks, extract it from stack_names:stack_versions
	# 2nd arg: versions, extract it from stack_names:stack_versions or 2nd arg
define docker-stack
	$(call INFO,docker-stack,$(1)$(comma) $(2))
	$(eval stacks          := $(firstword $(subst :, ,$(1))))
	$(eval versions        := $(or $(if $(findstring :,$(1)),$(lastword $(subst :, ,$(1)))),$(2)))
	$(if $($(stacks)),$(foreach substack,$($(stacks)),$(call docker-stack,$(substack),$(if $(findstring :,$(1)),$(versions)))),$(call docker-stack-update,$(stacks),$(versions)))
endef
# function docker-stack-update: Update COMPOSE_FILE with .yml files of the stack
# docker-stack-update: adds all .yml files of the stack to COMPOSE_FILE variable
# and update the .env file with the .env.dist files of the stack
	# 1st arg: stack_path/stack_name:stack_version
	# stack: get stack_name:stack_version from 1st arg
	# name: get stack name from $(stack)
	# 2nd arg: stack version, or extract it from $(stack), default to latest
	# 3rd arg: stack path, or extract it from $(stack), default to stack/$(name)
	# add $(path)/$(name).yml, $(path)/$(name).$(ENV).yml and $(path)/$(name).$(version).yml to COMPOSE_FILE variable
	# if $(path)/.env.dist file exists, update .env file
define docker-stack-update
	$(call INFO,docker-stack-update,$(1)$(comma) $(2)$(comma) $(3))
	$(eval stack           := $(patsubst %.yml,%,$(notdir $(1))))
	$(eval name            := $(firstword $(subst :, ,$(stack))))
	$(eval version         := $(or $(2),$(if $(findstring :,$(stack)),$(lastword $(subst :, ,$(stack))),latest)))
	$(eval path            := $(patsubst %/,%,$(or $(3),$(if $(findstring /,$(1)),$(if $(wildcard stack/$(1) stack/$(1).yml),stack/$(if $(findstring .yml,$(1)),$(dir $(1)),$(if $(wildcard stack/$(1).yml),$(dir $(1)),$(1))),$(dir $(1)))),stack/$(name))))
	$(eval COMPOSE_FILE    += $(wildcard $(path)/$(name).yml $(path)/$(name).$(ENV).yml $(path)/$(name).$(ENV).$(version).yml $(path)/$(name).$(version).yml))
	$(eval COMPOSE_FILE    := $(strip $(COMPOSE_FILE)))
	$(if $(wildcard $(path)/.env.dist),$(call .env,,$(path)/.env.dist,$(wildcard $(CONFIG)/$(ENV)/$(APP)/.env $(path)/.env.$(ENV) .env)))
endef
# function docker-tag: Tag docker image
define docker-tag
	$(call INFO,docker-tag,$(1)$(comma) $(2)$(comma) $(3)$(comma) $(4)$(comma) $(5))
	$(eval service         := $(or $(1),$(DOCKER_SERVICE)))
	$(eval source          := $(or $(2),$(DOCKER_REPOSITORY)/$(service)))
	$(eval source_tag      := $(or $(3),$(DOCKER_IMAGE_TAG)))
	$(eval target          := $(or $(4),$(DOCKER_REGISTRY_REPOSITORY)/$(service)))
	$(eval target_tag      := $(or $(5),$(source_tag)))
	$(RUN) docker tag $(source):$(source_tag) $(target):$(target_tag)
endef
