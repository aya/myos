APP_DIR                         ?= $(CURDIR)
APP_DOMAIN                      ?= $(ENV)$(addprefix .,$(DOMAIN))
APP_HOST                        ?= $(APP)$(addprefix .,$(APP_DOMAIN))
APP_PARENT                      ?= $(MONOREPO)
APP_PARENT_DIR                  ?= $(MONOREPO_DIR)
APP_PATH                        ?= /$(APP_PATH_PREFIX)
APP_REPOSITORY                  ?= $(GIT_REPOSITORY)
APP_SCHEME                      ?= https
APP_UPSTREAM_REPOSITORY         ?= $(or $(shell git config --get remote.upstream.url 2>/dev/null),$(GIT_UPSTREAM_REPOSITORY))
APP_URI                         ?= $(APP_HOST)$(APP_PATH)
APP_URL                         ?= $(APP_SCHEME)://$(APP_URI)
BUILD_ENV_VARS                  ?= APP BRANCH COMMIT DEPLOY_HOOK_URL ENV VERSION
CONTEXT_DEBUG                   += APP_DIR APP_DOMAIN APP_HOST APP_PATH APP_URL APP_REPOSITORY APP_UPSTREAM_REPOSITORY CONSUL_HTTP_TOKEN SERVICES
ENV_DEPLOY                      ?= $(shell ls .git/refs/heads/)
ENV_VARS                        += APP_DIR APP_DOMAIN APP_HOST APP_PATH APP_URL CONSUL_HTTP_TOKEN $(if $(filter true,$(MOUNT_NFS)),NFS_CONFIG)
MOUNT_NFS                       ?= false
NFS_CONFIG                      ?= addr=$(NFS_HOST),actimeo=3,intr,noacl,noatime,nocto,nodiratime,nolock,soft,rsize=32768,wsize=32768,tcp,rw,vers=3
NFS_HOST                        ?= host.docker.internal
SERVICES                        ?= $(eval DRYRUN_IGNORE := true) $(shell $(call docker-compose,--log-level critical config --services)) $(eval DRYRUN_IGNORE := false)
