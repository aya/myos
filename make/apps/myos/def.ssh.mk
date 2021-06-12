DOCKER_BUILD_VARS               += $(SSH_ENV_VARS)
ENV_VARS                        += $(SSH_ENV_VARS)
SSH_BASTION_HOSTNAME            ?= 
SSH_BASTION_USERNAME            ?= 
SSH_ENV_VARS                    ?= SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PUBLIC_HOST_KEYS SSH_PRIVATE_IP_RANGE
SSH_PUBLIC_HOST_KEYS            ?= $(SSH_REMOTE_HOSTS) $(SSH_BASTION_HOSTNAME)
SSH_PRIVATE_IP_RANGE            ?= 
SSH_REMOTE_HOSTS                ?= github.com gitlab.com

# function ssh-connect: Exec command 2 on remote hosts 1 with tty
define ssh-connect
	$(call INFO,ssh-connect,$(1)$(comma) $(2)$(comma) $(3))
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(eval DOCKER_EXEC_OPTIONS := -it)
	$(foreach host,$(hosts),$(call exec,ssh -t -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") ||) true
endef

# function ssh-exec: Exec command 2 on remote hosts 1 without tty
define ssh-exec
	$(call INFO,ssh-exec,$(1)$(comma) $(2)$(comma) $(3))
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(foreach host,$(hosts),$(call exec,ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") &&) true
endef
