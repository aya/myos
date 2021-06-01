##
# HELP

.DEFAULT_GOAL                   := help
COLOR_RESET                     ?= \033[0m
COLOR_GREEN                     ?= \033[32m
COLOR_BROWN                     ?= \033[33m
COLOR_BLUE                      ?= \033[36m
.PHONY: FORCE

# target blank1 blank2: Print new line
.PHONY: blank1 blank2
blank1 blank2:
	printf "\n"

# target context: Call context-% for each CONTEXT
.PHONY: context
context:
	printf "${COLOR_BROWN}Context:${COLOR_RESET}\n"
	$(MAKE) $(foreach var,$(CONTEXT),$(if $($(var)),context-$(var))) FORCE

# target context-%: Print % value
.PHONY: context-%
context-%:
	printf "${COLOR_BLUE}%-37s${COLOR_RESET}" $*
	printf "${COLOR_GREEN}"
	$(call PRINTF,$($*))
	printf "${COLOR_RESET}"

# target doc: Fire functions macros target variables
doc: functions macros targets variables ;

# target doc: Fire functions-% macros-% target-% variables-%
doc-%: functions-% macros-% targets-% variables-%;

# target help: Fire usage blank1 target blank2 context
.PHONY: help
help: usage blank1 target blank2 context ## This help

# target functions: Fire functions-.
.PHONY: functions
functions: functions-.

# target functions-%: Print documented functions starting with %
.PHONY: functions-%
functions-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# function $*.*:.*$$/ {printf "${COLOR_BLUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target macros: Fire macros-.
.PHONY: macros
macros: macros-.

# target macros-%: Print documented macros starting with %
.PHONY: macros-%
macros-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# macro $*.*:.*$$/ {printf "${COLOR_BLUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target target: Show common targets
.PHONY: target
target:
	printf "${COLOR_BROWN}Targets:${COLOR_RESET}\n"
	awk 'BEGIN {FS = ":.*?## "}; $$0 ~ /^[a-zA-Z_-]+:.*?## .*$$/ {printf "${COLOR_BLUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target targets: Fire targets-.
.PHONY: targets
targets: targets-.

# target targets-%: Print documented targets
.PHONY: targets-%
targets-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# target $*.*:.*$$/ {printf "${COLOR_BLUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target usage: Print Usage
.PHONY: usage
usage:
	printf "${COLOR_BROWN}Usage:${COLOR_RESET}\n"
	printf "make [target]\n"

# target variables: Fire variables-.
.PHONY: variables
variables: variables-.

# target variables-%: Show documented variables
.PHONY: variables-%
variables-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# variable $*.*:.*$$/ {printf "${COLOR_BLUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)
