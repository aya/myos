##
# SETUP

# target setup-docker-group: Call ansible to add user in docker group if needed
.PHONY: setup-docker-group
setup-docker-group:
ifneq ($(DOCKER),)
ifeq ($(or $(filter $(USER),$(subst $(comma), ,$(shell awk -F':' '$$1 == "docker" {print $$4}' /etc/group))),$(filter 0,$(UID))),)
	$(call ansible-user-add-groups,$(USER),docker)
	$(call WARNING,user,$(USER),added in group,docker)
endif
ifeq ($(filter 0 $(DOCKER_GID),$(GIDS)),)
	$(call ERROR,YOU MUST LOGOUT NOW AND LOGIN BACK TO GET DOCKER GROUP MEMBERSHIP)
endif
endif

# target setup-nfsd: Call setup-nfsd-osx if SETUP_NFSD=true and OPERATING_SYSTEM=Darwin
.PHONY: setup-nfsd
setup-nfsd:
ifeq ($(SETUP_NFSD),true)
ifeq ($(OPERATING_SYSTEM),Darwin)
	$(call setup-nfsd-osx)
endif
endif

# target setup-sysctl: Add sysctl config for each SETUP_SYSCTL_CONFIG
.PHONY: setup-sysctl
setup-sysctl:
ifeq ($(SETUP_SYSCTL),true)
	$(RUN) $(SUDO) sysctl -q -w $(SETUP_SYSCTL_CONFIG)
endif

# target setup-binfmt: Install binfmt abstraction layer
.PHONY: setup-binfmt
setup-binfmt:
ifeq ($(SETUP_BINFMT),true)
	$(call docker-run,--install $(SETUP_BINFMT_ARCH),--privileged tonistiigi/binfmt)
endif
