APP_DIR                         ?= $(CURDIR)
APP_DOMAIN                      ?= $(patsubst %,$(APP_DOMAIN_PREFIX)%,$(DOMAIN))
APP_DOMAIN_PREFIX               ?= $(if $(STACK_HOST),,$(addsuffix .,$(filter-out $(ENV_DEPLOY),$(ENV)))$(USER).)
APP_HOST                        ?= $(patsubst %,$(APP_HOST_PREFIX)%,$(APP_DOMAIN))$(if $(HOST_LB),$(space)$(APP_DOMAIN))
APP_HOST_PREFIX                 ?= $(addsuffix .,$(if $(STACK_HOST),$(HOSTNAME),$(if $(APP_LB),,$(APP_NAME))))
APP_INSTALLED                   ?= $(APPS)
APP_PARENT                      ?= $(MONOREPO)
APP_PARENT_DIR                  ?= $(MONOREPO_DIR)
APP_PATH                        += $(APP_PATH_PREFIX)
APP_REPOSITORY                  ?= $(APP_REPOSITORY_URL)
APP_REPOSITORY_HOST             ?= $(shell printf '$(APP_REPOSITORY_URI)\n' |sed 's|/.*||;s|.*@||')
APP_REPOSITORY_PATH             ?= $(shell printf '$(APP_REPOSITORY_URI)\n' |sed 's|[^/]*/||;')
APP_REPOSITORY_SCHEME           ?= $(shell printf '$(APP_REPOSITORY_URL)\n' |sed 's|://.*||;')
APP_REPOSITORY_URI              ?= $(shell printf '$(APP_REPOSITORY_URL)\n' |sed 's|.*://||;')
APP_REPOSITORY_URL              ?= $(GIT_REPOSITORY)
APP_REQUIRED                    ?= $(APP_REPOSITORY)
APP_SCHEME                      ?= https
APP_UPSTREAM_REPOSITORY         ?= $(or $(shell git config --get remote.upstream.url 2>/dev/null),$(GIT_UPSTREAM_REPOSITORY))
APP_URI                         ?= $(patsubst %,%/$(APP_PATH),$(APP_HOST))
APP_URIS                        ?= $(APP_URI)
APP_URL                         ?= $(patsubst %,$(APP_SCHEME)://%,$(APP_URI))
CONTEXT                         += APP APPS BRANCH DOMAIN VERSION RELEASE
CONTEXT_DEBUG                   += APP_DIR APP_URL APP_REPOSITORY APP_UPSTREAM_REPOSITORY ENV_DEPLOY
ENV_DEPLOY                      ?= $(patsubst origin/%,%,$(shell git rev-parse --symbolic --remotes=origin |sed '/origin\/HEAD/d' 2>/dev/null))
ENV_VARS                        += APP_DIR APP_DOMAIN APP_HOST APP_PATH APP_URL CONSUL_HTTP_TOKEN $(if $(filter true,$(MOUNT_NFS)),NFS_CONFIG)
MAKECMDARGS                     += exec exec:% exec@% run run:% run@%
MOUNT_NFS                       ?= false
NFS_CONFIG                      ?= addr=$(NFS_HOST),actimeo=3,intr,noacl,noatime,nocto,nodiratime,nolock,soft,rsize=32768,wsize=32768,tcp,rw,vers=3
NFS_HOST                        ?= host.docker.internal
SERVICES                        ?= $(DOCKER_SERVICES)

patsublist = $(patsubst $(1),$(2),$(firstword $(3)))$(foreach pat,$(wordlist 2,16,$(3)),$(comma)$(space)$(patsubst $(1),$(2),$(pat)))
urlprefix  = $(call patsublist,%,urlprefix-%$(1),$(or $(2),$(APP_URIS)))
urlprefixs = $(call urlprefix,$(1))$(foreach prefix,$(subst $(space),$(dollar),$(2)) $(subst $(space),$(dollar),$(3)) $(subst $(space),$(dollar),$(4)),$(comma)$(space)$(call subst,$(dollar),$(space),$(call urlprefix,$(prefix))))
## urlprefix tests (x APP_URI)
# $(call urlprefix)
# urlprefix-app.domain/
# $(call urlprefix,admin)
# urlprefix-app.domain/admin
# $(call urlprefix,:443/ proto=https,$(APP_HOST))
# urlprefix-app.domain:443/ proto=https
## urlprefixs tests (x prefix)
# $(call urlprefixs,admin strip=/admin,images)
# urlprefix-app.domain/admin strip=/admin, urlprefix-app.domain/images
