##
# INSTALL

.PHONY: install-infra
install-infra: infra-install

.PHONY: install-$(SHARED)
install-$(SHARED): $(SHARED)

$(SHARED):
	$(ECHO) mkdir -p $(SHARED)
