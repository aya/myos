##
# INSTALL

.PHONY: install-myos
install-myos: myos-install

.PHONY: install-$(SHARED)
install-$(SHARED): $(SHARED)

$(SHARED):
	$(ECHO) mkdir -p $(SHARED)
