##
# INFRA

.PHONY: setup-sysctl
setup-sysctl:
ifeq ($(SETUP_SYSCTL),true)
	$(foreach config,$(SETUP_SYSCTL_CONFIG),$(call docker-run,--privileged alpine:latest,sysctl -q -w $(config)) &&) true
endif

.PHONY: start-up
start-up: base-ssh-add
