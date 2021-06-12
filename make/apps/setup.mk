##
# SETUP

.PHONY: setup-sysctl
setup-sysctl:
ifeq ($(SETUP_SYSCTL),true)
	$(foreach config,$(SETUP_SYSCTL_CONFIG),$(call docker-run,--privileged alpine:latest,sysctl -q -w $(config)) &&) true
endif

.PHONY: setup-nfsd
setup-nfsd:
ifeq ($(SETUP_NFSD),true)
ifeq ($(HOST_SYSTEM),DARWIN)
	$(call setup-nfsd-osx)
endif
endif

define setup-nfsd-osx
	$(call INFO,setup-nfsd-osx,$(1)$(comma) $(2)$(comma) $(3))
	$(eval dir:=$(or $(1),$(MONOREPO_DIR)))
	$(eval uid:=$(or $(2),$(UID)))
	$(eval gid:=$(or $(3),$(GID)))
	grep "$(dir)" /etc/exports >/dev/null 2>&1 || echo "$(dir) -alldirs -mapall=$(uid):$(gid) localhost" |sudo tee -a /etc/exports >/dev/null
	$(foreach config,$(SETUP_NFSD_OSX_CONFIG),grep "$(config)" /etc/nfs.conf >/dev/null 2>&1 || echo "$(config)" |sudo tee -a /etc/nfs.conf >/dev/null &&) true
	nfsd status >/dev/null || sudo nfsd enable
	showmount -e localhost |grep "$(dir)" >/dev/null 2>&1 || sudo nfsd restart
endef
