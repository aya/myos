##
# MYOS

# target myos-%: call % target in MYOS folder
.PHONY: myos-%
myos-%: ;
ifeq ($(wildcard $(MYOS)),$(MYOS))
	$(call make,$*,$(MYOS))
endif
