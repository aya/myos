##
# COMMON

# target $(APP): Call update-app
.PHONY: $(APP)
$(APP): APP_DIR := $(RELATIVE)$(APP)
$(APP): myos-user
	$(call update-app)

# target install-app install-apps: Call install-app for each ARGS
.PHONY: install-app install-apps
install-app install-apps: myos-user install-app-required
	$(foreach url,$(ARGS),$(call install-app,$(url)))

# target install-app-required: Call install-app for each APP_REQUIRED
.PHONY: install-app-required
install-app-required: myos-user
	$(foreach url,$(APP_REQUIRED),$(call install-app,$(url)))

# target install-bin-%; Call ansible-run-localhost when bin % is not available
.PHONY: install-bin-%
install-bin-%:;
	$(if $(shell type $* 2>/dev/null),,$(call make,ansible-run-localhost))

# target $(SHARED): Create SHARED folder
$(SHARED):
	$(RUN) mkdir -p $(SHARED)

# target update-apps: Call update-app target for each APPS
.PHONY: update-apps
update-apps:
	$(foreach app,$(APPS),$(call make,update-app APP_NAME=$(app)))

# target update-app: Fire update-app-% for APP_NAME
.PHONY: update-app
update-app: update-app-$(APP_NAME) ;

# target update-app-%: Fire %
.PHONY: update-app-%
update-app-%: % ;

# target update-config: Update config files
.PHONY: update-config
update-config: myos-user
	$(call update-app,$(CONFIG_REPOSITORY),$(CONFIG))

# target update-hosts: Update /etc/hosts
# on local host
## it reads .env files to extract applications hostnames and add it to /etc/hosts
.PHONY: update-hosts
update-hosts:
ifneq (,$(filter $(ENV),local))
	cat .env */.env 2>/dev/null |grep -Eo 'urlprefix-[^/]+' |sed 's/urlprefix-//' |while read host; do \
	 grep $$host /etc/hosts >/dev/null 2>&1 || { \
	  printf "Adding $$host to /etc/hosts\n"; \
	  printf "127.0.0.1 $$host\n" |$(RUN) sudo tee -a /etc/hosts >/dev/null; \
	 }; \
	done
endif

# target update-remote-%: fetch git remote %
.PHONY: update-remote-%
update-remote-%: myos-user
	$(RUN) git fetch --prune --tags $*

# target update-remotes: fetch all git remotes
.PHONY: update-remotes
update-remotes: myos-user
	$(RUN) git fetch --all --prune --tags

# target update-upstream: fetch git remote upstream
.PHONY: update-upstream
update-upstream: myos-user .git/refs/remotes/upstream/master
	$(RUN) git fetch --prune --tags upstream

# target .git/refs/remotes/upstream/master: add git upstream APP_UPSTREAM_REPOSITORY
.git/refs/remotes/upstream/master:
	$(RUN) git remote add upstream $(APP_UPSTREAM_REPOSITORY)

# target shared: Fire SHARED
.PHONY: update-shared
update-shared: $(SHARED)
