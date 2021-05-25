CMDS                            += copy master-tag release release-check release-create release-finish subrepo-push update-subrepo
CONTEXT                         += APPS ENV RELEASE_INSTALL
DIRS                            ?= $(MAKE_DIR) $(PARAMETERS) $(SHARED)
RELEASE_UPGRADE                 ?= $(filter v%, $(shell git tag -l 2>/dev/null |sort -V |awk '/$(RELEASE_INSTALL)/,0'))
RELEASE_VERSION                 ?= $(firstword $(subst -, ,$(VERSION)))
SUBREPOS                        ?= $(filter subrepo/%, $(shell git remote 2>/dev/null))
