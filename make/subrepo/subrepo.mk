## Update subrepos
.PHONY: update-subrepo update-subrepos
update-subrepo update-subrepos: bootstrap-git git-stash subrepos-push git-unstash

.PHONY: subrepos-branch-delete
subrepos-branch-delete:
	$(call make,subrepo-branch-delete,..,SUBREPO BRANCH)

.PHONY: subrepos-tag-create-%
subrepos-tag-create-%:
	$(call make,subrepo-tag-create-$*,..,SUBREPO TAG)

.PHONY: subrepos-push
subrepos-push:
	$(call make,subrepo-push,..,SUBREPO BRANCH)

.PHONY: git-stash
git-stash:
	$(call make,git-stash,..)

.PHONY: git-unstash
git-unstash:
	$(call make,git-unstash,..)
