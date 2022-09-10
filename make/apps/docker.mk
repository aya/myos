##
# DOCKER

# target docker-build: Fire docker-images-myos, Call docker-build-% target for each DOCKER_IMAGES
.PHONY: docker-build
docker-build: docker-images-myos
	$(foreach image,$(or $(SERVICE),$(DOCKER_IMAGES)),$(call make,docker-build-$(image)))

# target docker-build-%: Call docker-build for each Dockerfile in docker/% folder
.PHONY: docker-build-%
docker-build-%:
	if grep -q DOCKER_REPOSITORY docker/$*/Dockerfile 2>/dev/null; then $(eval DOCKER_BUILD_ARGS:=$(subst $(DOCKER_REPOSITORY),$(USER_DOCKER_REPOSITORY),$(DOCKER_BUILD_ARGS))) true; fi
	$(if $(wildcard docker/$*/Dockerfile),$(call docker-build,docker/$*))
	$(if $(findstring :,$*),$(eval DOCKERFILES := $(wildcard docker/$(subst :,/,$*)/Dockerfile)),$(eval DOCKERFILES := $(wildcard docker/$*/*/Dockerfile)))
	$(foreach dockerfile,$(DOCKERFILES),$(call docker-build,$(dir $(dockerfile)),$(DOCKER_REPOSITORY)/$(word 2,$(subst /, ,$(dir $(dockerfile)))):$(lastword $(subst /, ,$(dir $(dockerfile)))),"") && true)

# target docker-commit: Call docker-commit for each SERVICES
.PHONY: docker-commit
docker-commit:
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-commit,$(service)))

# target docker-commit-%: Call docker-commit with tag % for each SERVICES
.PHONY: docker-commit-%
docker-commit-%:
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-commit,$(service),,,$*))

# target docker-compose-build: Fire docker-images-myos, Call docker-compose build SERVICE
.PHONY: docker-compose-build
docker-compose-build: DOCKER_RUN_OPTIONS += -it
docker-compose-build: docker-images-myos
	$(call docker-compose,build $(DOCKER_BUILD_ARGS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-compose-config: Call docker-compose config
.PHONY: docker-compose-config
docker-compose-config:
	$(call docker-compose,config)

# target docker-compose-connect: Call docker-compose exec SERVICE DOCKER_SHELL
.PHONY: docker-compose-connect
docker-compose-connect: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-connect: DOCKER_RUN_OPTIONS += -it
docker-compose-connect:
	$(call docker-compose,exec $(SERVICE) $(DOCKER_SHELL)) || true

# target docker-compose-down: Call docker-compose rm SERVICE or docker-compose down
.PHONY: docker-compose-down
docker-compose-down: DOCKER_RUN_OPTIONS += -it
docker-compose-down:
	$(if $(filter $(SERVICE),$(SERVICES)),$(call docker-compose,rm -fs $(SERVICE)),$(call docker-compose,down $(DOCKER_COMPOSE_DOWN_OPTIONS) ||:))

# target docker-compose-exec: Call docker-compose-exec SERVICE ARGS
.PHONY: docker-compose-exec
docker-compose-exec: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-exec:
	$(call docker-compose-exec-sh,$(SERVICE),$(ARGS)) || true

# target docker-compose-logs: Call docker-compose logs SERVICE
.PHONY: docker-compose-logs
docker-compose-logs:
	$(call docker-compose,logs -f --tail=100 $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE))) || true

# target docker-compose-ps: Call docker-compose ps
.PHONY: docker-compose-ps
docker-compose-ps:
	$(call docker-compose,ps)

# target docker-compose-rebuild: Call docker-compose-build target with DOCKER_BUILD_NO_CACHE=true
.PHONY: docker-compose-rebuild
docker-compose-rebuild:
	$(call make,docker-compose-build DOCKER_BUILD_NO_CACHE=true)

# target docker-compose-recreate: Fire docker-compose-rm docker-compose-up
.PHONY: docker-compose-recreate
docker-compose-recreate: docker-compose-rm docker-compose-up

# target docker-compose-restart: Call docker-compose restart SERVICE
.PHONY: docker-compose-restart
docker-compose-restart:
	$(call docker-compose,restart $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-compose-rm: Call docker-compose rm SERVICE
.PHONY: docker-compose-rm
docker-compose-rm: DOCKER_RUN_OPTIONS += -it
docker-compose-rm:
	$(call docker-compose,rm -fs $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-compose-run: Call docker-compose run SERVICE ARGS
.PHONY: docker-compose-run
docker-compose-run: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-run: DOCKER_RUN_OPTIONS += -it
docker-compose-run:
	$(call docker-compose,run $(DOCKER_COMPOSE_RUN_OPTIONS) $(SERVICE) $(ARGS))

# target docker-compose-scale: Call docker-compose up --scale SERVICE=NUM
.PHONY: docker-compose-scale
docker-compose-scale: SERVICE ?= $(DOCKER_SERVICE)
docker-compose-scale:
	$(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) --scale $(SERVICE)=$(NUM))

# target docker-compose-start: Call docker-compose start SERVICE
.PHONY: docker-compose-start
docker-compose-start:
	$(call docker-compose,start $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-compose-stop: Call docker-compose stop SERVICE
.PHONY: docker-compose-stop
docker-compose-stop:
	$(call docker-compose,stop $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-compose-up: Fire docker-image-myos, Call docker-compose up SERVICE
.PHONY: docker-compose-up
docker-compose-up: DOCKER_RUN_OPTIONS += -it
docker-compose-up: docker-images-myos bootstrap-stack
	$(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))

# target docker-images-myos: Call myos-docker-build-% target for each DOCKER_IMAGES_MYOS
.PHONY: docker-images-myos
docker-images-myos:
	$(foreach image,$(subst $(quote),,$(DOCKER_IMAGES_MYOS)),$(call make,myos-docker-build-$(image)))

# target docker-images-rm: Call docker-image-rm-% target for DOCKER_REPOSITORY
.PHONY: docker-images-rm
docker-images-rm:
	$(call make,docker-images-rm-$(DOCKER_REPOSITORY)/)

# target docker-images-rm-%: Remove docker images matching %
.PHONY: docker-images-rm-%
docker-images-rm-%:
	docker images |awk '$$1 ~ /^$(subst /,\/,$*)/ {print $$3}' |sort -u |while read image; do $(RUN) docker rmi -f $$image; done

# target docker-login: Run 'docker login'
.PHONY: docker-login
docker-login: myos-user
	$(RUN) docker login

# target docker-network-create: Fire docker-network-create-% for DOCKER_NETWORK
.PHONY: docker-network-create
docker-network-create: docker-network-create-$(DOCKER_NETWORK)

# target docker-network-create-%: Run 'docker network create %'
.PHONY: docker-network-create-%
docker-network-create-%:
	if [ -z "$(shell docker network ls -q --filter name='^$*$$' 2>/dev/null)" ]; then \
	  $(RUN) sh -c 'docker network create $* >/dev/null 2>&1' \
	   && $(or $(call INFO,docker network $* created), true) \
		 ||: ; \
	fi

# target docker-network-rm: Fire docker-network-rm-% for DOCKER_NETWORK
.PHONY: docker-network-rm
docker-network-rm: docker-network-rm-$(DOCKER_NETWORK)

# target docker-network-rm-%: Run 'docker network rm %'
.PHONY: docker-network-rm-%
docker-network-rm-%:
	if [ -n "$(shell docker network ls -q --filter name='^$*$$' 2>/dev/null)" ]; then \
	  $(RUN) sh -c 'docker network rm $* >/dev/null 2>&1' \
	   && $(or $(call INFO,docker network $* removed), true) \
		 ||: ; \
	fi

# target docker-plugin-install: Run 'docker plugin install DOCKER_PLUGIN_OPTIONS DOCKER_PLUGIN'
.PHONY: docker-plugin-install
docker-plugin-install:
	$(eval docker_plugin_state := $(shell docker plugin ls | awk '$$2 == "$(DOCKER_PLUGIN)" {print $$NF}') )
	$(if $(docker_plugin_state),\
	  $(if $(filter $(docker_plugin_state),false),\
	    $(RUN) docker plugin enable $(DOCKER_PLUGIN) >/dev/null 2>&1 \
	     && $(or $(call INFO,docker plugin $(DOCKER_PLUGIN) enabled), true) \
	  ), \
	  $(RUN) docker plugin install $(DOCKER_PLUGIN_OPTIONS) $(DOCKER_PLUGIN) $(DOCKER_PLUGIN_ARGS) >/dev/null 2>&1 \
	   && $(or $(call INFO,docker plugin $(DOCKER_PLUGIN) installed), true) \
	)

# target docker-push: Call docker-push for each SERVICES
.PHONY: docker-push
docker-push:
ifneq ($(filter $(DEPLOY),true),)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-push,$(service)))
else
	$(call WARNING,target,$@,disabled in app,$(APP))
endif

# target docker-push-%: Call docker-push with tag % for each SERVICES
.PHONY: docker-push-%
docker-push-%:
ifneq ($(filter $(DEPLOY),true),)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-push,$(service),,$*))
else
	$(call WARNING,target,$@,disabled in app,$(APP))
endif

# target docker-rebuild: Call docker-build target with DOCKER_BUILD_CAHE=false
.PHONY: docker-rebuild
docker-rebuild:
	$(call make,docker-build DOCKER_BUILD_CACHE=false)

# target docker-rebuild-%: Call docker-build-% target with DOCKER_BUILD_CAHE=false
.PHONY: docker-rebuild-%
docker-rebuild-%:
	$(call make,docker-build-$* DOCKER_BUILD_CACHE=false)

# target docker-rm: Fire docker-rm-% for COMPOSE_PROJECT_NAME
.PHONY: docker-rm
docker-rm: docker-rm-$(COMPOSE_PROJECT_NAME)

# target docker-rm-%: Remove dockers matching %
.PHONY: docker-rm-%
docker-rm-%:
	docker ps -a |awk '$$NF ~ /^$*/ {print $$NF}' |while read docker; do $(RUN) docker rm -f $$docker; done

# target docker-run: Call docker-run-% target with ARGS for SERVICE
.PHONY: docker-run
docker-run: SERVICE ?= $(DOCKER_SERVICE)
docker-run:
	$(call make,docker-run-$(SERVICE),,ARGS)

# target docker-run-%: Call docker-run with image % and command ARGS
.PHONY: docker-run-%
docker-run-%: docker-build-%
	$(eval command         := $(ARGS))
	$(eval path            := $(patsubst %/,%,$*))
	$(eval image           := $(DOCKER_REPOSITORY)/$(lastword $(subst /, ,$(path)))$(if $(findstring :,$*),,:$(DOCKER_IMAGE_TAG)))
	$(eval image_id        := $(shell docker images -q $(image) 2>/dev/null))
	$(call docker-run,$(RUN) $(command),$(if $(image_id),$(image),$(path)))

# target docker-tag: Call docker-tag for each SERVICES
.PHONY: docker-tag
docker-tag:
ifneq ($(filter $(DEPLOY),true),)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-tag,$(service)))
else
	$(call WARNING,target,$@,disabled in app,$(APP))
endif

# target docker-tag-%: Call docker-tag with target tag % for each SERVICES
.PHONY: docker-tag-%
docker-tag-%:
ifneq ($(filter $(DEPLOY),true),)
	$(foreach service,$(or $(SERVICE),$(SERVICES)),$(call docker-tag,$(service),,,,$*))
else
	$(call WARNING,target,$@,disabled in app,$(APP))
endif

# target docker-volume-rm: Fire docker-volume-rm-% for COMPOSE_PROJECT_NAME
.PHONY: docker-volume-rm
docker-volume-rm: docker-volume-rm-$(COMPOSE_PROJECT_NAME)

# target docker-volume-rm-%: Remove docker volumes matching %
.PHONY: docker-volume-rm-%
docker-volume-rm-%:
	docker volume ls |awk '$$2 ~ /^$*/ {print $$2}' |sort -u |while read volume; do $(RUN) docker volume rm $$volume; done
