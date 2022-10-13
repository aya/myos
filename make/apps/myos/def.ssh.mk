DOCKER_BUILD_VARS               += $(SSH_ENV_VARS)
ENV_VARS                        += $(SSH_ENV_VARS)
SSH_AUTHORIZED_KEYS             ?= $(SSH_GITHUB_AUTHORIZED_KEYS)
SSH_BASTION_HOSTNAME            ?= 
SSH_BASTION_USERNAME            ?= $(SSH_USER)
SSH_ENV_VARS                    ?= SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PUBLIC_HOSTS SSH_PRIVATE_IP_RANGE SSH_USER
SSH_GITHUB_AUTHORIZED_KEYS      ?= $(patsubst %,https://github.com/%,$(patsubst %,%.keys,$(SSH_USER)))
SSH_PUBLIC_HOSTS                ?= $(if $(filter ssh,$(CONFIG_REPOSITORY_SCHEME)),$(CONFIG_REPOSITORY_HOST)) $(SSH_BASTION_HOSTNAME) $(SSH_REMOTE_HOSTS)
SSH_PRIVATE_IP_RANGE            ?= 
SSH_PRIVATE_KEYS                ?= $(wildcard $(SSH_DIR)/id_ed25519 $(SSH_DIR)/id_rsa)
SSH_REMOTE_HOSTS                ?= github.com gitlab.com
SSH_USER                        ?= $(call slugify,$(GIT_USER))

# function ssh-connect: Exec command 2 on remote hosts 1 with tty
define ssh-connect
	$(call INFO,ssh-connect,$(1)$(comma) $(2)$(comma) $(3))
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(eval DOCKER_EXEC_OPTIONS := -it)
	$(foreach host,$(hosts),$(RUN) $(call exec,ssh -t -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") ||) true
endef

# function ssh-exec: Exec command 2 on remote hosts 1 without tty
define ssh-exec
	$(call INFO,ssh-exec,$(1)$(comma) $(2)$(comma) $(3))
	$(eval hosts := $(1))
	$(eval command := $(2))
	$(eval user := $(or $(3),root))
	$(foreach host,$(hosts),$(RUN) $(call exec,ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(user)@$(host) "$(command)") &&) true
endef
