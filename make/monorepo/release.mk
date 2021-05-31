##
# RELEASE

.PHONY: release
release: release-create ## Create release [version]

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
	$(call make,git-branch-create-upstream-develop BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)

.PHONY: release-finish
release-finish: release-check git-stash ## Finish release [version]
	$(call make,git-branch-merge-upstream-master BRANCH=$(RELEASE_BRANCH))
	$(call make,subrepos-update)
	$(call make,git-tag-create-upstream-master TAG=$(RELEASE_VERSION))
	$(call make,subrepos-tag-create-master TAG=$(RELEASE_VERSION))
	$(call make,git-tag-merge-upstream-develop TAG=$(RELEASE_VERSION))
	$(call make,git-branch-delete BRANCH=$(RELEASE_BRANCH))
	$(call make,subrepos-branch-delete BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)

## Update release version number in .env
.PHONY: release-update
release-update:
	$(ECHO) awk -v s=RELEASE=$(RELEASE_VERSION) '/^RELEASE=/{$$0=s;f=1} {a[++n]=$$0} END{if(!f)a[++n]=s;for(i=1;i<=n;i++)print a[i]>ARGV[1]}' .env

## Run migration targets to upgrade specific releases
.PHONY: release-upgrade
release-upgrade: $(patsubst %,release-upgrade-from-%,$(RELEASE_UPGRADE)) release-update ## Update monorepo version

## Sample of release migration target
.PHONY: release-upgrade-from-%
release-upgrade-from-%:
	echo "Upgrading from release: $*"
