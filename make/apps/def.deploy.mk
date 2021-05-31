DEPLOY                          ?= false
DEPLOY_HASH                     ?= $(shell date +%s)
DEPLOY_HOOK_TEXT                ?= app: *$(APP)* branch: *$(BRANCH)* env: *$(ENV)* version: *$(VERSION)* container: *$(CONTAINER)* host: *$(HOST)*
DEPLOY_HOOK_URL                 ?= https://hooks.slack.com/services/123456789/123456789/ABCDEFGHIJKLMNOPQRSTUVWX
SERVER_NAME                     ?= $(DOCKER_REGISTRY_USERNAME).$(ENV).$(APP)
