##
# DEBUG

# target debug: Print more informations
.PHONY: debug
debug:
	$(MAKE) doc help DEBUG=true

# target debug-%: Print value of %
.PHONY: debug-%
debug-%: context-% ;
