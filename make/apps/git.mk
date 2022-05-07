##
# GIT

# target git-branch-create-upstream-%: Create git BRANCH from upstream/% branch
.PHONY: git-branch-create-upstream-%
git-branch-create-upstream-%: myos-user update-upstream
	$(RUN) git fetch --prune upstream
	git rev-parse --verify $(BRANCH) >/dev/null 2>&1 \
		&& $(or $(call WARNING,present branch,$(BRANCH)), true) \
		|| $(RUN) git branch $(BRANCH) upstream/$*
	[ $$(git ls-remote --heads upstream $(BRANCH) |wc -l) -eq 0 ] \
		&& $(RUN) git push upstream $(BRANCH) \
		|| $(or $(call WARNING,present branch,$(BRANCH),upstream), true)
	$(RUN) git checkout $(BRANCH)

# target git-branch-delete: Delete git BRANCH
.PHONY: git-branch-delete
git-branch-delete: myos-user update-upstream
	git rev-parse --verify $(BRANCH) >/dev/null 2>&1 \
		&& $(RUN) git branch -d $(BRANCH) \
		|| $(or $(call WARNING,no branch,$(BRANCH)), true)
	$(foreach remote,upstream,[ $$(git ls-remote --heads $(remote) $(BRANCH) |wc -l) -eq 1 ] \
		&& $(RUN) git push $(remote) :$(BRANCH) \
		|| $(or $(call WARNING,no branch,$(BRANCH),$(remote)), true) \
		&&) true

# target git-branch-merge-upstream-%: Merge git BRANCH into upstream/% branch
.PHONY: git-branch-merge-upstream-%
git-branch-merge-upstream-%: myos-user update-upstream
	git rev-parse --verify $(BRANCH) >/dev/null 2>&1
	$(RUN) git checkout $(BRANCH)
	$(RUN) git pull --ff-only upstream $(BRANCH)
	$(RUN) git push upstream $(BRANCH)
	$(RUN) git checkout $*
	$(RUN) git pull --ff-only upstream $*
	$(RUN) git merge --no-ff --no-edit $(BRANCH)
	$(RUN) git push upstream $*

# target git-stash: git stash
.PHONY: git-stash
git-stash: myos-user
	$(if $(filter-out 0,$(STATUS)),$(RUN) git stash)

# target git-tag-create-upstream-%: Create git TAG to reference upstream/% branch
.PHONY: git-tag-create-upstream-%
git-tag-create-upstream-%: myos-user update-upstream
ifneq ($(words $(TAG)),0)
	$(RUN) git checkout $*
	$(RUN) git pull --tags --prune upstream $*
	$(call sed,s/^##\? $(TAG).*/## $(TAG) - $(shell date +%Y-%m-%d)/,CHANGELOG.md)
	[ $$(git diff CHANGELOG.md 2>/dev/null |wc -l) -eq 0 ] \
		|| $(RUN) git commit -m "$$(cat CHANGELOG.md |sed -n '/$(TAG)/,/^$$/{s/##\(.*\)/release\1\n/;p;}')" CHANGELOG.md
	[ $$(git tag -l $(TAG) |wc -l) -eq 0 ] \
		|| $(RUN) git tag -d $(TAG)
	$(RUN) git tag $(TAG)
	[ $$(git ls-remote --tags upstream $(TAG) |wc -l) -eq 0 ] \
		|| $(RUN) git push upstream :refs/tags/$(TAG)
	$(RUN) git push --tags upstream $*
endif

# target git-tag-merge-upstream-%: Merge git TAG into upstream/% branch
.PHONY: git-tag-merge-upstream-%
git-tag-merge-upstream-%: myos-user update-upstream
ifneq ($(words $(TAG)),0)
	$(RUN) git fetch --tags -u --prune upstream $*:$*
	$(RUN) git checkout $*
	$(RUN) git merge --ff --no-edit $(TAG)
	$(RUN) git push upstream $*
endif

# target git-unstash: git stash pop
.PHONY: git-unstash
git-unstash: myos-user
	$(if $(filter-out 0,$(STATUS)),$(RUN) git stash pop)
