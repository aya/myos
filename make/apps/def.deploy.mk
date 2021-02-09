CODEDEPLOY_APP_NAME             ?= $(APP)
CODEDEPLOY_DEPLOYMENT_GROUP     ?= $(CODEDEPLOY_APP_NAME)_$(ENV)
CODEDEPLOY_DEPLOYMENT_CONFIG    ?= CodeDeployDefault.AllAtOnce
CODEDEPLOY_DESCRIPTION          ?= deploy $(ENV) $(APP) branch: $(BRANCH) commit: $(SUBREPO_COMMIT) tag: $(TAG) version: $(VERSION)
CODEDEPLOY_GITHUB_REPO          ?= $(patsubst ssh://git@github.com/%,%,$(GIT_REPOSITORY))
CODEDEPLOY_GITHUB_COMMIT_ID     ?= $(SUBREPO_COMMIT)
DEPLOY                          ?= false
DEPLOY_PING_TEXT                ?= app: *$(APP)* branch: *$(BRANCH)* env: *$(ENV)* version: *$(VERSION)* container: *$(CONTAINER)* host: *$(HOST)*
DEPLOY_SLACK_HOOK               ?= https://hooks.slack.com/services/123456789/123456789/ABCDEFGHIJKLMNOPQRSTUVWX
HASH                            ?= $(shell date +%s)
SERVER_NAME                     ?= $(DOCKER_REGISTRY_USERNAME).$(ENV).$(APP)
OXA_SERVER_NAME                 ?= web

ifeq ($(APP),marketplace)
CODEDEPLOY_APP_NAME             := front
EC2_SERVER_NAME                 := front
else ifeq ($(APP),medias)
CODEDEPLOY_APP_NAME             := apimedia
EC2_SERVER_NAME                 := api
else ifeq ($(APP),partners)
CODEDEPLOY_APP_NAME             := api
EC2_SERVER_NAME                 := api
else ifeq ($(APP),workers)
CODEDEPLOY_APP_NAME             := worker
EC2_SERVER_NAME                 := worker
endif
ifeq ($(ENV), preprod)
CODEDEPLOY_APP_NAME             := $(CODEDEPLOY_APP_NAME)pp
CODEDEPLOY_DEPLOYMENT_GROUP     := $(CODEDEPLOY_APP_NAME)_preprod
OXA_SERVER_NAME                 := $(EC2_SERVER_NAME)pp-0x
else ifeq ($(ENV), prod)
CODEDEPLOY_DEPLOYMENT_GROUP     := $(CODEDEPLOY_APP_NAME)_prod
OXA_SERVER_NAME                 := $(EC2_SERVER_NAME)-xx
endif
