ANSIBLE_APP_LOAD                ?= myos
ANSIBLE_APP_NAME                ?= myos
ANSIBLE_ARGS                    ?= $(if $(filter-out 0,$(UID)),$(if $(shell sudo -l 2>/dev/null |grep 'NOPASSWD: ALL'),,--ask-become-pass))$(if $(DOCKER_RUN),$(if $(shell ssh-add -l >/dev/null 2>&1 || echo false), --ask-pass))
ANSIBLE_AWS_ACCESS_KEY_ID       ?= $(AWS_ACCESS_KEY_ID)
ANSIBLE_AWS_DEFAULT_OUTPUT      ?= $(AWS_DEFAULT_OUTPUT)
ANSIBLE_AWS_DEFAULT_REGION      ?= $(AWS_DEFAULT_REGION)
ANSIBLE_AWS_SECRET_ACCESS_KEY   ?= $(AWS_SECRET_ACCESS_KEY)
ANSIBLE_CONFIG                  ?= ansible/ansible.cfg
ANSIBLE_DISKS_NFS_DISK          ?= $(NFS_DISK)
ANSIBLE_DISKS_NFS_OPTIONS       ?= $(NFS_OPTIONS)
ANSIBLE_DISKS_NFS_PATH          ?= $(NFS_PATH)
# running ansible in docker requires sshd running on localhost,
# to allow ansible to escape docker and apply changes to localhost
ANSIBLE_DOCKER                  ?= false
ANSIBLE_DOCKER_RUN              ?= $(if $(filter-out false False FALSE,$(ANSIBLE_DOCKER)),$(ANSIBLE_DOCKER))
ANSIBLE_DOCKER_IMAGE_TAG        ?= $(DOCKER_IMAGE_TAG)
ANSIBLE_DOCKER_REGISTRY         ?= $(DOCKER_REGISTRY)
ANSIBLE_EXTRA_VARS              ?= target=localhost
ANSIBLE_GIT_DIRECTORY           ?= /dns/$(subst $(space),/,$(strip $(call reverse,$(subst ., ,$(APP_REPOSITORY_HOST)))))/$(APP_REPOSITORY_PATH)
ANSIBLE_GIT_KEY_FILE            ?= $(if $(ANSIBLE_SSH_PRIVATE_KEYS),~$(ANSIBLE_USERNAME)/.ssh/$(notdir $(firstword $(ANSIBLE_SSH_PRIVATE_KEYS))))
ANSIBLE_GIT_REPOSITORY          ?= $(GIT_REPOSITORY)
ANSIBLE_GIT_VERSION             ?= $(BRANCH)
ANSIBLE_INVENTORY               ?= ansible/inventories
ANSIBLE_MYOS                    ?= $(ANSIBLE_GIT_DIRECTORY)
ANSIBLE_PLAYBOOK                ?= ansible/playbook.yml
ANSIBLE_SSH_AUTHORIZED_KEYS     ?= $(strip $(SSH_AUTHORIZED_KEYS))
ANSIBLE_SSH_BASTION_HOSTNAME    ?= $(firstword $(SSH_BASTION_HOSTNAME))
ANSIBLE_SSH_BASTION_USERNAME    ?= $(firstword $(SSH_BASTION_USERNAME))
ANSIBLE_SSH_PRIVATE_IP_RANGE    ?= $(strip $(SSH_PRIVATE_IP_RANGE))
ANSIBLE_SSH_PRIVATE_KEYS        ?= $(if $(ANSIBLE_SSH_PRIVATE_KEYS_ENABLE),$(strip $(SSH_PRIVATE_KEYS)))
ANSIBLE_SSH_PRIVATE_KEYS_ENABLE ?=
ANSIBLE_SSH_PUBLIC_HOSTS        ?= $(strip $(SSH_PUBLIC_HOSTS))
ANSIBLE_SSH_USERNAME            ?= $(firstword $(SSH_USER))
ANSIBLE_SERVER_NAME             ?= $(SERVER_NAME)
ANSIBLE_USERNAME                ?= $(USER)
ANSIBLE_VERBOSE                 ?= $(if $(DEBUG),-vvvv,$(if $(VERBOSE),-v))
DOCKER_RUN_OPTIONS_ANSIBLE      ?= -it $(if $(DOCKER_INTERNAL_DOCKER_HOST),--add-host=host.docker.internal:$(DOCKER_INTERNAL_DOCKER_HOST))
ENV_VARS                        += ANSIBLE_APP_LOAD ANSIBLE_APP_NAME ANSIBLE_AWS_ACCESS_KEY_ID ANSIBLE_AWS_DEFAULT_OUTPUT ANSIBLE_AWS_DEFAULT_REGION ANSIBLE_AWS_SECRET_ACCESS_KEY ANSIBLE_CONFIG ANSIBLE_DISKS_NFS_DISK ANSIBLE_DISKS_NFS_OPTIONS ANSIBLE_DISKS_NFS_PATH ANSIBLE_DOCKER_IMAGE_TAG ANSIBLE_DOCKER_REGISTRY ANSIBLE_EXTRA_VARS ANSIBLE_GIT_DIRECTORY ANSIBLE_GIT_KEY_FILE ANSIBLE_GIT_REPOSITORY ANSIBLE_GIT_VERSION ANSIBLE_INVENTORY ANSIBLE_MYOS ANSIBLE_PLAYBOOK ANSIBLE_SSH_AUTHORIZED_KEYS ANSIBLE_SSH_BASTION_HOSTNAME ANSIBLE_SSH_BASTION_USERNAME ANSIBLE_SSH_PRIVATE_IP_RANGE ANSIBLE_SSH_PRIVATE_KEYS ANSIBLE_SSH_PUBLIC_HOSTS ANSIBLE_SSH_USERNAME ANSIBLE_USERNAME ANSIBLE_VERBOSE
MAKECMDARGS                     += ansible ansible-playbook

# function ansible: Call run ansible ANSIBLE_ARGS with arg 1
define ansible
	$(call INFO,ansible,$(1))
	$(call $(if $(ANSIBLE_DOCKER_RUN),run,env-exec),$(if $(ANSIBLE_DOCKER_RUN),,$(RUN) )ansible $(ANSIBLE_ARGS) $(ANSIBLE_VERBOSE) $(if $(ANSIBLE_DOCKER_RUN),-i $(ANSIBLE_INVENTORY)/.host.docker.internal) $(1),$(DOCKER_RUN_OPTIONS_ANSIBLE) $(DOCKER_REPOSITORY)/)
endef
# function ansible-playbook: Call run ansible-playbook ANSIBLE_ARGS with arg 1
define ansible-playbook
	$(call INFO,ansible-playbook,$(1))
	$(call $(if $(ANSIBLE_DOCKER_RUN),run,env-exec),$(if $(ANSIBLE_DOCKER_RUN),,$(RUN) )ansible$(if $(ANSIBLE_DOCKER_RUN),,-playbook) $(ANSIBLE_ARGS) $(ANSIBLE_VERBOSE) $(if $(ANSIBLE_DOCKER_RUN),-i $(ANSIBLE_INVENTORY)/.host.docker.internal) $(1),$(DOCKER_RUN_OPTIONS_ANSIBLE) --entrypoint=ansible-playbook $(DOCKER_REPOSITORY)/)
endef
# function ansible-pull: Call run ansible-pull ANSIBLE_ARGS with arg 1
define ansible-pull
	$(call INFO,ansible-pull,$(1))
	$(call $(if $(ANSIBLE_DOCKER_RUN),run,env-exec),$(if $(ANSIBLE_DOCKER_RUN),,$(RUN) )ansible-pull $(ANSIBLE_ARGS) $(ANSIBLE_VERBOSE) $(1))
endef
# function ansible-user-add-groups: Call ansible to add user 1 in groups 2
define ansible-user-add-groups
	$(call INFO,ansible-user-add-groups,$(1)$(comma) $(2))
	$(if $(ANSIBLE_DOCKER_RUN),$(call make,docker-build-ansible),$(call make,install-ansible))
	$(call ansible,-b -m user -a 'name=$(1) groups=$(2) append=yes' localhost)
endef
