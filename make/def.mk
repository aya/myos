comma                           ?= ,
dollar                          ?= $
dquote                          ?= "
quote                           ?= '
APP                             ?= $(if $(wildcard .git),$(if $(wildcard */.gitrepo),,$(notdir $(CURDIR))),$(notdir $(CURDIR)))
APP_DIR                         ?= $(if $(APP),$(CURDIR))
BRANCH                          ?= $(shell git rev-parse --abbrev-ref HEAD)
CMDS                            ?= exec exec:% exec@% run run:% run@%
COMMIT                          ?= $(shell git rev-parse $(BRANCH) 2>/dev/null)
CONTEXT                         ?= $(shell awk 'BEGIN {FS="="}; $$1 !~ /^(\#|$$)/ {print $$1}' .env.dist 2>/dev/null) BRANCH ENV_FILE UID USER VERSION
DEBUG                           ?= false
DOCKER                          ?= true
DRONE                           ?= false
DRYRUN                          ?= false
DRYRUN_IGNORE                   ?= false
DRYRUN_RECURSIVE                ?= false
ENV                             ?= local
ENV_DEPLOY                      ?= preprod prod
ENV_FILE                        ?= $(wildcard ../$(PARAMETERS)/$(ENV)/$(APP)/.env) .env
ENV_LIST                        ?= local dev tests preprod prod
ENV_RESET                       ?= false
ENV_VARS                        ?= APP APP_DIR BRANCH ENV HOSTNAME GID MONOREPO MONOREPO_DIR TAG UID USER VERSION
GID                             ?= $(shell id -g)
GIT_PARAMETERS_REPOSITORY       ?= $(call pop,$(GIT_UPSTREAM_REPOSITORY))/$(PARAMETERS)
GIT_REPOSITORY                  ?= $(if $(SUBREPO),$(shell awk -F ' = ' '$$1 ~ /^[[\s\t]]*remote$$/ {print $$2}' .gitrepo),$(shell git config --get remote.origin.url))
GIT_UPSTREAM_REPOSITORY         ?= $(if $(findstring ://,$(GIT_REPOSITORY)),$(call pop,$(call pop,$(GIT_REPOSITORY)))/,$(call pop,$(GIT_REPOSITORY),:):)$(GIT_UPSTREAM_USER)/$(lastword $(subst /, ,$(GIT_REPOSITORY)))
GIT_UPSTREAM_USER               ?= $(MONOREPO)
HOSTNAME                        ?= $(shell hostname |sed 's/\..*//')
MAKE_ARGS                       ?= $(foreach var,$(MAKE_VARS),$(if $($(var)),$(var)='$($(var))'))
MAKE_VARS                       ?= ENV
MAKECMDVARS                     ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter command\ line,$(origin $(var))),$(var))))
MAKECMDARGS                     ?= $(foreach var,$(MAKECMDVARS),$(var)='$($(var))')
MAKETARGETS                     ?= $(filter-out $(.VARIABLES),$(shell $(MAKE) -qp |awk -F':' '/^[a-zA-Z0-9][^$$\#\/\t=]*:([^=]|$$)/ {print $$1}' |sort -u))
MONOREPO                        ?= $(if $(wildcard .git),$(if $(wildcard */.gitrepo),$(notdir $(CURDIR))),$(if $(SUBREPO),$(notdir $(realpath $(CURDIR)/..))))
MONOREPO_DIR                    ?= $(if $(wildcard .git),$(if $(wildcard */.gitrepo),$(CURDIR)),$(if $(SUBREPO),$(realpath $(CURDIR)/..)))
PARAMETERS                      ?= parameters
RECURSIVE                       ?= true
SHARED                          ?= shared
SUBREPO                         ?= $(if $(wildcard .gitrepo),$(notdir $(CURDIR)))
SUBREPO_DIR                     ?= $(if $(SUBREPO),$(CURDIR))
SUBREPO_COMMIT                  ?= $(if $(SUBREPO),$(shell git rev-parse subrepo/$(SUBREPO)/$(BRANCH) 2>/dev/null))
TAG                             ?= $(shell git tag -l --points-at $(BRANCH) 2>/dev/null)
UID                             ?= $(shell id -u)
USER                            ?= $(shell id -nu)
VERBOSE                         ?= true
VERSION                         ?= $(shell git describe --tags $(BRANCH) 2>/dev/null || git rev-parse $(BRANCH) 2>/dev/null)

ifeq ($(DOCKER), true)
ENV_ARGS                         = $(foreach var,$(ENV_VARS),$(if $($(var)),-e $(var)='$($(var))')) $(shell printenv |awk -F '=' 'NR == FNR { if($$1 !~ /^(\#|$$)/) { A[$$1]; next } } ($$1 in A) {print "-e "$$0}' .env.dist - 2>/dev/null)
else
ENV_ARGS                         = $(foreach var,$(ENV_VARS),$(if $($(var)),$(var)='$($(var))')) $(shell printenv |awk -F '=' 'NR == FNR { if($$1 !~ /^(\#|$$)/) { A[$$1]; next } } ($$1 in A)' .env.dist - 2>/dev/null)
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

ifneq ($(DEBUG), true)
.SILENT:
endif
ifeq ($(DRYRUN), true)
ECHO                             = $(if $(filter $(DRYRUN_IGNORE),true),,printf '${COLOR_BROWN}$(APP)${COLOR_RESET}[${COLOR_GREEN}$(MAKELEVEL)${COLOR_RESET}] ${COLOR_BLUE}$@${COLOR_RESET}:${COLOR_RESET} '; echo)
ifeq ($(RECURSIVE), true)
DRYRUN_RECURSIVE                := true
endif
endif

ifeq ($(HOST_SYSTEM),DARWIN)
define getent-group
$(shell dscl . -read /Groups/$(1) 2>/dev/null |awk '$$1 == "PrimaryGroupID:" {print $$2}')
endef
ifneq ($(DOCKER),true)
SED_SUFFIX='\'\''
endif
else
define getent-group
$(shell getent group $(1) 2>/dev/null |awk -F: '{print $$3}')
endef
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

define force
	while true; do [ $$(ps x |awk 'BEGIN {nargs=split("'"$$*"'",args)} $$field == args[1] { matched=1; for (i=1;i<=NF-field;i++) { if ($$(i+field) == args[i+1]) {matched++} } if (matched == nargs) {found++} } END {print found+0}' field=4) -eq 0 ] && $(ECHO) $(1) || sleep 1; done
endef

pop = $(patsubst %$(or $(2),/)$(lastword $(subst $(or $(2),/), ,$(1))),%,$(1))

define sed
$(call exec,sed -i $(SED_SUFFIX) '\''$(1)'\'' $(2))
endef

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

ifneq ($(MONOREPO),)
ifneq ($(wildcard .gitrepo),)
INFRA                           := ../infra
MAKE_SUBDIRS                    := subrepo
else
INFRA                           := infra
MAKE_SUBDIRS                    := monorepo
endif
endif

ifneq ($(APP),)
MAKE_SUBDIRS                    += apps $(foreach type,$(APP_TYPE),$(if $(wildcard $(MAKE_DIR)/apps/$(type)),apps/$(type)))
endif

# include .env files
include $(wildcard $(ENV_FILE))
# include variables definitions
include $(wildcard $(MAKE_DIR)/def.*.mk)
include $(foreach subdir,$(MAKE_SUBDIRS),$(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk))

# set ENV=$(env) for each target ending with :$(env) and call $* target
# set ../$(PARAMETERS)/$(env)/$(APP)/.env as last .env readed file to override values of .env file
define TARGET:ENV
.PHONY: $(TARGET)
$(TARGET): $(ASSIGN_ENV)
$(TARGET): $(ASSIGN_ENV_FILE)
$(TARGET):
	$$(call make,$$*,,ENV_FILE)
endef
$(foreach env,$(ENV_LIST),$(eval TARGET := %\:$(env)) $(eval ASSIGN_ENV := ENV:=$(env)) $(eval ASSIGN_ENV_FILE := ENV_FILE+=$(wildcard ../$(PARAMETERS)/$(env)/$(APP)/.env)) $(eval $(TARGET:ENV)))

# set ENV=$(env) for each target ending with @$(env)
$(foreach env,$(ENV_LIST),$(eval %@$(env): ENV:=$(env)))

# Accept arguments for CMDS targets
ifneq ($(filter $(CMDS),$(firstword $(MAKECMDGOALS))),)
# set $ARGS with following arguments
ARGS                            := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS                            := $(subst :,\:,$(ARGS))
ARGS                            := $(subst &,\&,$(ARGS))
# ...and turn them into do-nothing targets
$(eval $(ARGS):;@:)
endif
