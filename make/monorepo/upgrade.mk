##
# UPGRADE

.PHONY: upgrade
upgrade: $(patsubst %,upgrade-from-release-%,$(RELEASE_UPGRADE)) update-release ## Update monorepo version

.PHONY: upgrade-from-release-%
upgrade-from-release-%:
	# echo "Upgrading from release: $*"
