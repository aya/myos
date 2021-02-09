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
	awk 'BEGIN {FS = ":.*?## "}; $$0 ~ /^[a-zA-Z_-]+:.*?## .*$$/ {printf "${COLOR_BLUE}%-30s${COLOR_RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: context
## Show current context
context:
	printf "${COLOR_BROWN}Context:${COLOR_RESET}\n"
	$(MAKE) $(CONTEXT)

.PHONY: $(CONTEXT)
$(CONTEXT):
	@printf "${COLOR_BLUE}%-30s${COLOR_RESET} ${COLOR_GREEN}%s${COLOR_RESET}\n" $@ "$($@)"

.PHONY: print-%
print-%: ; @printf "${COLOR_BLUE}%-30s${COLOR_RESET} ${COLOR_GREEN}%s${COLOR_RESET}\n" $* "$($*)"
