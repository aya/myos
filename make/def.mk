comma                           ?= ,
dollar                          ?= $
dquote                          ?= "
quote                           ?= '
APP                             ?= $(if $(wildcard .git),$(notdir $(CURDIR)))
APP_NAME                        ?= $(APP)
APP_TYPE                        ?= $(if $(SUBREPO),subrepo) $(if $(MYOS),,myos)
APPS                            ?= $(if $(MONOREPO),$(sort $(patsubst $(MONOREPO_DIR)/%/.git,%,$(wildcard $(MONOREPO_DIR)/*/.git))))
APPS_NAME                       ?= $(foreach app,$(APPS),$(or $(shell awk -F '=' '$$1 == "APP" {print $$2}' $(or $(wildcard $(MONOREPO_DIR)/$(app)/.env),$(wildcard $(MONOREPO_DIR)/$(app)/.env.$(ENV)),$(MONOREPO_DIR)/$(app)/.env.dist) 2>/dev/null),$(app)))
BRANCH                          ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
CMDS                            ?= exec exec:% exec@% run run:% run@%
COMMIT                          ?= $(shell git rev-parse $(BRANCH) 2>/dev/null)
CONTEXT                         ?= $(if $(APP),APP BRANCH VERSION) $(shell awk 'BEGIN {FS="="}; $$1 !~ /^(\#|$$)/ {print $$1}' .env.dist 2>/dev/null)
CONTEXT_DEBUG                   ?= APPS GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME MAKEFILE_LIST MAKE_DIR MAKE_SUBDIRS MAKE_CMD_ARGS MAKE_ENV_ARGS MONOREPO_DIR UID USER env
DEBUG                           ?= false
DOCKER                          ?= true
DOMAIN                          ?= localhost
DRONE                           ?= false
DRYRUN                          ?= false
DRYRUN_IGNORE                   ?= false
DRYRUN_RECURSIVE                ?= false
ENV                             ?= dist
ENV_FILE                        ?= $(wildcard ../$(PARAMETERS)/$(ENV)/$(APP)/.env) .env
ENV_LIST                        ?= debug local tests release master #TODO: staging develop
ENV_RESET                       ?= false
ENV_VARS                        ?= APP BRANCH ENV HOSTNAME GID GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME MONOREPO MONOREPO_DIR TAG UID USER VERSION
GID                             ?= $(shell id -g 2>/dev/null)
GIT_AUTHOR_EMAIL                ?= $(shell git config user.email 2>/dev/null)
GIT_AUTHOR_NAME                 ?= $(shell git config user.name 2>/dev/null)
GIT_PARAMETERS_REPOSITORY       ?= $(call pop,$(GIT_UPSTREAM_REPOSITORY))/$(notdir $(PARAMETERS))
GIT_REPOSITORY                  ?= $(if $(SUBREPO),$(shell awk -F ' = ' '$$1 ~ /^[[\s\t]]*remote$$/ {print $$2}' .gitrepo 2>/dev/null),$(shell git config --get remote.origin.url 2>/dev/null))
GIT_UPSTREAM_REPOSITORY         ?= $(if $(findstring ://,$(GIT_REPOSITORY)),$(call pop,$(call pop,$(GIT_REPOSITORY)))/,$(call pop,$(GIT_REPOSITORY),:):)$(GIT_UPSTREAM_USER)/$(lastword $(subst /, ,$(GIT_REPOSITORY)))
GIT_UPSTREAM_USER               ?= $(or $(MONOREPO),$(USER))
HOSTNAME                        ?= $(shell hostname 2>/dev/null |sed 's/\..*//')
MAKE_ARGS                       ?= $(foreach var,$(MAKE_VARS),$(if $($(var)),$(var)='$($(var))'))
MAKE_SUBDIRS                    ?= $(if $(filter myos,$(MYOS)),monorepo,$(if $(APP),apps $(foreach type,$(APP_TYPE),$(if $(wildcard $(MAKE_DIR)/apps/$(type)),apps/$(type)))))
MAKE_CMD_ARGS                   ?= $(foreach var,$(MAKE_CMD_VARS),$(var)='$($(var))')
MAKE_CMD_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter command\ line,$(origin $(var))),$(var))))
MAKE_ENV_ARGS                   ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_ENV_VARS)),$(var)='$($(var))')
MAKE_ENV_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter environment,$(origin $(var))),$(var))))
MAKE_FILE_ARGS                  ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_FILE_VARS)),$(var)='$($(var))')
MAKE_FILE_VARS                  ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter file,$(origin $(var))),$(var))))
MAKE_TARGETS                    ?= $(filter-out $(.VARIABLES),$(shell $(MAKE) -qp 2>/dev/null |awk -F':' '/^[a-zA-Z0-9][^$$\#\/\t=]*:([^=]|$$)/ {print $$1}' |sort -u))
MAKE_VARS                       ?= ENV
MONOREPO                        ?= $(if $(filter myos,$(MYOS)),$(notdir $(CURDIR)),$(if $(APP),$(notdir $(realpath $(CURDIR)/..))))
MONOREPO_DIR                    ?= $(if $(MONOREPO),$(if $(filter myos,$(MYOS)),$(realpath $(CURDIR)),$(if $(APP),$(realpath $(CURDIR)/..))))
MYOS                            ?= $(if $(filter $(MAKE_DIR),$(call pop,$(MAKE_DIR))),,$(call pop,$(MAKE_DIR)))
QUIET                           ?= $(if $(filter false,$(VERBOSE)),--quiet)
RECURSIVE                       ?= true
SHARED                          ?= shared
SSH_DIR                         ?= ${HOME}/.ssh
SUBREPO                         ?= $(if $(wildcard .gitrepo),$(notdir $(CURDIR)))
TAG                             ?= $(shell git tag -l --points-at $(BRANCH) 2>/dev/null)
UID                             ?= $(shell id -u 2>/dev/null)
USER                            ?= $(shell id -nu 2>/dev/null)
VERBOSE                         ?= true
VERSION                         ?= $(shell git describe --tags $(BRANCH) 2>/dev/null || git rev-parse $(BRANCH) 2>/dev/null)

ifeq ($(DOCKER), true)
ENV_ARGS                         = $(env.docker.args) $(env.docker.dist)
else
ENV_ARGS                         = $(env.args) $(env.dist)
endif

ifneq ($(DEBUG),true)
.SILENT:
else
CONTEXT                         += $(CONTEXT_DEBUG)
endif
ifeq ($(DRYRUN),true)
ECHO                             = $(if $(filter $(DRYRUN_IGNORE),true),,printf '${COLOR_BROWN}$(APP)${COLOR_RESET}[${COLOR_GREEN}$(MAKELEVEL)${COLOR_RESET}] ${COLOR_BLUE}$@${COLOR_RESET}:${COLOR_RESET} '; echo)
ifeq ($(RECURSIVE), true)
DRYRUN_RECURSIVE                := true
endif
endif

# Guess OS
ifeq ($(OSTYPE),cygwin)
HOST_SYSTEM                     := CYGWIN
else ifeq ($(OS),Windows_NT)
HOST_SYSTEM                     := WINDOWS
else
UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(UNAME_S),Linux)
HOST_SYSTEM                     := LINUX
endif
ifeq ($(UNAME_S),Darwin)
HOST_SYSTEM                     := DARWIN
endif
endif

# include .env files
include $(wildcard $(ENV_FILE))

ifeq ($(HOST_SYSTEM),DARWIN)
ifneq ($(DOCKER),true)
SED_SUFFIX                      := '\'\''
endif
endif

define conf
	$(eval file := $(1))
	$(eval block := $(2))
	$(eval variable := $(3))
	[ -r "$(file)" ] && while IFS='=' read -r key value; do \
		case $${key} in \
		  \#*) \
			continue; \
			;; \
		  \[*\]) \
			current_bloc="$${key##\[}"; \
			current_bloc="$${current_bloc%%\]}"; \
			[ -z "$(block)" ] && [ -z "$(variable)" ] && printf '%s\n' "$${current_bloc}" ||:; \
			;; \
		  *) \
			key=$${key%$${key##*[![:space:]]}}; \
			value=$${value#$${value%%[![:space:]]*}}; \
			if [ "$(block)" = "$${current_bloc}" ] && [ "$${key}" ]; then \
				[ -z "$(variable)" ] && printf '%s=%s\n' "$${key}" "$${value}" ||:; \
				[ "$(variable)" = "$${key}" ] && printf '%s\n' "$${value}" ||:; \
			fi \
			;; \
		esac \
	done < "$(file)"
endef

force = $$(while true; do [ $$(ps x |awk 'BEGIN {nargs=split("'"$$*"'",args)} $$field == args[1] { matched=1; for (i=1;i<=NF-field;i++) { if ($$(i+field) == args[i+1]) {matched++} } if (matched == nargs) {found++} } END {print found+0}' field=4) -eq 0 ] && $(ECHO) $(command) || sleep 1; done)

gid = $(shell grep '^$(1):' /etc/group 2>/dev/null |awk -F: '{print $$3}')

##
# function make
## call make with predefined options and variables
    # 1st arg: make command line (targets and arguments)
	# 2nd arg: directory to call make from
	# 3rd arg: list of variables to pass to make (ENV by default)
	# 4th arg: path to .env file with additional arguments to call make with (file must exist when calling make)
	# add list of VARIABLE=VALUE from vars to MAKE_ARGS
	# add list of arguments from file to MAKE_ARGS
	# eval MAKE_DIR option to -C $(2) if $(2) given
	# add current target to MAKE_OLDFILE (list of already fired targets)
	# print command that will be run if VERBOSE mode
	# actually run make command
	# if DRYRUN_RECURSIVE mode, run make command in DRYRUN mode
define make
	$(eval cmd := $(1))
	$(eval dir := $(2))
	$(eval vars := $(3))
	$(eval file := $(4))
	$(if $(vars),$(eval MAKE_ARGS += $(foreach var,$(vars),$(if $($(var)),$(var)='$($(var))'))))
	$(if $(wildcard $(file)),$(eval MAKE_ARGS += $(shell cat $(file) |sed '/^$$/d; /^#/d; /=/!d; s/^[[\s\t]]*//; s/[[\s\t]]*=[[\s\t]]*/=/;' |awk -F '=' '{print $$1"='\''"$$2"'\''"}')))
	$(eval MAKE_DIR := $(if $(dir),-C $(dir)))
	$(eval MAKE_OLDFILE += $(filter-out $(MAKE_OLDFILE), $^))
	$(if $(filter $(VERBOSE),true),printf '${COLOR_GREEN}Running${COLOR_RESET} "'"make $(MAKE_ARGS) $(cmd)"'" $(if $(dir),${COLOR_BLUE}in folder${COLOR_RESET} $(dir) )\n')
	$(ECHO) $(MAKE) $(MAKE_DIR) $(patsubst %,-o %,$(MAKE_OLDFILE)) MAKE_OLDFILE="$(MAKE_OLDFILE)" $(MAKE_ARGS) $(cmd)
	$(if $(filter $(DRYRUN_RECURSIVE),true),$(MAKE) $(MAKE_DIR) $(patsubst %,-o %,$(MAKE_OLDFILE)) MAKE_OLDFILE="$(MAKE_OLDFILE)" DRYRUN=$(DRYRUN) RECURSIVE=$(RECURSIVE) $(MAKE_ARGS) $(cmd))
endef

pop = $(patsubst %$(or $(2),/)$(lastword $(subst $(or $(2),/), ,$(1))),%,$(1))

sed = $(call exec,sed -i $(SED_SUFFIX) '\''$(1)'\'' $(2))

# set ENV=$(env) for target ending with :$(env) and call $* target
define TARGET:ENV
.PHONY: $(TARGET)
$(TARGET): $(ASSIGN_ENV)
$(TARGET): $(ASSIGN_ENV_FILE)
$(TARGET):
	$$(call make,$$*,,ENV_FILE)
endef

# eval each target:$(env) targets
# override value of $(ENV) with $(env)
# override values of .env files with ../$(PARAMETERS)/$(env)/$(APP)/.env file
$(foreach env,$(ENV_LIST),$(eval TARGET := %\:$(env)) $(eval ASSIGN_ENV := ENV:=$(env)) $(eval ASSIGN_ENV_FILE := ENV_FILE+=$(wildcard ../$(PARAMETERS)/$(env)/$(APP)/.env)) $(eval $(TARGET:ENV)))

# set ENV=$(env) for each target ending with @$(env)
$(foreach env,$(ENV_LIST),$(eval %@$(env): ENV:=$(env)))

# Accept arguments for CMDS targets and turn them into do-nothing targets
ifneq ($(filter $(CMDS),$(firstword $(MAKECMDGOALS))),)
ARGS                            := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS                            := $(subst :,\:,$(ARGS))
ARGS                            := $(subst &,\&,$(ARGS))
$(eval $(ARGS):;@:)
endif
