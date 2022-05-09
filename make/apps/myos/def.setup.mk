ENV_VARS                        += SETUP_SYSCTL_CONFIG
SETUP_BINFMT                    ?= $(if $(filter-out amd64 x86_64,$(PROCESSOR_ARCHITECTURE)),true,false)
SETUP_BINFMT_ARCH               ?= all
SETUP_NFSD                      ?= false
SETUP_NFSD_OSX_CONFIG           ?= nfs.server.bonjour=0 nfs.server.mount.regular_files=1 nfs.server.mount.require_resv_port=0 nfs.server.nfsd_threads=16 nfs.server.async=1
SETUP_SYSCTL                    ?= false
SETUP_SYSCTL_CONFIG             ?= vm.max_map_count=262144 vm.overcommit_memory=1 fs.file-max=8388608 net.core.rmem_max=2500000

define setup-nfsd-osx
	$(call INFO,setup-nfsd-osx,$(1)$(comma) $(2)$(comma) $(3))
	$(eval dir:=$(or $(1),$(MONOREPO_DIR)))
	$(eval uid:=$(or $(2),$(UID)))
	$(eval gid:=$(or $(3),$(GID)))
	grep "$(dir)" /etc/exports >/dev/null 2>&1 || printf "$(dir) -alldirs -mapall=$(uid):$(gid) localhost\n" |sudo tee -a /etc/exports >/dev/null
	$(foreach config,$(SETUP_NFSD_OSX_CONFIG),grep "$(config)" /etc/nfs.conf >/dev/null 2>&1 || printf "$(config)\n" |sudo tee -a /etc/nfs.conf >/dev/null &&) true
	nfsd status >/dev/null || sudo nfsd enable
	showmount -e localhost |grep "$(dir)" >/dev/null 2>&1 || sudo nfsd restart
endef
