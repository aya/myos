##
# HELP

# target blank1 blank2: Print new line
.PHONY: blank1 blank2
blank1 blank2:
	printf "\n"

# target context: Print Context and Call contexts target
.PHONY: context
context:
	@printf "${COLOR_INFO}Context:${COLOR_RESET}\n"
	$(MAKE) contexts

# target context: Fire context-% target for each CONTEXT
.PHONY: contexts
contexts: $(foreach var,$(CONTEXT),context-$(var))

# target context-% print-%: Print % value
.PHONY: context-% print-%
context-% print-%: stack
	@printf "${COLOR_HIGHLIGHT}%-37s${COLOR_RESET}" $*
	@printf "${COLOR_VALUE}"
	@$(call PRINTF,$($*))
	@printf "${COLOR_RESET}\n"

# target doc: Fire functions macros target variables
doc: functions macros targets variables ;

# target doc-%: Fire functions-% macros-% target-% variables-%
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
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# function $*.*:.*$$/ {printf "${COLOR_VALUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target macros: Fire macros-.
.PHONY: macros
macros: macros-.

# target macros-%: Print documented macros starting with %
.PHONY: macros-%
macros-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# macro $*.*:.*$$/ {printf "${COLOR_VALUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target target: Show common targets
.PHONY: target
target:
	printf "${COLOR_INFO}Targets:${COLOR_RESET}\n"
	awk 'BEGIN {FS = ":.*?## "}; $$0 ~ /^[a-zA-Z_-]+:.*?## .*$$/ {printf "${COLOR_VALUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target targets: Fire targets-.
.PHONY: targets
targets: targets-.

# target targets-%: Print documented targets
.PHONY: targets-%
targets-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# target $*.*:.*$$/ {printf "${COLOR_VALUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# target usage: Print Usage
.PHONY: usage
usage:
	printf "${COLOR_INFO}Usage:${COLOR_RESET}\n"
	printf "make [target]\n"

# target variables: Fire variables-.
.PHONY: variables
variables: variables-.

# target variables-%: Show documented variables
.PHONY: variables-%
variables-%:
	awk 'BEGIN {FS = ": "}; $$0 ~ /^# variable $*.*:.*$$/ {printf "${COLOR_VALUE}%-39s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)
