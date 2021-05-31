##
# UPDATE

.PHONY: update-parameters
update-app: $(APP) ## Update application source files

$(APP): myos-base
	$(call exec,[ -d ../$(APP) ] && cd ../$(APP) && git pull --quiet origin $(BRANCH) || git clone --quiet $(APP_REPOSITORY) ../$(APP))

## Update /etc/hosts
.PHONY: update-hosts
update-hosts:
ifneq (,$(filter $(ENV),local))
	cat */.env 2>/dev/null |grep -Eo 'urlprefix-[^/]+' |sed 's/urlprefix-//' |while read host; do grep $$host /etc/hosts >/dev/null 2>&1 || { echo "Adding $$host to /etc/hosts"; echo 127.0.0.1 $$host |$(ECHO) sudo tee -a /etc/hosts >/dev/null; }; done
endif

.PHONY: update-parameters
update-parameters: $(PARAMETERS)

$(PARAMETERS): SSH_PUBLIC_HOST_KEYS := $(PARAMETERS_REMOTE_HOST) $(SSH_BASTION_HOSTNAME) $(SSH_REMOTE_HOSTS)
$(PARAMETERS): MAKE_VARS += SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PRIVATE_IP_RANGE SSH_PUBLIC_HOST_KEYS
$(PARAMETERS): myos-base
	$(call exec,[ -d $(PARAMETERS) ] && cd $(PARAMETERS) && git pull --quiet || git clone --quiet $(APP_PARAMETERS_REPOSITORY))

.PHONY: update-remote-%
update-remote-%: myos-base
	$(call exec,git fetch --prune --tags $*)

.PHONY: update-remotes
update-remotes: myos-base
	$(call exec,git fetch --all --prune --tags)

.PHONY: update-upstream
update-upstream: myos-base .git/refs/remotes/upstream/master
	$(call exec,git fetch --prune --tags upstream)

.git/refs/remotes/upstream/master: myos-base
	$(call exec,git remote add upstream $(APP_UPSTREAM_REPOSITORY) 2>/dev/null ||:)
