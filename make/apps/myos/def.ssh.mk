DOCKER_BUILD_VARS               += $(SSH_ENV_VARS)
ENV_VARS                        += $(SSH_ENV_VARS)
SSH_BASTION_HOSTNAME            ?=
SSH_BASTION_USERNAME            ?=
SSH_ENV_VARS                    ?= SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PUBLIC_HOST_KEYS SSH_PRIVATE_IP_RANGE
SSH_PUBLIC_HOST_KEYS            ?= $(SSH_REMOTE_HOSTS) $(SSH_BASTION_HOSTNAME)
SSH_PRIVATE_IP_RANGE            ?= 10.10.*
SSH_REMOTE_HOSTS                ?= github.com gitlab.com

# function ssh-connect: Exec command on remote hosts with tty
define ssh-connect
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(eval DOCKER_EXEC_OPTIONS := -it)
	$(foreach host,$(hosts),$(call exec,ssh -t -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") ||) true
endef

# function ssh-exec: Exec command on remote hosts without tty
define ssh-exec
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(foreach host,$(hosts),$(call exec,ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") &&) true
endef
