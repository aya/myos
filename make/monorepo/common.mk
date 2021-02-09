##
# COMMON

.PHONY: build
build: $(APPS) ## Build applications

.PHONY: build@%
build@%: $(APPS);

.PHONY: clean
clean: $(APPS) ## Clean applications

.PHONY: clean@%
clean@%: $(APPS);

.PHONY: config
config: $(APPS)

.PHONY: copy
copy:
	$(foreach app,$(APPS),$(foreach file,$(ARGS),$(if $(wildcard $(file)),$(ECHO) $(if $(filter LINUX,$(HOST_SYSTEM)),cp -a --parents $(file) $(app)/,rsync -a $(file) $(app)/$(file)) &&)) true &&) true

.PHONY: deploy
deploy: $(APPS) ## Deploy applications

.PHONY: deploy@%
deploy@%: $(APPS);

.PHONY: down
down: $(APPS) ## Remove application dockers

.PHONY: ps
ps: $(APPS)

.PHONY: rebuild
rebuild: $(APPS) ## Rebuild applications

.PHONY: recreate
recreate: $(APPS) ## Recreate applications

.PHONY: reinstall
reinstall: $(APPS) ## Reinstall applications

.PHONY: restart
restart: $(APPS) ## Restart applications

.PHONY: start
start: $(APPS) ## Start applications

.PHONY: stop
stop: $(APPS) ## Stop applications

.PHONY: tests
tests: $(APPS) ## Test applications

.PHONY: up
up: $(APPS) ## Create application dockers

.PHONY: $(APPS)
$(APPS):
	$(if $(wildcard $@/Makefile), \
      $(call make,-o install-infra $(patsubst apps-%,%,$(MAKECMDGOALS)) STATUS=0,$(patsubst %/,%,$@),ENV_SUFFIX), \
      printf "${COLOR_BROWN}WARNING${COLOR_RESET}: ${COLOR_GREEN}no app available in folder${COLOR_RESET} $@.\n" >&2)

# run targets in $(APPS)
.PHONY: apps-%
apps-%: $(APPS) ; ## run % targets in $(APPS)
