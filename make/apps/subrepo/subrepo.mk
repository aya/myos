##
# SUBREPO

.PHONY: subrepo-branch-delete subrepos-branch-delete
subrepo-branch-delete subrepos-branch-delete:
	$(call make,subrepo-branch-delete,..,SUBREPO BRANCH)

.PHONY: subrepo-push subrepos-push
subrepo-push subrepos-push:
	$(call make,subrepo-push,..,SUBREPO BRANCH)

.PHONY: subrepo-tag-create-% subrepos-tag-create-%
subrepo-tag-create-% subrepos-tag-create-%:
	$(call make,subrepo-tag-create-$*,..,SUBREPO TAG)

.PHONY: subrepo-update subrepos-update
subrepo-update subrepos-update: bootstrap-git git-stash subrepo-push git-unstash
