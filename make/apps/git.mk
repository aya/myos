##
# GIT

# Create branch $(BRANCH) from upstream/$* branch
.PHONY: git-branch-create-upstream-%
git-branch-create-upstream-%: myos-base update-upstream
	$(call exec,git fetch --prune upstream)
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1 && echo Unable to create $(BRANCH). || git branch $(BRANCH) upstream/$*)
	$(call exec,[ $$(git ls-remote --heads upstream $(BRANCH) |wc -l) -eq 0 ] && git push upstream $(BRANCH) || echo Unable to create branch $(BRANCH) on remote upstream.)
	$(call exec,git checkout $(BRANCH))

# Delete branch $(BRANCH)
.PHONY: git-branch-delete
git-branch-delete: myos-base update-upstream
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1 && git branch -d $(BRANCH) || echo Unable to delete branch $(BRANCH).)
	$(foreach remote,upstream, $(call exec,[ $$(git ls-remote --heads $(remote) $(BRANCH) |wc -l) -eq 1 ] && git push $(remote) :$(BRANCH) || echo Unable to delete branch $(BRANCH) on remote $(remote).) &&) true

# Merge branch $(BRANCH) into upstream/$* branch
.PHONY: git-branch-merge-upstream-%
git-branch-merge-upstream-%: myos-base update-upstream
	$(call exec,git rev-parse --verify $(BRANCH) >/dev/null 2>&1)
	$(call exec,git checkout $(BRANCH))
	$(call exec,git pull --ff-only upstream $(BRANCH))
	$(call exec,git push upstream $(BRANCH))
	$(call exec,git checkout $*)
	$(call exec,git pull --ff-only upstream $*)
	$(call exec,git merge --no-ff --no-edit $(BRANCH))
	$(call exec,git push upstream $*)

.PHONY: git-stash
git-stash: myos-base git-status
	if [ ! $(STATUS) -eq 0 ]; then \
		$(call exec,git stash); \
	fi

.PHONY: git-status
git-status: myos-base
	$(eval DRYRUN_IGNORE := true)
	$(eval STATUS := $(shell $(call exec,git status -uno --porcelain 2>/dev/null |wc -l)))
	$(eval DRYRUN_IGNORE := false)

# Create $(TAG) tag to reference upstream/$* branch
.PHONY: git-tag-create-upstream-%
git-tag-create-upstream-%: myos-base update-upstream
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
.PHONY: git-tag-merge-upstream-%
git-tag-merge-upstream-%: myos-base update-upstream
ifneq ($(words $(TAG)),0)
	$(call exec,git fetch --tags -u --prune upstream $*:$*)
	$(call exec,git checkout $*)
	$(call exec,git merge --ff --no-edit $(TAG))
	$(call exec,git push upstream $*)
endif

.PHONY: git-unstash
git-unstash: myos-base
	$(eval STATUS ?= 0)
	if [ ! $(STATUS) -eq 0 ]; then \
		$(call exec,git stash pop); \
	fi