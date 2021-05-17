##
# MYOS

.PHONY: myos-%
myos-%: ;
ifneq ($(wildcard $(MYOS)),)
	$(call make,$*,$(MYOS))
endif
