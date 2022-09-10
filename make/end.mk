# Accept arguments for CMDS targets and turn them into do-nothing targets
ifneq ($(filter $(CMDS),$(firstword $(MAKECMDGOALS))),)
ARGS                            := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS                            := $(subst :,\:,$(ARGS))
ARGS                            := $(subst &,\&,$(ARGS))
$(eval $(ARGS):;@:)
endif
