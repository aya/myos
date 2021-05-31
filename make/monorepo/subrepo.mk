##
# SUBREPO

## Delete branch $(BRANCH) on $(SUBREPO) remote
.PHONY: subrepo-branch-delete
subrepo-branch-delete: myos-base subrepo-check
ifneq ($(words $(BRANCH)),0)
	$(call exec,[ $$(git ls-remote --heads $(REMOTE) $(BRANCH) |wc -l) -eq 1 ] && git push $(REMOTE) :$(BRANCH) || echo Unable to delete branch $(BRANCH) on remote $(REMOTE).)
endif

.PHONY: subrepo-check
subrepo-check:
ifeq ($(words $(ARGS)), 0)
ifeq ($(words $(SUBREPO)), 0)
	$(error Please provide a SUBREPO)
endif
endif
	$(eval SUBREPO ?= $(word 1, $(ARGS)))
	$(eval REMOTE  := subrepo/$(SUBREPO))

## Check if monorepo is up to date with subrepo. subrepo-push saves the parent commit in file subrepo/.gitrepo
.PHONY: subrepo-git-diff
subrepo-git-diff: myos-base subrepo-check
## Get parent commit in .gitrepo : awk '$1 == "parent" {print $3}' subrepo/.gitrepo
## Get child of parent commit : git rev-list --ancestry-path parent..HEAD |tail -n 1
## Compare child commit with our tree : git diff --quiet child -- subrepo
	$(eval DRYRUN_IGNORE := true)
	$(eval DIFF = $(shell $(call exec,git diff --quiet $(shell $(call exec,git rev-list --ancestry-path $(shell awk '$$1 == "parent" {print $$3}' $(SUBREPO)/.gitrepo)..HEAD |tail -n 1)) -- $(SUBREPO); echo $$?)) )
	$(eval DRYRUN_IGNORE := false)

.PHONY: subrepo-git-fetch
subrepo-git-fetch: myos-base subrepo-check
	$(call exec,git fetch --prune $(REMOTE))

.PHONY: subrepo-tag-create-%
subrepo-tag-create-%: myos-base subrepo-check subrepo-git-fetch ## Create $(TAG) tag to reference $(REMOTE)/$* branch
ifneq ($(words $(TAG)),0)
	$(call exec,[ $$(git ls-remote --tags $(REMOTE) $(TAG) |wc -l) -eq 0 ] || git push $(REMOTE) :refs/tags/$(TAG))
	$(call exec,git push $(REMOTE) refs/remotes/subrepo/$(SUBREPO)/$*:refs/tags/$(TAG))
endif

## Push to subrepo.
.PHONY: subrepo-push
subrepo-push: myos-base subrepo-check subrepo-git-fetch subrepo-git-diff
# update .gitrepo only on master branch
ifeq ($(BRANCH),master)
	$(eval UPDATE_SUBREPO_OPTIONS += -u)
endif
# if release|story|hotfix branch, delete remote branch before push and recreate it from master
ifneq ($(findstring $(firstword $(subst /, ,$(BRANCH))),release story hotfix),)
	$(eval DRYRUN_IGNORE := true)
	$(eval DELETE = $(shell $(call exec,git ls-remote --heads $(REMOTE) $(BRANCH) |wc -l)) )
	$(eval DRYRUN_IGNORE := false)
else
	$(eval DELETE = 0)
endif
	if [ $(DIFF) -eq 0 ]; then \
		echo subrepo $(SUBREPO) already up to date.; \
	else \
		if [ $(DELETE) -eq 1 ]; then \
			$(call exec,git push $(REMOTE) :$(BRANCH)); \
			$(call exec,git push $(REMOTE) refs/remotes/$(REMOTE)/master:refs/heads/$(BRANCH)); \
		fi; \
		$(call exec,git subrepo fetch $(SUBREPO) -b $(BRANCH)); \
		$(call exec,git subrepo push $(SUBREPO) -b $(BRANCH) $(UPDATE_SUBREPO_OPTIONS)); \
		$(call exec,git subrepo clean $(SUBREPO)); \
	fi

.PHONY: subrepos-branch-delete
subrepos-branch-delete: $(APPS) ;

.PHONY: subrepos-tag-create-%
subrepos-tag-create-%: $(APPS) ;

.PHONY: subrepos-update
subrepos-update: myos-base git-stash $(APPS) git-unstash ## Update subrepos
	$(call exec,git push upstream $(BRANCH))

.PHONY: subrepo-update-%
subrepo-update-%:
	$(if $(wildcard $*/Makefile),$(call make,subrepo-update,$*))
