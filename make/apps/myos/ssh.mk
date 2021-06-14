##
# SSH

# target ssh: Call ssh-connect ARGS or SHELL
.PHONY: ssh
ssh: ssh-get-PrivateIpAddress-$(SERVER_NAME) ## Connect to first remote host
	$(call ssh-connect,$(AWS_INSTANCE_IP),$(if $(ARGS),$(ARGS),$(SHELL)))

# target ssh-add: Fire ssh-key and ssh-add file SSH_PRIVATE_KEYS in folder SSH_DIR
.PHONY: ssh-add
ssh-add: ssh-key
	$(eval SSH_PRIVATE_KEYS := $(foreach file,$(SSH_DIR)/id_rsa $(filter-out $(wildcard $(SSH_DIR)/id_rsa),$(wildcard $(SSH_DIR)/*)),$(if $(shell grep "PRIVATE KEY" $(file) 2>/dev/null),$(notdir $(file)))))
	$(call run,sh -c '$(foreach file,$(patsubst %,$(SSH_DIR)/%,$(SSH_PRIVATE_KEYS)),ssh-add -l |grep -qw $$(ssh-keygen -lf $(file) 2>/dev/null |awk '\''{print $$2}'\'') 2>/dev/null || $(RUN) ssh-add $(file) ||: &&) true',-v $(SSH_DIR):$(SSH_DIR) $(DOCKER_IMAGE_CLI) )

# target ssh-connect: Call ssh-connect make connect SERVICE
.PHONY: ssh-connect
ssh-connect: ssh-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-connect,$(AWS_INSTANCE_IP),make connect COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) ENV=$(ENV) $(if $(SERVICE),SERVICE=$(SERVICE)))

# target ssh-del: ssh-add -d file SSH_PRIVATE_KEYS in folder SSH_DIR
.PHONY: ssh-del
ssh-del:
	$(eval SSH_PRIVATE_KEYS := $(foreach file,$(SSH_DIR)/id_rsa $(filter-out $(wildcard $(SSH_DIR)/id_rsa),$(wildcard $(SSH_DIR)/*)),$(if $(shell grep "PRIVATE KEY" $(file) 2>/dev/null),$(notdir $(file)))))
	$(call run,sh -c '$(foreach file,$(patsubst %,$(SSH_DIR)/%,$(SSH_PRIVATE_KEYS)),ssh-add -l |grep -qw $$(ssh-keygen -lf $(file) 2>/dev/null |awk '\''{print $$2}'\'') 2>/dev/null && $(RUN) ssh-add -d $(file) ||: &&) true',-v $(SSH_DIR):$(SSH_DIR) $(DOCKER_IMAGE_CLI) )

# target ssh-exec: Call ssh-exec make exec SERVICE ARGS
.PHONY: ssh-exec
ssh-exec: ssh-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make exec COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) ENV=$(ENV) $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))

# target ssh-get-PrivateIpAddress-%: Fire aws-ec2-get-instances-PrivateIpAddress-%
.PHONY: ssh-get-PrivateIpAddress-%
ssh-get-PrivateIpAddress-%: aws-ec2-get-instances-PrivateIpAddress-%;

# target ssh-key: Add ssh private key SSH_KEY to SSH_DIR
.PHONY: ssh-key
ssh-key: $(if $(DOCKER_RUN),stack-base-up)
ifneq (,$(filter true,$(DRONE)))
	$(call exec,sh -c '[ ! -d $(SSH_DIR) ] && mkdir -p $(SSH_DIR) && chown $(UID) $(SSH_DIR) && chmod 0700 $(SSH_DIR) ||:')
endif
	$(if $(SSH_KEY),$(eval export SSH_KEY ?= $(SSH_KEY)) $(call env-run,sh -c 'printf "$$SSH_KEY\n" > $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa && chmod 0600 $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa && chown $(UID) $(SSH_DIR)/$(COMPOSE_PROJECT_NAME)_id_rsa ||:'))

# target ssh-run: Call ssh-run make run SERVICE ARGS
.PHONY: ssh-run
ssh-run: ssh-get-PrivateIpAddress-$(SERVER_NAME)
	$(call ssh-exec,$(AWS_INSTANCE_IP),make run $(if $(SERVICE),SERVICE=$(SERVICE)) $(if $(ARGS),ARGS='\''"$(ARGS)"'\''))

# target ssl-certs: Create ${DOMAIN}.key.pem and ${DOMAIN}.crt.pem files
.PHONY: ssl-certs
ssl-certs:
	docker run --rm --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine [ -f /certs/$(DOMAIN).crt.pem -a -f /certs/$(DOMAIN).key.pem ] \
	 || $(RUN) docker run --rm -e DOMAIN=$(DOMAIN) --mount source=$(COMPOSE_PROJECT_NAME_NODE)_ssl-certs,target=/certs alpine sh -c "\
	   apk --no-cache add openssl \
	   && { [ -f /certs/${DOMAIN}.key.pem ] || openssl genrsa -out /certs/${DOMAIN}.key.pem 2048; } \
	   && openssl req -key /certs/${DOMAIN}.key.pem -out /certs/${DOMAIN}.crt.pem \
		  -addext extendedKeyUsage=serverAuth \
		  -addext subjectAltName=DNS:${DOMAIN} \
		  -subj \"/C=/ST=/L=/O=/CN=${DOMAIN}\" \
		  -x509 -days 365"
