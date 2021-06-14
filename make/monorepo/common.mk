##
# COMMON

# target build: Fire APPS target
.PHONY: build
build: $(APPS) ## Build applications

# target build@%: Fire APPS target
.PHONY: build@%
build@%: $(APPS);

# target clean: Fire APPS target
.PHONY: clean
clean: $(APPS) ## Clean applications

# target clean@%: Fire APPS target
.PHONY: clean@%
clean@%: $(APPS);

# target config: Fire APPS target
.PHONY: config
config: $(APPS)

# target copy: Copy files and folders to all APPS
.PHONY: copy
copy:
	$(foreach app,$(APPS),$(foreach file,$(ARGS),$(if $(wildcard $(file)),$(RUN) $(if $(filter LINUX,$(HOST_SYSTEM)),cp -a --parents $(file) $(app)/,rsync -a $(file) $(app)/$(file)) &&)) true &&) true

# target deploy: Fire APPS target
.PHONY: deploy
deploy: $(APPS) ## Deploy applications

# target deploy@%: Fire APPS target
.PHONY: deploy@%
deploy@%: $(APPS);

# target down: Fire APPS target
.PHONY: down
down: $(APPS) ## Remove applications dockers

# target install: Fire APPS target
.PHONY: install
install: $(APPS) ## Install applications

# target ps: Fire APPS target
.PHONY: ps
ps: $(APPS)

# target rebuild: Fire APPS target
.PHONY: rebuild
rebuild: $(APPS) ## Rebuild applications

# target recreate: Fire APPS target
.PHONY: recreate
recreate: $(APPS) ## Recreate applications

# target reinstall: Fire APPS target
.PHONY: reinstall
reinstall: $(APPS) ## Reinstall applications

# target release: Fire release-create target
.PHONY: release
release: release-create ## Create release VERSION

# target restart: Fire APPS target
.PHONY: restart
restart: $(APPS) ## Restart applications

# target start: Fire APPS target
.PHONY: start
start: $(APPS) ## Start applications

# target stop: Fire APPS target
.PHONY: stop
stop: $(APPS) ## Stop applications

# target tests: Fire APPS target
.PHONY: tests
tests: $(APPS) ## Test applications

# target up: Fire APPS target
.PHONY: up
up: $(APPS) ## Create applications dockers

# target update: Fire update-apps target
.PHONY: update
update: update-apps ## Update applications files

# target upgrade: Fire upgrade-apps and release-upgrade targets
.PHONY: upgrade
upgrade: upgrade-apps release-upgrade ## Upgrade applications

# target $(APPS): Call targets MAKECMDGOALS in folder $@
.PHONY: $(APPS)
$(APPS):
	$(if $(wildcard $@/Makefile), \
      $(call make,$(patsubst apps-%,%,$(MAKECMDGOALS)) STATUS=0,$(patsubst %/,%,$@),APP_PATH_PREFIX), \
      $(call WARNING,no Makefile in,$@) \
	)

# target apps-%: Fire $(APPS) target to call target % in $(APPS)
.PHONY: apps-%
apps-%: $(APPS) ;
