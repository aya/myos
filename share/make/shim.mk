##
# myos, from make.
#
# This file gives a project the myos commands as make targets, without the make
# engine: every target shells out to bin/myos, which is pure POSIX sh. What the
# project keeps from make is what make is actually good at, and the CLI is not:
# its own targets, its own dependencies, and the .mk files of its stacks.
#
#   MYOS ?= /usr/local/lib/myos
#   include $(MYOS)/share/make/shim.mk
#
# It lives outside make/ on purpose: the legacy engine includes every .mk of
# that directory, and would pull this one in too.
#
# Then `make up STACK=host` and `myos up host` do the same thing, through the
# same code. Variables given on the command line are forwarded, so
# `make up STACK=host DOMAIN=example.org` behaves as expected.

MYOS                            ?= $(patsubst %/share/make/shim.mk,%,$(lastword $(MAKEFILE_LIST)))
MYOS_BIN                        ?= $(MYOS)/bin/myos
STACK_DIR_NAME                  ?= stack
## every directory myos looks for stacks in, so the .mk of a stack installed
## system wide brings its targets along too
STACK_DIR                       ?= $(subst :, ,$(shell $(MYOS_BIN) env MYOS_PATH --color=never 2>/dev/null | awk '{print $$2}'))

# variable MYOS_ARGS: variables set on the make command line, forwarded to myos
MYOS_ARGS                       ?= $(foreach v,$(MAKEOVERRIDES),$(v))

.DEFAULT_GOAL                   := help

## the stack files may add their own targets: that is what make is kept for
include $(foreach dir,$(STACK_DIR),$(wildcard $(dir)/*.mk $(dir)/*/*.mk))

# function make: run a myos command, for the stack .mk files that call it
define make
	$(MYOS_BIN) $(MYOS_ARGS) $(1)
endef

# function myos-var: the value myos resolves for a variable.
# A stack keeps its settings in hooks that only myos reads, so a .mk target
# asks for them rather than defining them itself:
#   $(call myos-var,HOST_DOCKER_VOLUME)
myos-var = $(shell $(MYOS_BIN) --color=never $(MYOS_ARGS) env $(1) | awk '{print $$2}')

# target help: List the myos commands
.PHONY: help
help:
	@$(MYOS_BIN) help

# target myos: Run an arbitrary myos command, as in `make myos ARGS="up host"`
.PHONY: myos
myos:
	@$(MYOS_BIN) $(MYOS_ARGS) $(ARGS)

# make tries to remake every makefile it read, and the catch-all below would
# hand each of them to myos as a command. An empty rule stops that.
$(MAKEFILE_LIST): ;

# target %: Hand anything else to myos
## a target the project defines itself keeps precedence over this rule
%: FORCE
	@$(MYOS_BIN) $(MYOS_ARGS) $@ $(ARGS)

.PHONY: FORCE
FORCE: ;
