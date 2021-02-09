##
# DOCKER

.PHONY: docker-build
docker-build: docker-images-infra
	$(foreach image,$(or $(SERVICE),$(DOCKER_IMAGES)),$(call make,docker-build-$(image)))

.PHONY: docker-build-%
docker-build-%:
	if grep -q DOCKER_REPOSITORY docker/$*/Dockerfile 2>/dev/null; then $(eval DOCKER_BUILD_ARGS:=$(subst $(DOCKER_REPOSITORY),$(DOCKER_REPOSITORY_INFRA),$(DOCKER_BUILD_ARGS))) true; fi
	$(if $(wildcard docker/$*/Dockerfile),$(call docker-build,docker/$*))
	$(if $(findstring :,$*),$(eval DOCKERFILES := $(wildcard docker/$(subst :,/,$*)/Dockerfile)),$(eval DOCKERFILES := $(wildcard docker/$*/*/Dockerfile)))
	$(foreach dockerfile,$(DOCKERFILES),$(call docker-build,$(dir $(dockerfile)),$(DOCKER_REPOSITORY)/$(word 2,$(subst /, ,$(dir $(dockerfile)))):$(lastword $(subst /, ,$(dir $(dockerfile)))),"") && true)

.PHONY: docker-commit
docker-commit:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-commit,$(service)))

.PHONY: docker-commit-%
docker-commit-%:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-commit,$(service),,,$*))

.PHONY: docker-compose-build
docker-compose-build: docker-images-infra
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,build $(if $(filter $(DOCKER_BUILD_NO_CACHE),true),--pull --no-cache) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-compose-config
docker-compose-config:
	$(call docker-compose,config)

.PHONY: docker-compose-connect
docker-compose-connect: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-connect:
	$(call docker-compose,exec $(SERVICE) $(DOCKER_SHELL)) || true

.PHONY: docker-compose-down
docker-compose-down:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(if $(filter $(SERVICE),$(SERVICES)),$(call docker-compose,rm -fs $(SERVICE)),$(call docker-compose,down $(DOCKER_COMPOSE_DOWN_OPTIONS)))

.PHONY: docker-compose-exec
docker-compose-exec: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-exec:
	$(call docker-compose-exec,$(SERVICE),$(ARGS)) || true

.PHONY: docker-compose-logs
docker-compose-logs:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,logs -f --tail=100 $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE))) || true

.PHONY: docker-compose-ps
docker-compose-ps:
	$(call docker-compose,ps)

.PHONY: docker-compose-rebuild
docker-compose-rebuild: docker-images-infra
	$(call make,docker-compose-build DOCKER_BUILD_NO_CACHE=true)

.PHONY: docker-compose-recreate
docker-compose-recreate: docker-compose-rm docker-compose-up

.PHONY: docker-compose-restart
docker-compose-restart:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,restart $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-compose-rm
docker-compose-rm:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,rm -fs $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-compose-run
docker-compose-run: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-run:
	$(call docker-compose,run $(SERVICE) $(ARGS))

.PHONY: docker-compose-scale
docker-compose-scale: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-scale:
	$(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) --scale $(SERVICE)=$(NUM))

.PHONY: docker-compose-start
docker-compose-start:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,start $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-compose-stop
docker-compose-stop:
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,stop $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-compose-up
docker-compose-up: docker-images-infra
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

.PHONY: docker-images-infra
docker-images-infra:
	$(foreach image,$(subst $(quote),,$(DOCKER_IMAGES_INFRA)),$(call make,infra-docker-build-$(image)))

.PHONY: docker-login
docker-login: infra-aws-ecr-login

.PHONY: docker-network-create
docker-network-create: docker-network-create-$(DOCKER_NETWORK)

.PHONY: docker-network-create-%
docker-network-create-%:
	[ -n "$(shell docker network ls -q --filter name='^$*$$' 2>/dev/null)" ] \
	  || { echo -n "Creating docker network $* ... " && $(ECHO) docker network create $* >/dev/null 2>&1 && echo "done" || echo "ERROR"; }

.PHONY: docker-network-rm
docker-network-rm: docker-network-rm-$(DOCKER_NETWORK)

.PHONY: docker-network-rm-%
docker-network-rm-%:
	[ -z "$(shell docker network ls -q --filter name='^$*$$' 2>/dev/null)" ] \
	  || { echo -n "Removing docker network $* ... " && $(ECHO) docker network rm $* >/dev/null 2>&1 && echo "done" || echo "ERROR"; }

.PHONY: docker-plugin-install
docker-plugin-install:
	$(eval docker_plugin_state := $(shell docker plugin ls | awk '$$2 == "$(DOCKER_PLUGIN)" {print $$NF}') )
	$(if $(docker_plugin_state),$(if $(filter $(docker_plugin_state),false),echo -n "Enabling docker plugin $(DOCKER_PLUGIN) ... " && $(ECHO) docker plugin enable $(DOCKER_PLUGIN) >/dev/null 2>&1 && echo "done" || echo "ERROR"),echo -n "Installing docker plugin $(DOCKER_PLUGIN) ... " && $(ECHO) docker plugin install $(DOCKER_PLUGIN_OPTIONS) $(DOCKER_PLUGIN) $(DOCKER_PLUGIN_ARGS) >/dev/null 2>&1 && echo "done" || echo "ERROR")

.PHONY: docker-push
docker-push:
ifneq ($(filter $(DEPLOY),true),)
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-push,$(service)))
else
	printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}target${COLOR_RESET} $@ ${COLOR_GREEN}not enabled in${COLOR_RESET} $(APP).\n" >&2
endif

.PHONY: docker-push-%
docker-push-%:
ifneq ($(filter $(DEPLOY),true),)
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-push,$(service),,$*))
else
	printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}target${COLOR_RESET} $@ ${COLOR_GREEN}not enabled in${COLOR_RESET} $(APP).\n" >&2
endif

.PHONY: docker-rebuild
docker-rebuild:
	$(call make,docker-build DOCKER_BUILD_CACHE=false)

.PHONY: docker-rebuild-%
docker-rebuild-%:
	$(call make,docker-build-$* DOCKER_BUILD_CACHE=false)

.PHONY: docker-run
docker-run: SERVICE ?= $(DOCKER_SERVICE)
docker-run:
	$(call make,docker-run-$(SERVICE),,ARGS)

.PHONY: docker-run-%
docker-run-%: docker-build-%
	$(eval command         := $(ARGS))
	$(eval path            := $(patsubst %/,%,$*))
	$(eval image           := $(DOCKER_REPOSITORY)/$(lastword $(subst /, ,$(path)))$(if $(findstring :,$*),,:$(DOCKER_IMAGE_TAG)))
	$(eval image_id        := $(shell docker images -q $(image) 2>/dev/null))
	$(call docker-run,$(if $(image_id),$(image),$(path)),$(command))

.PHONY: docker-tag
docker-tag:
ifneq ($(filter $(DEPLOY),true),)
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-tag,$(service)))
else
	printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}target${COLOR_RESET} $@ ${COLOR_GREEN}not enabled in${COLOR_RESET} $(APP).\n" >&2
endif

.PHONY: docker-tag-%
docker-tag-%:
ifneq ($(filter $(DEPLOY),true),)
	$(eval DRYRUN_IGNORE := true)
	$(eval SERVICES      ?= $(shell $(call docker-compose,--log-level critical config --services)))
	$(eval DRYRUN_IGNORE := false)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-tag,$(service),,,,$*))
else
	printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}target${COLOR_RESET} $@ ${COLOR_GREEN}not enabled in${COLOR_RESET} $(APP).\n" >&2
endif
