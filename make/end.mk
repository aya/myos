# Accept arguments for MAKECMDARGS targets and turn them into do-nothing targets
ifneq ($(filter $(MAKECMDARGS),$(firstword $(MAKECMDGOALS))),)
ARGS                            := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS                            := $(subst :,\:,$(ARGS))
ARGS                            := $(subst &,\&,$(ARGS))
$(eval $(ARGS):;@:)
endif
