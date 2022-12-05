##
# MYOS

# target myos: Call host target in MYOS folder
.PHONY: myos
myos: myos-host

# target myos-%: Call % target in MYOS folder
.PHONY: myos-%
myos-%: ;
	$(call make,$*,$(MYOS))
