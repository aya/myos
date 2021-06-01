##
# SUBREPO

# target subrepo-branch-delete subrepo-branch-deletes: Call subrepo-branch-delete target in folder ..
.PHONY: subrepo-branch-delete subrepos-branch-delete
subrepo-branch-delete subrepos-branch-delete:
	$(call make,subrepo-branch-delete,..,SUBREPO BRANCH)

# target subrepo-push subrepos-push: Call subrepo-push target in folder ..
.PHONY: subrepo-push subrepos-push
subrepo-push subrepos-push:
	$(call make,subrepo-push,..,SUBREPO BRANCH)

# target subrepo-tag-create-% subrepos-tag-create-%: Call subrepo-tag-create-% target in folder ..
.PHONY: subrepo-tag-create-% subrepos-tag-create-%
subrepo-tag-create-% subrepos-tag-create-%:
	$(call make,subrepo-tag-create-$*,..,SUBREPO TAG)

# target subrepo-update subrepos-update: Fire bootstrap-git git-stash subrepo-push git-unstash
.PHONY: subrepo-update subrepos-update
subrepo-update subrepos-update: bootstrap-git git-stash subrepo-push git-unstash
