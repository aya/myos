comma                           ?= ,
dollar                          ?= $
dquote                          ?= "
quote                           ?= '
lbracket                        ?= (
rbracket                        ?= )
APP                             ?= $(if $(wildcard .git),$(notdir $(CURDIR)))
APP_NAME                        ?= $(APP)
APP_TYPE                        ?= $(if $(SUBREPO),subrepo) $(if $(filter .,$(MYOS)),myos)
APPS                            ?= $(if $(MONOREPO),$(sort $(patsubst $(MONOREPO_DIR)/%/.git,%,$(wildcard $(MONOREPO_DIR)/*/.git))))
APPS_NAME                       ?= $(foreach app,$(APPS),$(or $(shell awk -F '=' '$$1 == "APP" {print $$2}' $(or $(wildcard $(MONOREPO_DIR)/$(app)/.env),$(wildcard $(MONOREPO_DIR)/$(app)/.env.$(ENV)),$(MONOREPO_DIR)/$(app)/.env.dist) 2>/dev/null),$(app)))
BRANCH                          ?= $(GIT_BRANCH)
CMDS                            ?= exec exec:% exec@% install-app install-apps run run:% run@%
COMMIT                          ?= $(or $(SUBREPO_COMMIT),$(GIT_COMMIT))
CONFIG                          ?= $(RELATIVE)config
CONFIG_REPOSITORY               ?= $(call pop,$(or $(APP_UPSTREAM_REPOSITORY),$(GIT_UPSTREAM_REPOSITORY)))/$(notdir $(CONFIG))
CONTEXT                         ?= $(if $(APP),APP BRANCH DOMAIN VERSION) $(shell awk 'BEGIN {FS="="}; $$1 !~ /^(\#|$$)/ {print $$1}' .env.dist 2>/dev/null)
CONTEXT_DEBUG                   ?= MAKEFILE_LIST env env.docker APPS GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME LOG_LEVEL MAKE_DIR MAKE_SUBDIRS MAKE_CMD_ARGS MAKE_ENV_ARGS MONOREPO_DIR UID USER
DEBUG                           ?= 
DOCKER                          ?= $(if $(BUILD),false,true)
DOMAIN                          ?= localhost
DRONE                           ?= false
DRYRUN                          ?= false
DRYRUN_RECURSIVE                ?= false
ELAPSED_TIME                     = $(shell $(call TIME))
ENV                             ?= local
ENV_FILE                        ?= $(wildcard $(CONFIG)/$(ENV)/$(APP)/.env .env)
ENV_LIST                        ?= $(shell ls .git/refs/heads/ 2>/dev/null)
ENV_RESET                       ?= false
ENV_VARS                        ?= APP BRANCH DOMAIN ENV HOSTNAME GID GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME MONOREPO MONOREPO_DIR TAG UID USER VERSION
GID                             ?= $(shell id -g 2>/dev/null)
GIT_AUTHOR_EMAIL                ?= $(or $(shell git config user.email 2>/dev/null),$(USER)@my.os)
GIT_AUTHOR_NAME                 ?= $(or $(shell git config user.name 2>/dev/null),$(USER))
GIT_BRANCH                      ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_COMMIT                      ?= $(shell git rev-parse $(BRANCH) 2>/dev/null)
GIT_REPOSITORY                  ?= $(if $(SUBREPO),$(shell awk -F ' = ' '$$1 ~ /^[[\s\t]]*remote$$/ {print $$2}' .gitrepo 2>/dev/null),$(shell git config --get remote.origin.url 2>/dev/null))
GIT_TAG                         ?= $(shell git tag -l --points-at $(BRANCH) 2>/dev/null)
GIT_UPSTREAM_REPOSITORY         ?= $(if $(findstring ://,$(GIT_REPOSITORY)),$(call pop,$(call pop,$(GIT_REPOSITORY)))/,$(call pop,$(GIT_REPOSITORY),:):)$(GIT_UPSTREAM_USER)/$(lastword $(subst /, ,$(GIT_REPOSITORY)))
GIT_UPSTREAM_USER               ?= $(lastword $(subst /, ,$(call pop,$(MYOS_REPOSITORY))))
GIT_VERSION                     ?= $(shell git describe --tags $(BRANCH) 2>/dev/null || git rev-parse $(BRANCH) 2>/dev/null)
HOSTNAME                        ?= $(shell hostname 2>/dev/null |sed 's/\..*//')
IGNORE_DRYRUN                   ?= false
IGNORE_VERBOSE                  ?= $(IGNORE_DRYRUN)
LOG_LEVEL                       ?= $(if $(DEBUG),debug,$(if $(VERBOSE),info,error))
MAKE_ARGS                       ?= $(foreach var,$(MAKE_VARS),$(if $($(var)),$(var)='$($(var))'))
MAKE_SUBDIRS                    ?= $(if $(filter myos,$(MYOS)),monorepo,$(if $(APP),apps $(foreach type,$(APP_TYPE),$(if $(wildcard $(MAKE_DIR)/apps/$(type)),apps/$(type)))))
MAKE_CMD_ARGS                   ?= $(foreach var,$(MAKE_CMD_VARS),$(var)='$($(var))')
MAKE_CMD_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter command\ line,$(origin $(var))),$(var))))
MAKE_ENV_ARGS                   ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_ENV_VARS)),$(var)='$($(var))')
MAKE_ENV_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter environment,$(origin $(var))),$(var))))
MAKE_FILE_ARGS                  ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_FILE_VARS)),$(var)='$($(var))')
MAKE_FILE_VARS                  ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter file,$(origin $(var))),$(var))))
MAKE_OLDFILE                    ?= $@
MAKE_TARGETS                    ?= $(filter-out $(.VARIABLES),$(shell $(MAKE) -qp 2>/dev/null |awk -F':' '/^[a-zA-Z0-9][^$$\#\/\t=]*:([^=]|$$)/ {print $$1}' |sort -u))
MAKE_UNIXTIME_START             := $(shell date -u +'%s' 2>/dev/null)
MAKE_UNIXTIME_CURRENT            = $(shell date -u "+%s" 2>/dev/null)
MAKE_VARS                       ?= ENV
MONOREPO                        ?= $(if $(filter myos,$(MYOS)),$(notdir $(CURDIR)),$(if $(APP),$(notdir $(realpath $(CURDIR)/..))))
MONOREPO_DIR                    ?= $(if $(MONOREPO),$(if $(filter myos,$(MYOS)),$(realpath $(CURDIR)),$(if $(APP),$(realpath $(CURDIR)/..))))
MYOS                            ?= $(if $(filter $(MAKE_DIR),$(call pop,$(MAKE_DIR))),.,$(call pop,$(MAKE_DIR)))
MYOS_COMMIT                     ?= $(shell GIT_DIR=$(MYOS)/.git git rev-parse head 2>/dev/null)
MYOS_REPOSITORY                 ?= $(shell GIT_DIR=$(MYOS)/.git git config --get remote.origin.url 2>/dev/null)
QUIET                           ?= $(if $(VERBOSE),,--quiet)
RECURSIVE                       ?= true
RELATIVE                        ?= $(if $(filter myos,$(MYOS)),./,../)
SHARED                          ?= $(RELATIVE)shared
SSH_DIR                         ?= ${HOME}/.ssh
SUBREPO                         ?= $(if $(wildcard .gitrepo),$(notdir $(CURDIR)))
TAG                             ?= $(GIT_TAG)
UID                             ?= $(shell id -u 2>/dev/null)
USER                            ?= $(shell id -nu 2>/dev/null)
VERBOSE                         ?= $(if $(DEBUG),true)
VERSION                         ?= $(GIT_VERSION)

ifeq ($(DOCKER), true)
ENV_ARGS                         = $(env.docker.args) $(env.docker.dist)
else
ENV_ARGS                         = $(env.args) $(env.dist)
endif

ifneq ($(DEBUG),)
CONTEXT                         += $(CONTEXT_DEBUG)
else
.SILENT:
endif

ifeq ($(DRYRUN),true)
RUN                              = $(if $(filter-out true,$(IGNORE_DRYRUN)),echo)
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

# function conf: Extract variable=value line from configuration files
## it prints the line with variable 3 definition from block 2 in file 1
define conf
	$(call INFO,conf,$(1)$(comma) $(2)$(comma) $(3))
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

# macro force: Run command 1 sine die
## it starts command 1 if it is not already running
## it returns never
force = $$(while true; do [ $$(ps x |awk 'BEGIN {nargs=split("'"$$*"'",args)} $$field == args[1] { matched=1; for (i=1;i<=NF-field;i++) { if ($$(i+field) == args[i+1]) {matched++} } if (matched == nargs) {found++} } END {print found+0}' field=4) -eq 0 ] && $(RUN) $(1) || sleep 1; done)

# macro gid: Return GID of group 1
gid = $(shell grep '^$(1):' /etc/group 2>/dev/null |awk -F: '{print $$3}')

# macro INFO: customized info
INFO = $(if $(VERBOSE),$(if $(filter-out true,$(IGNORE_VERBOSE)),printf '${COLOR_BROWN}$(APP)${COLOR_RESET}[${COLOR_GREEN}$(MAKELEVEL)${COLOR_RESET}] ${COLOR_BLUE}$@${COLOR_RESET}:${COLOR_RESET} ${COLOR_GREEN}Calling${COLOR_RESET} $(1)$(if $(2),$(lbracket)$(2)$(rbracket)) $(if $(3),${COLOR_BLUE}in folder${COLOR_RESET} $(3) )\n' >&2))

# function install-app: Exec 'git clone url 1 dir 2' or Call update-app with url 1 dir 2
define install-app
	$(call INFO,install-app,$(1)$(comma) $(2))
	$(eval url := $(or $(1), $(APP_REPOSITORY)))
	$(eval dir := $(or $(2), $(RELATIVE)$(lastword $(subst /, ,$(url)))))
	$(if $(wildcard $(dir)/.git), \
		$(call update-app,$(url),$(dir)), \
		$(call exec,$(RUN) git clone $(QUIET) $(url) $(dir)) \
	)
endef

# function make: Call make with predefined options and variables
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
	$(call INFO,make,$(MAKE_ARGS) $(cmd),$(dir))
	$(RUN) $(MAKE) $(MAKE_DIR) $(patsubst %,-o %,$(MAKE_OLDFILE)) MAKE_OLDFILE="$(MAKE_OLDFILE)" $(MAKE_ARGS) $(cmd)
	$(if $(filter true,$(DRYRUN_RECURSIVE)),$(MAKE) $(MAKE_DIR) $(patsubst %,-o %,$(MAKE_OLDFILE)) MAKE_OLDFILE="$(MAKE_OLDFILE)" DRYRUN=$(DRYRUN) RECURSIVE=$(RECURSIVE) $(MAKE_ARGS) $(cmd))
endef

# macro pop: Return last word of string 1 according to separator 2
pop = $(patsubst %$(or $(2),/)$(lastword $(subst $(or $(2),/), ,$(1))),%,$(1))

# macro sed: Exec sed script 1 on file 2
sed = $(call exec,sed -i $(SED_SUFFIX) '\''$(1)'\'' $(2))

# macro TIME: Print time elapsed since unixtime 1
TIME = awk '{printf "%02d:%02d:%02d\n",int($$1/3600),int(($$1%3600)/60),int($$1%60)}' \
	   <<< $(shell bc <<< "$(or $(2),$(MAKE_UNIXTIME_CURRENT))-$(or $(1),$(MAKE_UNIXTIME_START))" 2>/dev/null)

# function update-app: Exec 'cd dir 1 && git pull' or Call install-app
define update-app
	$(call INFO,update-app,$(1)$(comma) $(2))
	$(eval url := $(or $(1), $(APP_REPOSITORY)))
	$(eval dir := $(or $(2), $(APP_DIR)))
	$(if $(wildcard $(dir)/.git), \
		$(call exec,cd $(dir) && $(RUN) git pull $(QUIET)), \
		$(call install-app,$(url),$(dir)) \
	)
endef

# function TARGET:ENV: Create a new target ending with :env
## it sets ENV, ENV_FILE and calls original target
define TARGET:ENV
.PHONY: $(TARGET)
$(TARGET): $(ASSIGN_ENV)
$(TARGET): $(ASSIGN_ENV_FILE)
$(TARGET):
	$$(call make,$$*,,ENV_FILE)
endef

# set ENV=env for targets ending with :env
## for each env in ENV_LIST
##  it overrides value of ENV with env
##  it adds $(CONFIG)/$(env)/$(APP)/.env file to ENV_FILE
##  it evals TARGET:ENV
$(foreach env,$(ENV_LIST),$(eval TARGET := %\:$(env)) $(eval ASSIGN_ENV := ENV:=$(env)) $(eval ASSIGN_ENV_FILE := ENV_FILE+=$(wildcard $(CONFIG)/$(env)/$(APP)/.env)) $(eval $(TARGET:ENV)))

# set ENV=env for targets ending with @env
$(foreach env,$(ENV_LIST),$(eval %@$(env): ENV:=$(env)))

# Accept arguments for CMDS targets and turn them into do-nothing targets
ifneq ($(filter $(CMDS),$(firstword $(MAKECMDGOALS))),)
ARGS                            := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS                            := $(subst :,\:,$(ARGS))
ARGS                            := $(subst &,\&,$(ARGS))
$(eval $(ARGS):;@:)
endif
