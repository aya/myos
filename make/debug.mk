##
# DEBUG

.PHONY: debug
debug:
	$(MAKE) DEBUG=true

.PHONY: debug-%
debug-%: context-% ;
