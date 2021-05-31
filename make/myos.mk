##
# MYOS

.PHONY: myos-%
myos-%: ;
ifeq ($(wildcard $(MYOS)),$(MYOS))
	$(call make,$*,$(MYOS))
endif
