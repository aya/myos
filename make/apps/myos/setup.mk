##
# SETUP

# target setup-binfmt: Install binfmt abstraction layer
.PHONY: setup-binfmt
setup-binfmt:
ifeq ($(SETUP_BINFMT),true)
	$(call docker-run,--privileged tonistiigi/binfmt,--install $(SETUP_BINFMT_ARCH))
endif

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

# target setup-nfsd: Call setup-nfsd-osx if SETUP_NFSD=true and SYSTEM=Darwin
.PHONY: setup-nfsd
setup-nfsd:
ifeq ($(SETUP_NFSD),true)
ifeq ($(SYSTEM),Darwin)
	$(call setup-nfsd-osx)
endif
endif

# target setup-sysctl: Add sysctl config for each SETUP_SYSCTL_CONFIG
.PHONY: setup-sysctl
setup-sysctl:
ifeq ($(SETUP_SYSCTL),true)
	$(RUN) $(SUDO) sysctl -q -w $(SETUP_SYSCTL_CONFIG)
endif

# target setup-ufw: Install ufw-docker
.PHONY: setup-ufw
setup-ufw: COMPOSE_PROJECT_NAME := $(HOST_COMPOSE_PROJECT_NAME)
setup-ufw: DOCKER_RUN_NETWORK   :=
setup-ufw: DOCKER_RUN_OPTIONS   := --rm -d --cap-add NET_ADMIN -v /etc/ufw:/etc/ufw $(if wildcard /etc/default/ufw,-v /etc/default/ufw:/etc/default/ufw) --network host --restart always
setup-ufw:
ifeq ($(SETUP_UFW),true)
	$(call app-install,$(SETUP_UFW_REPOSITORY))
	$(call app-bootstrap,$(lastword $(subst /, ,$(SETUP_UFW_REPOSITORY))))
	$(call app-build)
	$(call app-up)
	$(call ufw-docker,install)
endif
