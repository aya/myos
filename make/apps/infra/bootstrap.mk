##
# BOOTSTRAP

.PHONY: bootstrap-infra
bootstrap-infra: setup-sysctl
ifeq ($(SETUP_NFSD),true)
ifeq ($(HOST_SYSTEM),DARWIN)
	$(call setup-nfsd-osx)
endif
endif
