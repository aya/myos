# target ansible: Fire docker-build-ansible, Call ansible ANSIBLE_ARGS ARGS or ansible-run target
.PHONY: ansible
ansible: $(if $(DOCKER_RUN),docker-build-ansible,install-ansible)
	$(call ansible,$(ANSIBLE_ARGS) $(ARGS))

# target ansible-playbook: Call ansible-playbook ANSIBLE_ARGS ARGS
.PHONY: ansible-playbook
ansible-playbook: $(if $(DOCKER_RUN),docker-build-ansible,install-ansible)
	$(call ansible-playbook,$(ANSIBLE_ARGS) $(ARGS))

# target ansible-pull: Call ansible-pull ANSIBLE_GIT_REPOSITORY ANSIBLE_PLAYBOOK
.PHONY: ansible-pull
ansible-pull: install-ansible
	$(call ansible-pull,--url $(ANSIBLE_GIT_REPOSITORY) $(if $(ANSIBLE_GIT_KEY_FILE),--key-file $(ANSIBLE_GIT_KEY_FILE)) $(if $(ANSIBLE_GIT_VERSION),--checkout $(ANSIBLE_GIT_VERSION)) $(if $(ANSIBLE_GIT_DIRECTORY),--directory $(ANSIBLE_GIT_DIRECTORY)) $(if $(ANSIBLE_TAGS),--tags $(ANSIBLE_TAGS)) $(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)') $(if $(findstring true,$(FORCE)),--force) $(if $(findstring true,$(DRYRUN)),--check) --full $(if $(ANSIBLE_INVENTORY),--inventory $(ANSIBLE_INVENTORY)) $(ANSIBLE_PLAYBOOK))

# target ansible-pull@%: Fire ssh-get-PrivateIpAddress-% for SERVER_NAME, Call ssh-exec make ansible-pull DOCKER_IMAGE_TAG
.PHONY: ansible-pull@%
ansible-pull@%: ssh-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make ansible-pull ANSIBLE_DOCKER_IMAGE_TAG=$(ANSIBLE_DOCKER_IMAGE_TAG) ANSIBLE_TAGS=$(ANSIBLE_TAGS) FORCE=$(FORCE))

# target ansible-run: Fire ssh-add ansible-run-localhost
.PHONY: ansible-run
ansible-run: ansible-run-localhost

# target ansible-run-%: Fire docker-build-ansible, Call ansible-playbook ANSIBLE_PLAYBOOK
.PHONY: ansible-run-%
ansible-run-%: $(if $(DOCKER_RUN),docker-build-ansible,install-ansible) debug-ANSIBLE_PLAYBOOK
	$(call ansible-playbook,$(if $(ANSIBLE_TAGS),--tags $(ANSIBLE_TAGS)) $(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(patsubst target=localhost,target=$*,$(ANSIBLE_EXTRA_VARS))') $(if $(findstring true,$(DRYRUN)),--check) $(if $(ANSIBLE_INVENTORY),--inventory $(ANSIBLE_INVENTORY)) $(ANSIBLE_PLAYBOOK))

# target ansible-tests: Fire ssh-add ansible-tests-localhost
.PHONY: ansible-tests
ansible-tests: ansible-tests-localhost

# target ansible-tests-%: Fire docker-run-% with ANSIBLE_PLAYBOOK ansible/roles/*/tests/playbook.yml
.PHONY: ansible-tests-%
ansible-tests-%: ANSIBLE_PLAYBOOK := $(wildcard ansible/roles/*/tests/playbook.yml)
ansible-tests-%: ansible-run-%;
