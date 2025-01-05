.DEFAULT_GOAL                   := help
.PHONY: FORCE
comma                           ?= ,
dollar                          ?= $
dquote                          ?= "
lbracket                        ?= (
percent                         ?= %
quote                           ?= '
rbracket                        ?= )
APP                             ?= $(if $(wildcard .git),$(notdir $(CURDIR)))
APP_LOAD                        ?= $(if $(SUBREPO),subrepo) $(if $(filter .,$(MYOS)),myos)
APP_NAME                        ?= $(subst _,,$(subst -,,$(subst .,,$(call LOWERCASE,$(APP)))))
APPS                            ?= $(if $(MONOREPO),$(sort $(patsubst $(MONOREPO_DIR)/%/.git,%,$(wildcard $(MONOREPO_DIR)/*/.git))))
APPS_NAME                       ?= $(foreach app,$(APPS),$(or $(shell awk -F '=' '$$1 == "APP" {print $$2}' $(or $(wildcard $(MONOREPO_DIR)/$(app)/.env),$(wildcard $(MONOREPO_DIR)/$(app)/.env.$(ENV)),$(MONOREPO_DIR)/$(app)/.env.dist) 2>/dev/null),$(app)))
BRANCH                          ?= $(GIT_BRANCH)
CMD_APK_INSTALL                 ?= $(if $(shell type -p apk),apk --no-cache --update add)
CMD_APK_REMOVE                  ?= $(if $(shell type -p apk),apk --no-cache del)
CMD_APT_INSTALL                 ?= $(if $(shell type -p apt-get),apt-get update && apt-get -fy install)
CMD_APT_REMOVE                  ?= $(if $(shell type -p apt-get),apt-get -fy remove)
COLOR_BLUE                      ?= \033[01;34m
COLOR_BROWN                     ?= \033[33m
COLOR_CYAN                      ?= \033[36m
COLOR_DGRAY                     ?= \033[30m
COLOR_ERROR                     ?= $(COLOR_RED)
COLOR_GRAY                      ?= \033[37m
COLOR_GREEN                     ?= \033[32m
COLOR_HIGHLIGHT                 ?= $(COLOR_GREEN)
COLOR_INFO                      ?= $(COLOR_BROWN)
COLOR_RED                       ?= \033[31m
COLOR_RESET                     ?= \033[0m
COLOR_VALUE                     ?= $(COLOR_CYAN)
COLOR_WARNING                   ?= $(COLOR_YELLOW)
COLOR_YELLOW                    ?= \033[01;33m
COMMIT                          ?= $(or $(SUBREPO_COMMIT),$(GIT_COMMIT))
CONFIG                          ?= $(RELATIVE)config
CONFIG_REPOSITORY               ?= $(CONFIG_REPOSITORY_URL)
CONFIG_REPOSITORY_HOST          ?= $(shell printf '$(CONFIG_REPOSITORY_URI)\n' |sed 's|/.*||;s|.*@||')
CONFIG_REPOSITORY_PATH          ?= $(shell printf '$(CONFIG_REPOSITORY_URI)\n' |sed 's|[^/]*/||;')
CONFIG_REPOSITORY_SCHEME        ?= $(shell printf '$(CONFIG_REPOSITORY_URL)\n' |sed 's|://.*||;')
CONFIG_REPOSITORY_URI           ?= $(shell printf '$(CONFIG_REPOSITORY_URL)\n' |sed 's|.*://||;')
CONFIG_REPOSITORY_URL           ?= $(call pop,$(APP_UPSTREAM_REPOSITORY))/$(notdir $(CONFIG))
CONTEXT                         ?= ENV $(shell awk 'BEGIN {FS="="}; $$1 !~ /^(\#|$$)/ {print $$1}' .env.dist 2>/dev/null)
CONTEXT_DEBUG                   ?= MAKEFILE_LIST DOCKER_ENV_ARGS ENV_ARGS APPS GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME MAKE_DIR MAKE_SUBDIRS MAKE_CMD_ARGS MAKE_ENV_ARGS UID USER
DEBUG                           ?= 
DOCKER                          ?= $(shell type -p docker)
DOMAIN                          ?= $(or $(shell dnsdomainname 2>/dev/null),$(shell hostname -d 2>/dev/null),$(shell hostname -f | sed -n 's/[^\.]*\.\([^/ ]*\).*/\1/p'), localhost)
DOMAINNAME                      ?= $(firstword $(DOMAIN))
DRONE                           ?= false
DRYRUN                          ?= false
DRYRUN_RECURSIVE                ?= false
ELAPSED_TIME                     = $(shell $(call TIME))
ENV                             ?= master
ENV_ARGS                        ?= $(env_args)
ENV_FILE                        ?= $(wildcard $(if $(filter-out myos,$(MYOS)),$(MONOREPO_DIR)/.env) $(CONFIG)/$(ENV)/$(APP)/.env .env)
ENV_LIST                        ?= $(shell ls .git/refs/heads/ 2>/dev/null)
ENV_RESET                       ?= false
ENV_VARS                        ?= APP BRANCH DOMAIN DOMAINNAME ENV HOME HOSTNAME GID GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME GROUP MAIL MONOREPO MONOREPO_DIR TAG UID USER VERSION
GID                             ?= $(shell id -g 2>/dev/null)
GIDS                            ?= $(shell id -G 2>/dev/null)
GIT_AUTHOR_EMAIL                ?= $(or $(shell git config user.email 2>/dev/null),$(USER)@$(DOMAINNAME))
GIT_AUTHOR_NAME                 ?= $(or $(shell git config user.name 2>/dev/null),$(USER))
GIT_BRANCH                      ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_COMMIT                      ?= $(shell git rev-parse $(BRANCH) 2>/dev/null)
GIT_REPOSITORY                  ?= $(if $(SUBREPO),$(shell awk -F ' = ' '$$1 ~ /^[[\s\t]]*remote$$/ {print $$2}' .gitrepo 2>/dev/null),$(shell git config --get remote.origin.url 2>/dev/null))
GIT_STATUS                      ?= $(shell git status -uno --porcelain 2>/dev/null |wc -l)
GIT_TAG                         ?= $(shell git tag -l --points-at $(BRANCH) 2>/dev/null)
GIT_UPSTREAM_REPOSITORY         ?= $(if $(GIT_REPOSITORY),$(if $(findstring ://,$(GIT_REPOSITORY)),$(call pop,$(call pop,$(GIT_REPOSITORY)))/,$(call pop,$(GIT_REPOSITORY),:):)$(or $(GIT_UPSTREAM_USER),$(GIT_USER))/$(lastword $(subst /, ,$(GIT_REPOSITORY))))
GIT_UPSTREAM_USER               ?= $(lastword $(subst /, ,$(call pop,$(MYOS_REPOSITORY))))
GIT_USER                        ?= $(USER)
GIT_VERSION                     ?= $(shell git describe --tags $(BRANCH) 2>/dev/null || git rev-parse $(BRANCH) 2>/dev/null)
GROUP                           ?= $(shell id -ng 2>/dev/null)
HOST                            ?= $(patsubst %,$(HOSTNAME).%,$(DOMAIN))
HOSTNAME                        ?= $(call LOWERCASE,$(shell hostname 2>/dev/null |sed 's/\..*//'))
IGNORE_DRYRUN                   ?= false
IGNORE_VERBOSE                  ?= false
INSTALL                         ?= $(RUN) $(SUDO) $(subst &&,&& $(RUN) $(SUDO),$(INSTALL_CMD))
INSTALL_CMDS                    ?= APK_INSTALL APT_INSTALL
$(foreach cmd,$(INSTALL_CMDS),$(if $(CMD_$(cmd)),$(eval INSTALL_CMD ?= $(CMD_$(cmd)))))
LOG_LEVEL                       ?= $(if $(DEBUG),debug,$(if $(VERBOSE),info,error))
MAIL                            ?= $(GIT_AUTHOR_EMAIL)
MAKE_ARGS                        = $(foreach var,$(MAKE_VARS),$(if $($(var)),$(var)='$($(var))'))
MAKE_SUBDIRS                    ?= $(if $(filter myos,$(MYOS)),monorepo,$(if $(APP),apps $(foreach type,$(APP_LOAD),$(if $(wildcard $(MAKE_DIR)/apps/$(type)),apps/$(type)))))
MAKE_CMD_ARGS                   ?= $(foreach var,$(MAKE_CMD_VARS),$(var)='$($(var))')
MAKE_CMD_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter command\ line,$(origin $(var))),$(var))))
MAKE_ENV_ARGS                   ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_ENV_VARS)),$(var)='$($(var))')
MAKE_ENV_VARS                   ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter environment,$(origin $(var))),$(var))))
MAKE_FILE_ARGS                  ?= $(foreach var,$(filter $(ENV_VARS),$(MAKE_FILE_VARS)),$(var)='$($(var))')
MAKE_FILE_VARS                  ?= $(strip $(foreach var, $(filter-out .VARIABLES,$(.VARIABLES)), $(if $(filter file,$(origin $(var))),$(var))))
MAKE_OLDFILE                    ?= $@
MAKE_TARGETS                    ?= $(filter-out $(.VARIABLES),$(shell $(MAKE) -qp 2>/dev/null |awk -F':' '/^[a-zA-Z0-9][^$$\#\/\t=]*:([^=]|$$)/ {print $$1}' 2>/dev/null |sort -u))
MAKE_UNIXTIME_START             := $(shell date -u +'%s' 2>/dev/null)
MAKE_UNIXTIME_CURRENT            = $(shell date -u "+%s" 2>/dev/null)
MAKE_VARS                       := ENV COMPOSE_FILE DOCKER_COMPOSE DOCKER_MACHINE DOCKER_SERVICES DOCKER_SYSTEM
MAKECMDARGS                     ?= apps-install install-app
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
STATUS                          ?= $(GIT_STATUS)
SUBREPO                         ?= $(if $(wildcard .gitrepo),$(notdir $(CURDIR)))
SUDO                            ?= $(if $(filter-out 0,$(UID)),$(shell type -p sudo))
TAG                             ?= $(GIT_TAG)
UID                             ?= $(shell id -u 2>/dev/null)
USER                            ?= $(shell id -nu 2>/dev/null)
VERSION                         ?= $(GIT_VERSION)

ifneq ($(DEBUG),)
CONTEXT                         += $(CONTEXT_DEBUG)
else
.SILENT:
endif

# Guess RUN
ifeq ($(DRYRUN),true)
RUN                              = $(if $(filter-out true,$(IGNORE_DRYRUN)),echo)
ifeq ($(RECURSIVE), true)
DRYRUN_RECURSIVE                := true
endif
endif

# Guess OS
ifeq ($(OSTYPE),cygwin)
SYSTEM                          ?= cygwin
else ifeq ($(OS),Windows_NT)
SYSTEM                          ?= Windows_NT
else
SYSTEM                          ?= $(shell uname -s 2>/dev/null)
endif
MACHINE                         ?= $(shell uname -m 2>/dev/null)

ifeq ($(SYSTEM),Darwin)
SED_SUFFIX                      := ''
STAT_FORMAT_ARG                 := -f
STAT_FORMAT_FILE                := '%a %N'
else
STAT_FORMAT_ARG                 := -c
STAT_FORMAT_FILE                := '%Y %n'
endif

# include .env files
include $(wildcard $(ENV_FILE))

ERROR_FD := 2
# macro ERROR: print colorized warning
ERROR = \
printf '${COLOR_ERROR}ERROR:${COLOR_RESET} ${COLOR_INFO}$(APP)${COLOR_RESET}[${COLOR_VALUE}$(MAKELEVEL)${COLOR_RESET}]$(if $@, ${COLOR_VALUE}$@${COLOR_RESET}):${COLOR_RESET} ' >&$(ERROR_FD) \
  $(if $(2), \
    && printf '$(1) ${COLOR_HIGHLIGHT}$(2)${COLOR_RESET}' >&$(ERROR_FD) \
    $(if $(3),&& printf ' $(3)$(if $(4), ${COLOR_VALUE}$(4)${COLOR_RESET})' >&$(ERROR_FD)) \
  , \
    && $(strip $(call PRINTF,$(1)) >&$(ERROR_FD)) \
  ) \
 && printf '\n' >&$(ERROR_FD) \
 && exit 2

INFO_FD := 2
# macro INFO: print colorized info
INFO = $(if $(VERBOSE),$(if $(filter-out true,$(IGNORE_VERBOSE)), \
  printf '${COLOR_INFO}$(APP)${COLOR_RESET}[${COLOR_VALUE}$(MAKELEVEL)${COLOR_RESET}]$(if $@, ${COLOR_VALUE}$@${COLOR_RESET}):${COLOR_RESET} ' >&$(INFO_FD) \
  $(if $(2), \
    && printf 'Calling ${COLOR_HIGHLIGHT}$(1)${COLOR_RESET}$(lbracket)' >&$(INFO_FD) \
    && $(or $(strip $(call PRINTF,$(2))),printf '$(2)') >&$(INFO_FD) \
    && printf '$(rbracket)' >&$(INFO_FD) \
    $(if $(3),&& printf ' ${COLOR_VALUE}in${COLOR_RESET} $(3)' >&$(INFO_FD)) \
  , \
    && $(strip $(call PRINTF,$(1)) >&$(INFO_FD)) \
  ) \
 && printf '\n' >&$(INFO_FD) \
))

# macro RESU: Print USER associated to MAIL
RESU = $(strip \
 $(if $(findstring @,$(MAIL)), \
  $(eval user          := $(call LOWERCASE,$(subst +,.,$(subst _,.,$(shell printf '$(MAIL)' |awk -F "@" '{print $$1}'))))) \
  $(eval domain        := $(call LOWERCASE,$(subst +,.,$(subst _,.,$(shell printf '$(MAIL)' |awk -F "@" '{print $$NF}'))))) \
  $(if $(domain), \
    $(eval mail        := $(call LOWERCASE,$(subst +,.,$(subst _,.,$(MAIL))))) \
    $(eval niamod      := $(subst $(space),.,$(strip $(call reverse,$(subst ., ,$(domain)))))) \
    $(eval resu        := $(subst $(space),.,$(strip $(call reverse,$(subst ., ,$(user)))))) \
    $(eval resu.niamod := $(niamod).$(resu)) \
    $(eval resu.path   := $(subst .,/,$(resu.niamod))) \
    $(eval user.domain := $(user).$(domain)) \
    $(user.domain) \
  , $(USER) \
  ) \
 , $(USER) \
 ) \
)

# macro TIME: Print time elapsed since unixtime 1
TIME = awk '{printf "%02d:%02d:%02d\n",int($$1/3600),int(($$1%3600)/60),int($$1%60)}' \
	   <<< $(shell awk 'BEGIN {current=$(or $(2),$(MAKE_UNIXTIME_CURRENT)); start=$(or $(1),$(MAKE_UNIXTIME_START)); print (current  - start)}' 2>/dev/null)

WARNING_FD := 2
# macro WARNING: print colorized warning
WARNING = \
printf '${COLOR_WARNING}WARNING:${COLOR_RESET} ${COLOR_INFO}$(APP)${COLOR_RESET}[${COLOR_VALUE}$(MAKELEVEL)${COLOR_RESET}]$(if $@, ${COLOR_VALUE}$@${COLOR_RESET}):${COLOR_RESET} ' >&$(WARNING_FD) \
  $(if $(2), \
    && printf '$(1) ${COLOR_HIGHLIGHT}$(2)${COLOR_RESET}' >&$(WARNING_FD) \
    $(if $(3),&& printf ' $(3)$(if $(4), ${COLOR_VALUE}$(4)${COLOR_RESET})' >&$(WARNING_FD)) \
  , \
    && $(strip $(call PRINTF,$(1)) >&$(WARNING_FD)) \
  ) \
 && printf '\n' >&$(WARNING_FD)

# macro force: Run command 1 sine die
## it starts command 1 if it is not already running
## it returns never
force = $$(while true; do \
 [ $$(ps x |awk '\
  BEGIN {nargs=split("'"$$*"'",args)} \
  $$field == args[1] { \
   matched=1; \
   for (i=1;i<=NF-field;i++) { \
    if ($$(i+field) == args[i+1]) {matched++} \
   } \
   if (matched == nargs) {found++} \
  } \
  END {print found+0}' field=4) -eq 0 \
 ] \
 && $(RUN) $(1) || sleep 1; done \
)

# macro gid: Return GID of group 1
gid = $(shell awk -F':' '$$1 == "$(1)" {print $$3}' /etc/group 2>/dev/null)

# macro newer: Return the newest file
newer = $(shell stat $(STAT_FORMAT_ARG) $(STAT_FORMAT_FILE) $(1) $(2) $(if $(DEBUG),,2>/dev/null) |sort -n |tail -n1 |awk '{print $$2}')

# older newer: Return the oldest file
older = $(shell stat $(STAT_FORMAT_ARG) $(STAT_FORMAT_FILE) $(1) $(2) $(if $(DEBUG),,2>/dev/null) |sort -n |head -n1 |awk '{print $$2}')

# macro pop: Return last word of string 1 according to separator 2
pop = $(patsubst %$(or $(2),/)$(lastword $(subst $(or $(2),/), ,$(1))),%,$(1))

# macro sed: Run sed script 1 on file 2
sed = $(RUN) sed -i $(SED_SUFFIX) '$(1)' $(2)

# macro verle: Return true when version 1 <= 2
verle = [ -n "$(1)" ] && [ "$(1)" = "$(shell echo -e "$(1)\n$(2)" |sort -V |head -n1)" ]

# macro verlt: Return true when version 1 < 2
verlt = [ "$(1)" = "$(2)" ] && return 1 || $(call verlte,$(1),$(2))

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

# function env-exec: Exec arg 1 with env
define env-exec
	$(call INFO,env-exec,$(1))
	IFS=$$'\n'; env $(env_reset) $(env_args) $(1)
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
