##
# RELEASE

.PHONY: release
release: release-create # Create release [version]

.PHONY: release-check
release-check:
ifneq ($(words $(ARGS)),0)
	$(eval RELEASE_VERSION := $(word 1, $(ARGS)))
	$(eval RELEASE_BRANCH := release/$(RELEASE_VERSION))
else
ifneq ($(findstring $(firstword $(subst /, ,$(BRANCH))),release),)
	$(eval RELEASE_BRANCH := $(BRANCH))
	$(eval RELEASE_VERSION := $(word 2, $(subst /, ,$(BRANCH))))
endif
endif
	$(if $(filter VERSION=%,$(MAKEFLAGS)), $(eval RELEASE_VERSION:=$(VERSION)) $(eval RELEASE_BRANCH := release/$(RELEASE_VERSION)))
	$(if $(findstring $(firstword $(subst /, ,$(RELEASE_BRANCH))),release),,$(error Please provide a VERSION or a release BRANCH))

.PHONY: release-create
release-create: release-check git-stash ## Create release [version]
	$(call make,branch-create-upstream-develop BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)

.PHONY: release-finish
release-finish: release-check git-stash ## Finish release [version]
	$(call make,branch-merge-upstream-master BRANCH=$(RELEASE_BRANCH))
	$(call make,update-subrepos)
	$(call make,tag-create-upstream-master TAG=$(RELEASE_VERSION))
	$(call make,subrepos-tag-create-master TAG=$(RELEASE_VERSION))
	$(call make,tag-merge-upstream-develop TAG=$(RELEASE_VERSION))
	$(call make,branch-delete BRANCH=$(RELEASE_BRANCH))
	$(call make,subrepos-branch-delete BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)
