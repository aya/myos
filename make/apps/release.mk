##
# RELEASE

# target release-check: Define RELEASE_BRANCH and RELEASE_VERSION
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

# target release-create: Create release VERSION from upstream/wip branch
.PHONY: release-create
release-create: release-check git-stash
	$(call make,git-branch-create-upstream-wip BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)

# target release-finish: Merge release VERSION in master branch
.PHONY: release-finish
release-finish: release-check git-stash
	$(call make,git-branch-merge-upstream-master BRANCH=$(RELEASE_BRANCH))
	$(call make,git-tag-create-upstream-master TAG=$(RELEASE_VERSION))
	$(call make,git-tag-merge-upstream-wip TAG=$(RELEASE_VERSION))
	$(call make,git-branch-delete BRANCH=$(RELEASE_BRANCH))
	$(call make,git-unstash,,STATUS)

# target release-update: Update RELEASE with RELEASE_VERSION in .env
.PHONY: release-update
release-update:
	$(RUN) awk -v s=RELEASE=$(RELEASE_VERSION) '/^RELEASE=/{$$0=s;f=1} {a[++n]=$$0} END{if(!f)a[++n]=s;for(i=1;i<=n;i++)print a[i]>ARGV[1]}' .env

# target release-upgrade: Run migration targets to upgrade specific releases
.PHONY: release-upgrade
release-upgrade: $(patsubst %,release-upgrade-from-%,$(RELEASE_UPGRADE)) release-update ## Upgrade release

# target release-upgrade-from-%: Sample of catch-all release migration target
.PHONY: release-upgrade-from-%
release-upgrade-from-%:
	echo "Upgrading from release: $*"
