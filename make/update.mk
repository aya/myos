##
# UPDATE

# target install-app install-apps: Call install-app for each ARGS
.PHONY: install-app install-apps
install-app install-apps:
	$(foreach url,$(ARGS),$(call install-app,$(url)))

# target install-app-%: Call install-app for %
.PHONY: install-app-%
install-app-%:
	$(call install-app,$*)

# target update-apps: Call update-app target for each APPS
.PHONY: update-apps
update-apps:
	$(foreach app,$(APPS),$(call make,update-app APP_NAME=$(app)))

# target update-app: Fire update-app-% for APP_NAME
.PHONY: update-app
update-app: update-app-$(APP_NAME) ;

# target update-app-%: Fire myos-base %
.PHONY: update-app-%
update-app-%: myos-base % ;

# target $(APP): Call update-app
.PHONY: $(APP)
$(APP): APP_DIR := $(RELATIVE)$(APP)
$(APP):
	$(call update-app)

# target update-hosts: Update /etc/hosts
# on local host
## it reads .env files to extract applications hostnames and add it to /etc/hosts
.PHONY: update-hosts
update-hosts:
ifneq (,$(filter $(ENV),local))
	cat */.env 2>/dev/null |grep -Eo 'urlprefix-[^/]+' |sed 's/urlprefix-//' |while read host; do grep $$host /etc/hosts >/dev/null 2>&1 || { echo "Adding $$host to /etc/hosts"; echo 127.0.0.1 $$host |$(ECHO) sudo tee -a /etc/hosts >/dev/null; }; done
endif

# target update-parameters: Fire PARAMETERS
.PHONY: update-parameters
update-parameters: $(PARAMETERS)

# target $(PARAMETERS): Clone or pull parameters files
.PHONY: $(PARAMETERS)
$(PARAMETERS): SSH_PUBLIC_HOST_KEYS := $(PARAMETERS_REMOTE_HOST) $(SSH_BASTION_HOSTNAME) $(SSH_REMOTE_HOSTS)
$(PARAMETERS): MAKE_VARS += SSH_BASTION_HOSTNAME SSH_BASTION_USERNAME SSH_PRIVATE_IP_RANGE SSH_PUBLIC_HOST_KEYS
$(PARAMETERS): myos-base
	$(call update-app,$(PARAMETERS),$(PARAMETERS_REPOSITORY))

# target update-remote-%: fetch git remote %
.PHONY: update-remote-%
update-remote-%: myos-base
	$(call exec,git fetch --prune --tags $*)

# target update-remotes: fetch all git remotes
.PHONY: update-remotes
update-remotes: myos-base
	$(call exec,git fetch --all --prune --tags)

# target update-upstream: fetch git remote upstream
.PHONY: update-upstream
update-upstream: myos-base .git/refs/remotes/upstream/master
	$(call exec,git fetch --prune --tags upstream)

# target .git/refs/remotes/upstream/master: git add upstream APP_UPSTREAM_REPOSITORY
.git/refs/remotes/upstream/master: myos-base
	$(call exec,git remote add upstream $(APP_UPSTREAM_REPOSITORY) 2>/dev/null ||:)

# target shared: Fire SHARED
.PHONY: update-shared
update-shared: $(SHARED)

# target $(SHARED): Create SHARED folder
$(SHARED):
	$(ECHO) mkdir -p $(SHARED)
