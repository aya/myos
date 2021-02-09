define ssh-connect
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(eval DOCKER_EXEC_OPTIONS := -it)
	$(foreach host,$(hosts),$(call exec,ssh -t -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") ||) true
endef

define ssh-exec
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(foreach host,$(hosts),$(call exec,ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") &&) true
endef
