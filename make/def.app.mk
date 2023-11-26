MAKECMDARGS                     += app-%-exec app-%-run

# function app-attach: Call docker-attach for each Dockerfile in dir 1
define app-attach
	$(call INFO,app-attach,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,logs -f $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-attach)
	  )
	)
endef

# function app-bootstrap: Define custom variables for app 1 in dir 2 with name 3 and type 4
define app-bootstrap
	$(call INFO,app-bootstrap,$(1)$(comma) $(2$(comma) $(3))$(comma) $(4))
	$(eval APP              := $(or $(1), $(APP)))
	$(eval APP_DIR          := $(or $(2), $(RELATIVE)$(APP)))
	$(eval APP_NAME         := $(or $(3),$(subst -,,$(subst .,,$(call LOWERCASE,$(APP))))))
	$(eval COMPOSE_PROJECT_NAME := $(if $(DOCKER_COMPOSE_PROJECT_NAME),$(DOCKER_COMPOSE_PROJECT_NAME),$(subst .,,$(call LOWERCASE,$(USER)-$(APP_NAME)-$(ENV)$(addprefix -,$(subst /,,$(subst -,,$(APP_PATH))))))))
	$(eval COMPOSE_SERVICE_NAME := $(if $(DOCKER_COMPOSE_SERVICE_NAME),$(DOCKER_COMPOSE_SERVICE_NAME),$(subst _,-,$(COMPOSE_PROJECT_NAME))))
	$(eval DOCKER_BUILD_DIR := $(APP_DIR))
	$(call compose-file,$(APP_DIR) $(APP_DIR)/$(or $(APP_DOCKER_DIR),$(DOCKER_DIR)),docker-compose)
	$(call compose-file,apps apps/$(APP),$(APP))
	$(eval APP_COMPOSE_FILE := $(COMPOSE_FILE))
	$(foreach stackz,$(STACK),$(call docker-stack,$(stackz)))
	$(call compose-file,$(MYOS_STACK),$(MYOS_STACK_FILE))
	$(call .env,$(APP_DIR)/.env,$(APP_DIR)/.env.dist $(APP_DIR)/.env.example $(APP_DIR)/.env.sample)
endef

# function app-build: Call docker-build for each Dockerfile in dir 1
define app-build
	$(call INFO,app-build,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,build $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-build, $(dir $(dockerfile)), $(DOCKER_IMAGE), "" )
	  )
	)
endef

# function app-clean: Remove docker images and volumes for each Dockerfile in dir 1
define app-clean
	$(call INFO,app-clean,$(1)$(comma))
	$(eval DOCKER_COMPOSE_DOWN_OPTIONS += --rmi all --volumes)
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,down $(DOCKER_COMPOSE_DOWN_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-rm)
	  )
	)
endef

# function app-config: Call docker-compose config with each docker-compose.yml in dir 1
define app-config
	$(call INFO,app-config,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,config)
	, $(call WARNING,Unable to find a file docker-compose.yml in dir,$(APP_DIR)) \
	)
endef

# function app-connect: Call docker exec $(DOCKER_SHELL) for each Dockerfile in dir 1
define app-connect
	$(call INFO,app-connect,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,exec $(or $(SERVICE),$(DOCKER_SERVICE)) $(DOCKER_SHELL))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-connect)
	  )
	)
endef

# function app-docker: Define custom variables for Dockerfile 1
define app-docker
	$(call INFO,app-docker,$(1)$(comma))
	$(eval dir              := $(or $(APP_DIR)))
	$(eval dockerfile       := $(or $(1)))
	$(if $(wildcard $(dockerfile)),
	  $(eval service        := $(or $(DOCKER_SERVICE),$(subst .,,$(call LOWERCASE,$(lastword $(subst /, ,$(patsubst %/Dockerfile,%,$(dockerfile)))))),undefined))
	  $(eval docker         := ${COMPOSE_SERVICE_NAME}-$(service))
	  $(eval DOCKER_IMAGE   := $(DOCKER_REPOSITORY)/$(service):$(DOCKER_IMAGE_TAG))
	  $(eval DOCKER_LABELS  := SERVICE_NAME=$(docker) SERVICE_TAGS=$(call urlprefix,$(APP_PATH),,$(service).$(APP_HOST)))
	  $(eval DOCKER_NAME    := $(docker))
	  $(eval DOCKER_RUN_NAME := --name $(DOCKER_NAME))
	, $(call ERROR,Unable to find Dockerfile,$(dockerfile))
	)
endef

# function app-down: Call docker rm for each Dockerfile in dir 1
define app-down
	$(call INFO,app-down,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,down $(DOCKER_COMPOSE_DOWN_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-rm)
	  )
	)
endef

# function app-exec: Call docker exec $(ARGS) for each Dockerfile in dir 1
define app-exec
	$(call INFO,app-exec,$(1)$(comma) $(2))
	$(eval args             := $(or $(2), $(ARGS)))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,exec $(or $(SERVICE),$(DOCKER_SERVICE)) $(args))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call exec,$(args))
	  )
	)
endef

# function app-install: Run 'git clone url 1 dir 2'
define app-install
	$(call INFO,app-install,$(1)$(comma) $(2))
	$(eval url              := $(or $(1), $(REPOSITORY_URL), $(APP_REPOSITORY_URL)))
	$(eval dir              := $(or $(2), $(RELATIVE)$(lastword $(subst /, ,$(url)))))
	$(if $(wildcard $(dir)/.git),
	  $(call INFO,app $(url) already installed in dir $(dir))
	, $(RUN) git clone $(QUIET) $(url) $(dir) && if [ -n "$(APP_VERSION)" ]; then cd $(dir) && git reset --hard $(QUIET) "$(APP_VERSION)"; fi
	)
endef

# function app-logs: Call docker logs $(ARGS) for each Dockerfile in dir 1
define app-logs
	$(call INFO,app-logs,$(1)$(comma) $(2))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,logs $(DOCKER_COMPOSE_LOGS_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-logs)
	  )
	)
endef

# function app-ps: Call docker ps for each Dockerfile in dir 1
define app-ps
	$(call INFO,app-ps,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,ps $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(eval DOCKERS += $(DOCKER_NAME))
	  )
	  $(RUN) docker ps $(patsubst %,-f name=%,$(DOCKERS)) 2>/dev/null
	)
endef

# function app-rebuild: Call app-build with DOCKER_BUILD_CACHE=false
define app-rebuild
	$(call INFO,app-rebuild,$(1)$(comma))
	$(eval DOCKER_BUILD_CACHE := false)
	$(call app-build,$(1))
endef

# function app-restart: Call app-stop and app-start
define app-restart
	$(call INFO,app-restart,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,restart $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call app-stop,$(1)) # NEED FIX
	  $(call app-start,$(1))
	)
endef

# function app-run: Call docker-run for each Dockerfile in dir 1 with args 2
define app-run
	$(call INFO,app-run,$(1)$(comma) $(2))
	$(eval args             := $(or $(2), $(ARGS)))
	$(eval DOCKER_RUN_OPTIONS += -it)
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,run $(DOCKER_RUN_OPTIONS) $(or $(SERVICE),$(DOCKER_SERVICE)) $(args))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(if $(shell docker images -q $(DOCKER_IMAGE) 2>/dev/null),
	      $(call docker-run,$(DOCKER_IMAGE),$(args))
	    , $(call ERROR,Unable to find docker image,$(DOCKER_IMAGE))
	    )
	  )
	)
endef

# function app-scale: Call docker-compose scale in dir 1
define app-scale
	$(call INFO,app-scale,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) --scale $(or $(SERVICE),$(DOCKER_SERVICE))=$(NUM))
	, $(call WARNING,Unable to find a file docker-compose.yml in dir,$(APP_DIR)) \
	)
endef

# function app-start: Call docker start for each Dockerfile in dir 1
define app-start
	$(call INFO,app-start,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,start $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-start)
	  )
	)
endef

# function app-stop: Call docker stop for each Dockerfile in dir 1
define app-stop
	$(call INFO,app-stop,$(1)$(comma))
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,stop $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(call docker-file,$(1))
	  $(foreach dockerfile,$(DOCKER_FILE),
	    $(call app-docker,$(dockerfile))
	    $(call docker-stop)
	  )
	)
endef

# function app-up: Call docker-run (-d) for each Dockerfile in dir 1
define app-up
	$(call INFO,app-up,$(1)$(comma))
	$(eval DOCKER_RUN_OPTIONS := -d)
	$(if $(APP_COMPOSE_FILE),
	  $(call docker-compose,up $(DOCKER_COMPOSE_UP_OPTIONS) $(if $(filter $(SERVICE),$(SERVICES)),$(SERVICE)))
	, $(if $(shell docker ps -q -f name=$(DOCKER_NAME) 2>/dev/null),
	    $(call INFO,docker $(DOCKER_NAME) already running)
	  , $(call app-run,$(1))
	  )
	)
endef

# function app-update: Run 'cd dir 1 && git pull' or Call app-install
define app-update
	$(call INFO,app-update,$(1)$(comma) $(2))
	$(eval url              := $(or $(1), $(REPOSITORY_URL), $(APP_REPOSITORY_URL)))
	$(eval dir              := $(or $(2), $(APP_DIR)))
	$(if $(wildcard $(dir)/.git),
	  $(RUN) sh -c 'cd $(dir) && git pull $(QUIET) && if [ -n "$(APP_VERSION)" ]; then git reset --hard $(QUIET) "$(APP_VERSION)"; fi'
	, $(call app-install,$(url),$(dir))
	)
endef
