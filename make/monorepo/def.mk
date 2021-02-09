APPS                            ?= $(INFRA) $(sort $(filter-out $(DIRS) $(INFRA), $(patsubst %/,%,$(wildcard */)) ))
APPS_NAME                       ?= $(foreach app,$(APPS),$(or $(shell awk -F '=' '$$1 == "APP" {print $$2}' $(or $(wildcard $(app)/.env),$(wildcard $(app)/.env.$(ENV)),$(app)/.env.dist) 2>/dev/null),$(app)))
CMDS                            += copy master-tag release release-check release-create release-finish subrepo-push update-subrepo
CONTEXT                         += APPS APPS_NAME ENV RELEASE_INSTALL
DIRS                            ?= $(MAKE_DIR) $(PARAMETERS) $(SHARED)
RELEASE_UPGRADE                 ?= $(filter v%, $(shell git tag -l |sort -V |awk '/$(RELEASE_INSTALL)/,0'))
RELEASE_VERSION                 ?= $(firstword $(subst -, ,$(VERSION)))
SUBREPOS                        ?= $(filter subrepo/%, $(shell git remote))
