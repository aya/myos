##
# COMMON

# target bootstrap: Update application files and start dockers
# on local host
.PHONY: bootstrap
bootstrap: bootstrap-app bootstrap-host bootstrap-user app-bootstrap ## Update application files and start dockers

# target bootstrap-app: Fire install-bin-git
.PHONY: bootstrap-app
bootstrap-app: install-bin-git

# target bootstrap-docker: Install and configure docker
# on local host
.PHONY: bootstrap-docker
bootstrap-docker: install-bin-docker setup-docker-group

# target bootstrap-host: Fire bootstrap-docker target and start node stack
# on local host
.PHONY: bootstrap-host
bootstrap-host: bootstrap-docker node

# target bootstrap-user: Fire bootstrap-docker target and start user stack
# on local host
.PHONY: bootstrap-user
bootstrap-user: bootstrap-docker user

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
down: docker-compose-down ## Remove application dockers

# target exec: Exec ARGS in docker SERVICE
# on local host
.PHONY: exec
exec: ## Exec command in docker SERVICE
ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
	$(RUN) $(call exec,$(ARGS))
else
	$(call make,docker-compose-exec,,ARGS)
endif

# target exec@%: Exec ARGS in docker SERVICE of % ENV
# on all remote hosts
.PHONY: exec@%
exec@%: SERVICE ?= $(DOCKER_SERVICE)
exec@%:
	$(call make,ssh-exec,$(MYOS),APP ARGS SERVICE)

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
run: ## Run a command in a new docker
ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
	$(call run,$(ARGS))
else
	$(call make,docker-compose-run,,ARGS)
endif

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
## ex: stack-User-up will fire the docker-compose-up target in the User stack
.PHONY: stack-%
stack-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
		$(if $(filter $(command),$(filter-out %-%,$(patsubst docker-compose-%,%,$(filter docker-compose-%,$(MAKE_TARGETS))))), \
		$(call make,docker-compose-$(command) STACK="$(stack)" $(if $(filter $(COMPOSE_PROJECT_NAME_NODE),$(stack)),COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME_NODE)),,ARGS COMPOSE_IGNORE_ORPHANS SERVICE)))

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
up: docker-compose-up app-start ## Create application dockers

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
