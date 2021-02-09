##
# DEV

## Build assets
.PHONY: dev-assets
dev-assets: ## Build assets
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn build:dev:watch)

.PHONY: dev-outdated
dev-outdated:
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn outdated)

# compile webpack assets (REACT)
.PHONY: dev-webpack-compile
dev-webpack-compile: bootstrap ## Compile dev assets
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn encore dev)

# watch webpack assets updates (REACT)
.PHONY: dev-webpack-watch
dev-webpack-watch: bootstrap ## Watch dev assets update
	$(call docker-compose-exec,$(DOCKER_SERVICE),yarn encore dev --watch)
