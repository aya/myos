##
# COMMON

# target $(APP): Call app-update
.PHONY: $(APP)
$(APP): APP_DIR := $(RELATIVE)$(APP)
$(APP): myos-user
	$(call app-update)

# target app-%: Call app-$(command) for APP in APP_DIR
## it splits % on dashes and extracts app from the beginning and command from the last part of %
## ex: app-foo-build will call app-build for app foo in ../foo
.PHONY: app-%
app-%:
	$(eval app     := $(subst -$(lastword $(subst -, ,$*)),,$*))
	$(eval command := $(lastword $(subst -, ,$*)))
	$(if $(filter app-$(command),$(.VARIABLES)), \
	  $(call app-bootstrap,$(app)) \
	  $(call app-$(command)) \
	, \
	  $(call app-bootstrap,$*) \
	)

# target app-required-install: Call app-install for each APP_REQUIRED
.PHONY: app-required-install
app-required-install:
	$(foreach url,$(APP_REQUIRED),$(call app-install,$(url)))

# target apps-build: Call app-build for each APPS
.PHONY: apps-build
apps-build:
	$(foreach app,$(APPS),$(call app-build,$(RELATIVE)$(app)))

# target apps-install install-app: Call app-install for each ARGS
.PHONY: apps-install install-app
apps-install install-app: app-required-install
	$(foreach url,$(ARGS),$(call app-install,$(url)))

# target apps-update: Call app-update target for each APPS
.PHONY: apps-update
apps-update:
	$(foreach app,$(APPS),$(call make,update-app APP_NAME=$(app)))

# target debug: Print more informations
.PHONY: debug
debug:
	$(MAKE) help profile DEBUG=true

# target debug-%: Print value of %
.PHONY: debug-%
debug-%: $(if $(DEBUG),context-%) ;

# target install-bin-%; Install package % when bin % is not available
.PHONY: install-bin-%
install-bin-%:;
	$(if $(shell type $* 2>/dev/null),,$(RUN) $(INSTALL) $*)

# target profile: Print timing informations
.PHONY: profile
profile: context-ELAPSED_TIME

# target update-app: Fire update-app-% for APP_NAME
.PHONY: update-app
update-app: update-app-$(APP_NAME) ;

# target update-app-%: Fire %
.PHONY: update-app-%
update-app-%: % ;

# target update-config: Update config files
.PHONY: update-config
update-config:
	$(call app-update,$(CONFIG_REPOSITORY),$(CONFIG))

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

# target $(SHARED): Create SHARED folder
$(SHARED):
	$(RUN) mkdir -p $(SHARED)
