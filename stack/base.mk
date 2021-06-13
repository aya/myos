# target base: Fire docker-network-create stack-base-up base-ssh-add
.PHONY: base
base: docker-network-create $(if $(filter $(DOCKER),true),stack-base-up base-ssh-add)

# target ssh-add: Fire base-ssh-add
.PHONY: ssh-add
ssh-add: base-ssh-add

# target base-ssh-add: Fire base-ssh-key and exec ssh-add file SSH_PRIVATE_KEYS in folder SSH_DIR
.PHONY: base-ssh-add
base-ssh-add: base-ssh-key
	$(eval SSH_PRIVATE_KEYS := $(foreach file,$(SSH_DIR)/id_rsa $(filter-out $(wildcard $(SSH_DIR)/id_rsa),$(wildcard $(SSH_DIR)/*)),$(if $(shell grep "PRIVATE KEY" $(file) 2>/dev/null),$(notdir $(file)))))
	$(eval IGNORE_VERBOSE := true)
	$(call docker-run,$(DOCKER_IMAGE_CLI),sh -c "$(foreach file,$(patsubst %,$(SSH_DIR)/%,$(SSH_PRIVATE_KEYS)),ssh-add -l |grep -qw $$(ssh-keygen -lf $(file) 2>/dev/null |awk '{print $$2}') 2>/dev/null || ssh-add $(file) ||: &&) true")
	$(eval IGNORE_VERBOSE := false)

# target base-ssh-key: Setup ssh private key SSH_KEY in SSH_DIR
.PHONY: base-ssh-key
base-ssh-key: stack-base-up
ifneq (,$(filter true,$(DRONE)))
	$(call exec,[ ! -d $(SSH_DIR) ] && mkdir -p $(SSH_DIR) && chown $(UID) $(SSH_DIR) && chmod 0700 $(SSH_DIR) ||:)
else
	$(eval DOCKER_RUN_VOLUME += -v $(SSH_DIR):$(SSH_DIR))
endif
	$(if $(SSH_KEY),$(eval export SSH_KEY ?= $(SSH_KEY)) $(call docker-run,$(DOCKER_IMAGE_CLI),echo -e "$$SSH_KEY" > $(SSH_DIR)/${COMPOSE_PROJECT_NAME}_id_rsa && chmod 0400 $(SSH_DIR)/${COMPOSE_PROJECT_NAME}_id_rsa && chown $(UID) $(SSH_DIR)/${COMPOSE_PROJECT_NAME}_id_rsa ||:))
