CMDARGS                         += app-%-exec app-%-run

# function app-bootstrap: Define custom variables for app 1 in dir 2 with name 3 and type 4
define app-bootstrap
	$(call INFO,app-bootstrap,$(1)$(comma) $(2$(comma) $(3))$(comma) $(4))
	$(eval APP              := $(or $(1), $(APP)))
	$(eval APP_DIR          := $(or $(2), $(RELATIVE)$(APP)))
	$(eval APP_NAME         := $(or $(3),$(subst -,,$(subst .,,$(call LOWERCASE,$(APP))))))
	$(eval APP_TYPE         := $(or $(4), git))
	$(eval DOCKER_BUILD_DIR := $(APP_DIR))
	$(eval DOCKER_FILE      := $(wildcard $(APP_DIR)/docker/*/Dockerfile $(APP_DIR)/*/Dockerfile $(APP_DIR)/Dockerfile))
	$(eval COMPOSE_FILE     := $(wildcard $(APP_DIR)/docker-compose.yml $(APP_DIR)/docker-compose.$(ENV).yml $(APP_DIR)/docker/docker-compose.yml $(foreach file,$(patsubst $(APP_DIR)/docker/docker-compose.%,%,$(basename $(wildcard $(APP_DIR)/docker/docker-compose.*.yml))),$(if $(filter true,$(COMPOSE_FILE_$(file)) $(COMPOSE_FILE_$(call UPPERCASE,$(file)))),$(APP_DIR)/docker/docker-compose.$(file).yml))))
	$(if $(wildcard $(APP_DIR)/.env.sample),
	  $(call .env,$(APP_DIR)/.env,$(APP_DIR)/.env.sample)
	,
	  $(call .env,$(APP_DIR)/.env)
	)

endef

# function app-build: Call docker-build for each Dockerfile in dir 1
define app-build
	$(call INFO,app-build,$(1)$(comma))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE), \
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-build, $(dir $(dockerfile)), $(DOCKER_IMAGE), "" )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile in dir,$(or $(1),$(APP_DIR)))
	)
endef

# function app-docker: Define custom variables for Dockerfile 1
define app-docker
	$(call INFO,app-docker,$(1)$(comma))
	$(eval dir              := $(or $(APP_DIR)))
	$(eval dockerfile       := $(or $(1)))
	$(if $(wildcard $(dockerfile)),
	  $(eval service        := $(or $(SERVICE),$(subst .,,$(call LOWERCASE,$(lastword $(subst /, ,$(patsubst %/Dockerfile,%,$(dockerfile)))))),undefined))
	  $(eval docker         := ${COMPOSE_SERVICE_NAME}-$(service))
	  $(eval DOCKER_IMAGE   := $(DOCKER_REPOSITORY)/$(service):$(DOCKER_IMAGE_TAG))
	  $(eval DOCKER_LABELS  := SERVICE_NAME=$(docker) SERVICE_TAGS=urlprefix-$(service).$(APP_DOMAIN)/$(APP_PATH))
	  $(eval DOCKER_NAME    := $(docker))
	  $(eval DOCKER_RUN_NAME := --name $(DOCKER_NAME))
	,
	  $(call ERROR,Unable to find Dockerfile,$(dockerfile))
	)
endef

# function app-connect: Call docker exec $(DOCKER_SHELL) for each Dockerfile in dir 1
define app-connect
	$(call INFO,app-connect,$(1)$(comma))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE),
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker ps -q -f name=$(DOCKER_NAME) 2>/dev/null),
	      $(RUN) docker exec -it $(DOCKER_NAME) $(DOCKER_SHELL)
	    ,
	      $(call WARNING,Unable to find docker,$(DOCKER_NAME))
	    )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile,in dir $(or $(1),$(APP_DIR)))
	)
endef

# function app-down: Call docker rm for each Dockerfile in dir 1
define app-down
	$(call INFO,app-down,$(1)$(comma))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE),
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker ps -q -f name=$(DOCKER_NAME) 2>/dev/null),
	      $(RUN) docker rm -f $(DOCKER_NAME)
	    ,
	      $(call WARNING,Unable to find docker,$(DOCKER_NAME))
	    )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile,in dir $(or $(1),$(APP_DIR)))
	)
endef

# function app-exec: Call docker exec $(ARGS) for each Dockerfile in dir 1
define app-exec
	$(call INFO,app-exec,$(1)$(comma) $(2))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE),
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker ps -q -f name=$(DOCKER_NAME) 2>/dev/null),
	      $(RUN) docker exec -it $(DOCKER_NAME) $(ARGS)
	    ,
	      $(call WARNING,Unable to find docker,$(DOCKER_NAME))
	    )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile,in dir $(or $(1),$(APP_DIR)))
	)
endef

# function app-install: Run 'git clone url 1 dir 2'
define app-install
	$(call INFO,app-install,$(1)$(comma) $(2))
	$(eval url              := $(or $(1), $(APP_REPOSITORY_URL)))
	$(eval dir              := $(or $(2), $(RELATIVE)$(lastword $(subst /, ,$(url)))))
	$(if $(wildcard $(dir)/.git),
	  $(call INFO,app: $(url) already installed in dir: $(dir)),
	  $(RUN) git clone $(QUIET) $(url) $(dir)
	)
endef

# function app-logs: Call docker logs $(ARGS) for each Dockerfile in dir 1
define app-logs
	$(call INFO,app-logs,$(1)$(comma) $(2))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE),
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker ps -q -f name=$(DOCKER_NAME) 2>/dev/null),
	      $(RUN) docker logs --follow --tail=100 $(DOCKER_NAME)
	    ,
	      $(call WARNING,Unable to find docker,$(DOCKER_NAME))
	    )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile,in dir $(or $(1),$(APP_DIR)))
	)
endef

# function app-ps: Call docker ps $(ARGS) for each Dockerfile in dir 1
define app-ps
	$(call INFO,app-ps,$(1)$(comma) $(2))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(if $(DOCKER_FILE),
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(eval DOCKERS += $(DOCKER_NAME))
	  )
	  $(RUN) docker ps $(patsubst %,-f name=%,$(DOCKERS)) 2>/dev/null
	,
	  $(call ERROR,Unable to find a,Dockerfile,in dir $(or $(1),$(APP_DIR)))
	)
endef

# function app-rebuild: Call app-build with DOCKER_BUILD_CACHE=false
define app-rebuild
	$(call INFO,app-rebuild,$(1)$(comma))
	$(eval DOCKER_BUILD_CACHE := false)
	$(call app-build,$(1))
endef

# function app-run: Call docker-run for each Dockerfile in dir 1 with args 2
define app-run
	$(call INFO,app-run,$(1)$(comma) $(2))
	$(if $(filter-out $(APP_DIR),$(1)),
	  $(eval DOCKER_FILE    := $(wildcard $(1)/docker/*/Dockerfile $(1)/*/Dockerfile $(1)/Dockerfile))
	)
	$(eval args             := $(or $(2), $(ARGS)))
	$(eval DOCKER_RUN_OPTIONS += -it)
	$(if $(DOCKER_FILE), \
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker images -q $(DOCKER_IMAGE) 2>/dev/null),
	      $(call docker-run,$(args))
	    ,
	      $(call ERROR,Unable to find docker image,$(DOCKER_IMAGE))
	    )
	  ),
	  $(call ERROR,Unable to find a,Dockerfile in dir,$(or $(1),$(APP_DIR)))
	)
endef

# function app-up: Call docker-run (-d) for each Dockerfile in dir 1
define app-up
	$(call INFO,app-up,$(1)$(comma))
	$(eval DOCKER_RUN_OPTIONS += -d)
	$(call app-run,$(1))
endef

# function app-update: Run 'cd dir 1 && git pull' or Call app-install
define app-update
	$(call INFO,app-update,$(1)$(comma) $(2))
	$(eval url              := $(or $(1), $(APP_REPOSITORY_URL)))
	$(eval dir              := $(or $(2), $(APP_DIR)))
	$(if $(wildcard $(dir)/.git),
	  $(RUN) sh -c 'cd $(dir) && git pull $(QUIET)',
	  $(call app-install,$(url),$(dir))
	)
endef
