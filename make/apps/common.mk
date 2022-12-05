##
# COMMON

# target attach: Exec ARGS in docker SERVICE
# on local host
.PHONY: attach
attach: SERVICE ?= $(DOCKER_SERVICE)
attach: ## Attach to docker SERVICE
	$(eval attach          := $(COMPOSE_PROJECT_NAME)-$(SERVICE))
	$(if $(call docker-running,^$(attach)-1$), \
	  $(call docker-attach,$(attach)-1) \
	, $(call docker-attach,$(attach)) \
	)

# target bootstrap: Configure system
# on local host
.PHONY: bootstrap app-bootstrap
bootstrap: bootstrap-docker bootstrap-app app-bootstrap ## Configure system

# target bootstrap-app: Fire install-bin-git
.PHONY: bootstrap-app
bootstrap-app: install-bin-git

# target bootstrap-docker: Install and configure docker
.PHONY: bootstrap-docker
bootstrap-docker: install-bin-docker setup-docker-group setup-binfmt setup-nfsd setup-sysctl setup-ufw

# target bootstrap-stack: Call bootstrap target of each stack
.PHONY: bootstrap-stack
bootstrap-stack: docker-network debug-STACK $(foreach stack,$(STACK),bootstrap-stack-$(subst /,-,$(stack)) debug-$(stack))

# target build: Build application docker images to run
# on local host
.PHONY: build
build: docker-compose-build ## Build application docker images

# target build@%: Build application docker images of % ENV
# on local host
.PHONY: build@% app-build
build@%: myos-user
	$(eval docker_images   += $(foreach service,$(SERVICES),$(if $(shell docker images -q $(DOCKER_REPOSITORY)/$(service):$(DOCKER_IMAGE_TAG) 2>/dev/null),$(service))))
	$(eval build_app       := $(or $(filter $(DOCKER_BUILD_CACHE),false),$(filter-out $(docker_images),$(SERVICES))))
	$(if $(build_app), \
		$(call make,build-init app-build), \
		$(foreach service,$(SERVICES), \
			$(or $(call INFO,docker image $(DOCKER_REPOSITORY)/$(service):$(DOCKER_IMAGE_TAG) has id $(shell docker images -q $(DOCKER_REPOSITORY)/$(service):$(DOCKER_IMAGE_TAG) 2>/dev/null)), true) && \
		) true \
	)

# target clean: Clean application and docker images
# on local host
.PHONY: clean app-clean
clean: app-clean docker-rm docker-images-rm docker-volume-rm .env-clean ## Clean application and docker stuffs

# target clean@%: Clean deployed application and docker images of % ENV
# on local host
.PHONY: clean@%
clean@%: docker-rm docker-image-rm docker-volume-rm;

# target config: View application docker compose file
# on local host
.PHONY: config
config: docker-compose-config ## View application docker compose file

# target connect: Connect to docker SERVICE
# on local host
.PHONY: connect
connect: docker-compose-connect ## Connect to docker SERVICE

# target connect@%: Connect to docker SERVICE of % ENV
# on first remote host
.PHONY: connect@%
connect@%: SERVICE ?= $(DOCKER_SERVICE)
connect@%:
	$(call make,ssh-connect,$(MYOS),APP SERVICE)

# target deploy: Fire deploy@% for ENV
.PHONY: deploy
deploy: $(if $(filter $(ENV),$(ENV_DEPLOY)),deploy-localhost,deploy@$(ENV)) ## Deploy application dockers

# target down: Remove application dockers
# on local host
.PHONY: down
down: docker-compose-down ufw-delete ## Remove application dockers

# target exec: Exec ARGS in docker SERVICE
# on local host
.PHONY: exec
exec: SERVICE ?= $(DOCKER_SERVICE)
exec: ## Exec command in docker SERVICE
#ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
#	$(RUN) $(call exec,$(ARGS))
#else
	$(call docker-compose-exec-sh,$(SERVICE),$(ARGS)) || true
#endif

# target exec@%: Exec ARGS in docker SERVICE of % ENV
# on all remote hosts
.PHONY: exec@%
exec@%: SERVICE ?= $(DOCKER_SERVICE)
exec@%:
	$(call make,ssh-exec,$(MYOS),APP ARGS SERVICE)

# target force-%: Fire targets %, stack-user-% and stack-host-%
# on local host
.PHONY: force-%
force-%: % stack-user-% stack-host-%;

# target install app-install: Install application
# on local host
.PHONY: install app-install
install: bootstrap app-install ## Install application

# target logs: Display application dockers logs
# on local host
.PHONY: logs
logs: docker-compose-logs ## Display application dockers logs

# target ps: List application dockers
# on local host
.PHONY: ps
ps: docker-compose-ps ## List application dockers

# target rebuild: Rebuild application docker images
# on local host
.PHONY: rebuild
rebuild: docker-compose-rebuild ## Rebuild application dockers images

# target rebuild@%: Rebuild application docker images
# on local host
.PHONY: rebuild@%
rebuild@%:
	$(call make,build@$* DOCKER_BUILD_CACHE=false)

# target recreate: Recreate application dockers
# on local host
.PHONY: recreate
recreate: docker-compose-recreate app-start ## Recreate application dockers

# target reinstall: Fire clean, Call .env target, Call install target
# on local host
.PHONY: reinstall
reinstall: clean ## Reinstall application
	$(call make,.env)
	$(call make,install)

# target release: Fire release-create
.PHONY: release
release: release-create ## Create release VERSION

# target restart: Restart application dockers
# on local host
.PHONY: restart
restart: docker-compose-restart app-start ## Restart application

# target run: Run command ARGS in a new docker SERVICE
# on local host
.PHONY: run
run: SERVICE ?= $(or $(DOCKER_COMPOSE_SERVICE),$(DOCKER_SERVICE))
run: ## Run a command in a new docker
#ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
#	$(call run,$(ARGS))
#else
	$(eval DOCKER_RUN_OPTIONS += -it)
	$(call docker-compose,run $(DOCKER_COMPOSE_RUN_OPTIONS) $(SERVICE) $(ARGS))
#endif

# target run@%: Run command ARGS in a new docker SERVICE of % ENV
# on all remote hosts
.PHONY: run@%
run@%: SERVICE ?= $(DOCKER_SERVICE)
run@%:
	$(call make,ssh-run,$(MYOS),APP ARGS)

# target scale: Scale SERVICE application to NUM dockers
# on local host
.PHONY: scale
scale: docker-compose-scale ## Scale SERVICE application to NUM dockers

# target shutdown: remove application, host and user dockers
# on local host
.PHONY: shutdown
shutdown: force-down ## Shutdown all dockers

# target ssh@%: Connect to % ENV
# on first remote host
.PHONY: ssh@%
ssh@%:
	$(call make,ssh,$(MYOS),APP)

# target stack: Call docker-stack for each STACK
## it updates COMPOSE_FILE with all .yml files of the current stack
.PHONY: stack
stack:
	$(foreach stackz,$(STACK),$(call docker-stack,$(stackz)))

# target stack-%: Call docker-compose-% target on STACK
## it splits % on dashes and extracts stack from the beginning and command from
## the last part of %
## ex: stack-host-up will fire the docker-compose-up target in the host stack
.PHONY: stack-%
stack-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
		$(if $(filter $(command),$(filter-out %-%,$(patsubst docker-compose-%,%,$(filter docker-compose-%,$(MAKE_TARGETS))))), \
		$(call make,$(command) STACK="$(stack)",,ARGS COMPOSE_IGNORE_ORPHANS DOCKER_COMPOSE_PROJECT_NAME SERVICE User host)))

# target start app-start: Start application dockers
# on local host
.PHONY: start app-start
start: docker-compose-start ## Start application dockers

# target stop: Stop application dockers
# on local host
.PHONY: stop
stop: docker-compose-stop ## Stop application dockers

# target tests app-tests: Test application
# on local host
.PHONY: tests app-tests
tests: app-tests ## Test application

# target up: Create and start application dockers
# on local host
.PHONY: up
up: docker-compose-up ufw-update app-start ## Create application dockers

# target update app-update: Update application files
# on local host
.PHONY: update app-update
update: update-app app-update ## Update application files

# target upgrade app-upgrade: Upgrade application
# on local host
.PHONY: upgrade app-upgrade
upgrade: update app-upgrade release-upgrade ## Upgrade application

# target %: Always fired target
## it fires the stack and %-rule-exists targets everytime
%: FORCE stack %-rule-exists ;

# target %-rule-exists: Print a warning message if % target does not exists
%-rule-exists:
	$(if $(filter $*,$(MAKECMDGOALS)),$(if $(filter-out $*,$(MAKE_TARGETS)),$(call WARNING,target,$*,unavailable in app,$(APP))))
