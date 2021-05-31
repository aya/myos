.DEFAULT_GOAL                   := help
COLOR_RESET                     ?= \033[0m
COLOR_GREEN                     ?= \033[32m
COLOR_BROWN                     ?= \033[33m
COLOR_BLUE                      ?= \033[36m

##
# HELP

.PHONY: help
help: usage blank1 target blank2 context ## This help

.PHONY: usage
usage:
	printf "${COLOR_BROWN}Usage:${COLOR_RESET}\n"
	printf "make [target]\n"

.PHONY: blank1 blank2
blank1 blank2:
	printf "\n"

.PHONY: target
## Show available targets
target:
	printf "${COLOR_BROWN}Targets:${COLOR_RESET}\n"
	awk 'BEGIN {FS = ":.*?## "}; $$0 ~ /^[a-zA-Z_-]+:.*?## .*$$/ {printf "${COLOR_BLUE}%-31s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: context
## Show current context
context:
	printf "${COLOR_BROWN}Context:${COLOR_RESET}\n"
	$(MAKE) $(foreach var,$(CONTEXT),$(if $($(var)),context-$(var))) FORCE

.PHONY: context-%
context-%:
	printf "${COLOR_BLUE}%-31s${COLOR_RESET}" $*
	printf "${COLOR_GREEN}"
	$(call PRINTF,$($*))
	printf "${COLOR_RESET}"
