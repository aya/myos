##
# INFRA

.PHONY: infra-%
infra-%: ;
ifneq ($(wildcard $(INFRA)),)
	$(call make,$*,$(INFRA))
endif
