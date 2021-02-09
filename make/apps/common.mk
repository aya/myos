##
# COMMON

.PHONY: bootstrap
bootstrap: bootstrap-git bootstrap-docker ## Bootstrap application

.PHONY: boostrap-docker
bootstrap-docker: docker-network-create
	$(if $(filter bootstrap-$(APP),$(MAKETARGETS)),$(call make,bootstrap-$(APP)))
	$(call make,docker-compose-up)

.PHONY: bootstrap-git
bootstrap-git:
ifneq ($(SUBREPO),)
	if ! git config remote.subrepo/$(SUBREPO).url > /dev/null ; \
		then git remote add subrepo/$(SUBREPO) $(GIT_REPOSITORY); \
	fi
endif

.PHONY: config
config: docker-compose-config ## View docker compose file

.PHONY: connect
connect: docker-compose-connect ## Connect to docker $(SERVICE)

.PHONY: connect@%
connect@%: SERVICE ?= $(DOCKER_SERVICE)
connect@%: ## Connect to docker $(SERVICE) on first remote host
	$(call make,ssh-connect,../infra,APP SERVICE)

.PHONY: down
down: docker-compose-down ## Remove application dockers

.PHONY: exec
exec: ## Exec a command in docker $(SERVICE)
ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
	$(call exec,$(ARGS))
else
	$(call make,docker-compose-exec,,ARGS)
endif

.PHONY: exec@%
exec@%: SERVICE ?= $(DOCKER_SERVICE)
exec@%: ## Exec a command in docker $(SERVICE) on all remote hosts
	$(call make,ssh-exec,../infra,APP ARGS SERVICE)

.PHONY: logs
logs: docker-compose-logs ## Display application dockers logs

.PHONY: ps
ps: docker-compose-ps ## List application dockers

.PHONY: recreate
recreate: docker-compose-recreate start-up ## Recreate application dockers

.PHONY: reinstall
reinstall: clean ## Reinstall application
	$(call make,.env)
	$(call make,install)

.PHONY: restart
restart: docker-compose-restart start-up ## Restart application

.PHONY: run
run: ## Run a command in a new docker
ifneq (,$(filter $(ENV),$(ENV_DEPLOY)))
	$(call run,$(ARGS))
else
	$(call make,docker-compose-run,,ARGS)
endif

.PHONY: run@%
run@%: SERVICE ?= $(DOCKER_SERVICE)
run@%: ## Run a command on all remote hosts
	$(call make,ssh-run,../infra,APP ARGS)

.PHONY: scale
scale: docker-compose-scale ## Scale application to NUM dockers

.PHONY: ssh@%
ssh@%: ## Connect to first remote host
	$(call make,ssh,../infra,APP)

# target stack: Call docker-stack function with each value of $(STACK)
.PHONY: stack
stack:
	$(foreach stackz,$(STACK),$(call docker-stack,$(stackz)))

# target stack-%: Call docker-compose-* command on a given stack
## ex: calling stack-base-up will fire the docker-compose-up target on the base stack
## it splits $* on dashes and extracts stack from the beginning of $* and command
## from the last part of $*
.PHONY: stack-%
stack-%:
	$(eval stack   := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(findstring -,$*), \
	  $(if $(filter $(command),$(filter-out %-%,$(patsubst docker-compose-%,%,$(filter docker-compose-%,$(MAKETARGETS))))), \
	    $(call make,docker-compose-$(command) STACK="$(stack)" $(if $(filter node,$(stack)),COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME_INFRA_NODE)),,ARGS COMPOSE_IGNORE_ORPHANS SERVICE)))

.PHONY: start
start: docker-compose-start ## Start application dockers

.PHONY: stop
stop: docker-compose-stop ## Stop application dockers

.PHONY: tests app-tests
tests: app-tests ## Test application

.PHONY: up
up: docker-compose-up start-up ## Create application dockers

.PHONY: update app-update
update: app-update ## Update application

# target %: Always fired target
## this target is fired everytime make is runned to call the stack target and
## update COMPOSE_FILE variable with all .yml files of the current project stack
.PHONY: FORCE
%: FORCE stack %-rule-exists ;

# target %-rule-exists: Print a warning message if $* target does not exists
%-rule-exists:
	$(if $(filter $*,$(MAKECMDGOALS)),$(if $(filter-out $*,$(MAKETARGETS)),printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}target${COLOR_RESET} $* ${COLOR_GREEN}not available in app${COLOR_RESET} $(APP).\n" >&2))
