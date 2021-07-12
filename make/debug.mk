##
# DEBUG

# target debug: Print more informations
.PHONY: debug
debug:
	$(MAKE) doc help profile DEBUG=true

# target debug-%: Print value of %
.PHONY: debug-%
debug-%: $(if $(DEBUG),context-%) ;

# target profile: Print timing informations
.PHONY: profile
profile: context-ELAPSED_TIME

