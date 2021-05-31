##
# UPDATE

.PHONY: update-apps
update-apps:
	$(foreach app,$(APPS),$(call make,update-app APP_NAME=$(app)))

.PHONY: update-app
update-app: update-app-$(APP_NAME) ; ## Update application source files

.PHONY: update-app-%
update-app-%: myos-base % ;

.PHONY: $(APP)
$(APP): APP_DIR := $(if $(filter myos,$(MYOS)),,../)$(APP)
$(APP):
	$(call exec,[ -d $(APP_DIR) ] && cd $(APP_DIR) && git pull $(QUIET) origin $(BRANCH) || git clone $(QUIET) $(APP_REPOSITORY) $(APP_DIR))

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
