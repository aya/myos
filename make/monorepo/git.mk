##
# GIT

## Check if monorepo is up to date with subrepo. subrepo-push saves the parent commit in file subrepo/.gitrepo
.PHONY: git-diff-subrepo
git-diff-subrepo: myos-base subrepo-check
## Get parent commit in .gitrepo : awk '$1 == "parent" {print $3}' subrepo/.gitrepo
## Get child of parent commit : git rev-list --ancestry-path parent..HEAD |tail -n 1
## Compare child commit with our tree : git diff --quiet child -- subrepo
	$(eval DRYRUN_IGNORE := true)
	$(eval DIFF = $(shell $(call exec,git diff --quiet $(shell $(call exec,git rev-list --ancestry-path $(shell awk '$$1 == "parent" {print $$3}' $(SUBREPO)/.gitrepo)..HEAD |tail -n 1)) -- $(SUBREPO); echo $$?)) )
	$(eval DRYRUN_IGNORE := false)

.PHONY: git-fetch-subrepo
git-fetch-subrepo: myos-base subrepo-check
	$(call exec,git fetch --prune $(REMOTE))
