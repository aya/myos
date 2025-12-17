##
# MYOS

# target myos-%: Call % target in MYOS folder
.PHONY: myos-%
myos-%: ;
	$(call make,$*,$(MYOS))
