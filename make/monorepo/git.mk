##
# GIT

## Check if monorepo is up to date with subrepo. subrepo-push saves the parent commit in .gitrepo
.PHONY: git-diff-subrepo
git-diff-subrepo: infra-base subrepo-check
## Get parent commit in .gitrepo : awk '$1 == "parent" {print $3}' subrepo/.gitrepo
## Get child of parent commit : git rev-list --ancestry-path parent..HEAD |tail -n 1
## Compare child commit with our tree : git diff --quiet child -- subrepo
	$(eval DRYRUN_IGNORE := true)
	$(eval DIFF = $(shell $(call exec,git diff --quiet $(shell $(call exec,git rev-list --ancestry-path $(shell awk '$$1 == "parent" {print $$3}' $(SUBREPO)/.gitrepo)..HEAD |tail -n 1)) -- $(SUBREPO); echo $$?)) )
	$(eval DRYRUN_IGNORE := false)

.PHONY: git-fetch-subrepo
git-fetch-subrepo: infra-base subrepo-check
	$(call exec,git fetch --prune $(REMOTE))

.PHONY: git-stash
git-stash: infra-base git-status
	if [ ! $(STATUS) -eq 0 ]; then \
		$(call exec,git stash); \
	fi

.PHONY: git-status
git-status: infra-base
	$(eval DRYRUN_IGNORE := true)
	$(eval STATUS := $(shell $(call exec,git status -uno --porcelain 2>/dev/null |wc -l)))
	$(eval DRYRUN_IGNORE := false)

.PHONY: git-unstash
git-unstash: infra-base
	$(eval STATUS ?= 0)
	if [ ! $(STATUS) -eq 0 ]; then \
		$(call exec,git stash pop); \
	fi

# Create branch $(BRANCH) from upstream/$* branch
.PHONY: branch-create-upstream-%
branch-create-upstream-%: infra-base update-upstream
	$(call exec,git fetch --prune upstream)
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1 && echo Unable to create $(BRANCH). || git branch $(BRANCH) upstream/$*)
	$(call exec,[ $$(git ls-remote --heads upstream $(BRANCH) |wc -l) -eq 0 ] && git push upstream $(BRANCH) || echo Unable to create branch $(BRANCH) on remote upstream.)
	$(call exec,git checkout $(BRANCH))

# Delete branch $(BRANCH)
.PHONY: branch-delete
branch-delete: infra-base update-upstream
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1 && git branch -d $(BRANCH) || echo Unable to delete branch $(BRANCH).)
	$(foreach remote,upstream, $(call exec,[ $$(git ls-remote --heads $(remote) $(BRANCH) |wc -l) -eq 1 ] && git push $(remote) :$(BRANCH) || echo Unable to delete branch $(BRANCH) on remote $(remote).) &&) true

# Merge branch $(BRANCH) into upstream/$* branch
.PHONY: branch-merge-upstream-%
branch-merge-upstream-%: infra-base update-upstream
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1)
	$(call exec,git checkout $(BRANCH))
	$(call exec,git pull --ff-only upstream $(BRANCH))
	$(call exec,git push upstream $(BRANCH))
	$(call exec,git checkout $*)
	$(call exec,git pull --ff-only upstream $*)
	$(call exec,git merge --no-ff --no-edit $(BRANCH))
	$(call exec,git push upstream $*)

# Create $(TAG) tag to reference upstream/$* branch
.PHONY: tag-create-upstream-%
tag-create-upstream-%: infra-base update-upstream
ifneq ($(words $(TAG)),0)
	$(call exec,git checkout $*)
	$(call exec,git pull --tags --prune upstream $*)
	$(call sed,s/^##\? $(TAG).*/## $(TAG) - $(shell date +%Y-%m-%d)/,CHANGELOG.md)
	$(call exec,[ $$(git diff CHANGELOG.md 2>/dev/null |wc -l) -eq 0 ] || git commit -m "$$(cat CHANGELOG.md |sed -n '\''/$(TAG)/,/^$$/{s/##\(.*\)/release\1\n/;p;}'\'')" CHANGELOG.md)
	$(call exec,[ $$(git tag -l $(TAG) |wc -l) -eq 0 ] || git tag -d $(TAG))
	$(call exec,git tag $(TAG))
	$(call exec,[ $$(git ls-remote --tags upstream $(TAG) |wc -l) -eq 0 ] || git push upstream :refs/tags/$(TAG))
	$(call exec,git push --tags upstream $*)
endif

# Merge tag $(TAG) into upstream/$* branch
.PHONY: tag-merge-upstream-%
tag-merge-upstream-%: infra-base update-upstream
ifneq ($(words $(TAG)),0)
	$(call exec,git fetch --tags -u --prune upstream $*:$*)
	$(call exec,git checkout $*)
	$(call exec,git merge --ff --no-edit $(TAG))
	$(call exec,git push upstream $*)
endif
