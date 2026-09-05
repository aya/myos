##
# SSH
#
# The remote hosts used to come from AWS, through
# ssh-get-PrivateIpAddress-% -> aws-ec2-get-instances-PrivateIpAddress-%.
# make/apps/aws was removed and AWS_INSTANCE_IP is defined nowhere, so these
# targets looped over an empty list and exited 0 without doing anything.
# They now take SSH_HOSTS, and say so when it is empty rather than pretending
# to have connected.

# variable SSH_HOSTS: hosts the ssh targets act on, space separated
SSH_HOSTS                       ?= $(AWS_INSTANCE_IP)

# target ssh-hosts-check: Fail when no remote host is known
.PHONY: ssh-hosts-check
ssh-hosts-check:
	$(if $(SSH_HOSTS),,$(call ERROR,no remote host: set SSH_HOSTS=host1 host2))

# target ssh: Call ssh-connect ARGS or SHELL
.PHONY: ssh
ssh: ssh-hosts-check ## Connect to first remote host
	$(call ssh-connect,$(SSH_HOSTS),$(if $(ARGS),$(ARGS),$(SHELL)))

# target ssh-add: Fire ssh-key and ssh-add file SSH_PRIVATE_KEYS in folder SSH_DIR
.PHONY: ssh-add
ssh-add: DOCKER_RUN_OPTIONS += -it
ssh-add: ssh-key
	$(eval SSH_PRIVATE_KEYS := $(foreach file,$(SSH_DIR)/id_ed25519 $(SSH_DIR)/id_rsa $(filter-out $(wildcard $(SSH_DIR)/id_ed25519 $(SSH_DIR)/id_rsa),$(wildcard $(SSH_DIR)/*)),$(if $(shell grep "PRIVATE KEY" $(file) 2>/dev/null),$(notdir $(file)))))
	$(call run,sh -c '$(foreach file,$(patsubst %,$(SSH_DIR)/%,$(SSH_PRIVATE_KEYS)),ssh-add -l |grep -qw $$(ssh-keygen -lf $(file) 2>/dev/null |awk '\''{print $$2}'\'') 2>/dev/null || $(RUN) ssh-add $(file) ||: &&) true',-v $(SSH_DIR):$(SSH_DIR) $(USER_DOCKER_IMAGE) )

# target ssh-connect: Call ssh-connect make connect SERVICE
.PHONY: ssh-connect
ssh-connect: ssh-hosts-check
	$(call ssh-connect,$(SSH_HOSTS),make connect COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) ENV=$(ENV) $(if $(SERVICE),SERVICE=$(SERVICE)))

# target ssh-del: ssh-add -d file SSH_PRIVATE_KEYS in folder SSH_DIR
.PHONY: ssh-del
ssh-del:
	$(eval SSH_PRIVATE_KEYS := $(foreach file,$(SSH_DIR)/id_ed25519 $(SSH_DIR)/id_rsa $(filter-out $(wildcard $(SSH_DIR)/id_ed25519 $(SSH_DIR)/id_rsa),$(wildcard $(SSH_DIR)/*)),$(if $(shell grep "PRIVATE KEY" $(file) 2>/dev/null),$(notdir $(file)))))
	$(call run,sh -c '$(foreach file,$(patsubst %,$(SSH_DIR)/%,$(SSH_PRIVATE_KEYS)),ssh-add -l |grep -qw $$(ssh-keygen -lf $(file) 2>/dev/null |awk '\''{print $$2}'\'') 2>/dev/null && $(RUN) ssh-add -d $(file) ||: &&) true',-v $(SSH_DIR):$(SSH_DIR) $(USER_DOCKER_IMAGE) )

# target ssh-exec: Call ssh-exec make exec SERVICE ARGS
.PHONY: ssh-exec
ssh-exec: ssh-hosts-check
	$(call ssh-exec,$(SSH_HOSTS),make exec COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) ENV=$(ENV) $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))

# target ssh-key: Add ssh private key SSH_KEY to SSH_DIR
.PHONY: ssh-key
ssh-key:
ifneq (,$(filter true,$(DRONE)))
	$(call exec,sh -c '[ ! -d $(SSH_DIR) ] && mkdir -p $(SSH_DIR) && chown $(UID) $(SSH_DIR) && chmod 0700 $(SSH_DIR) ||:')
endif
	$(if $(SSH_KEY),$(eval export SSH_KEY ?= $(SSH_KEY)) $(call env-exec,sh -c 'printf "$$SSH_KEY\n" > $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa && chmod 0600 $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa && chown $(UID) $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa ||:'))

# target ssh-run: Call ssh-run make run SERVICE ARGS
.PHONY: ssh-run
ssh-run: ssh-hosts-check
	$(call ssh-exec,$(SSH_HOSTS),make run $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))
